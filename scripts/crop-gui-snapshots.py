#!/usr/bin/env python3
"""Crop full-screen Factorio GUI snapshots down to the Turret XP panel."""

from __future__ import annotations

import argparse
import json
import pathlib
import struct
import sys
import zlib


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
DEFAULT_LEFT = 895
DEFAULT_WIDTH = 860
DEFAULT_HEIGHT = 832


class PngImage:
    def __init__(self, width: int, height: int, color_type: int, rows: list[bytearray]):
        self.width = width
        self.height = height
        self.color_type = color_type
        self.rows = rows
        if color_type == 2:
            self.bytes_per_pixel = 3
        elif color_type == 6:
            self.bytes_per_pixel = 4
        else:
            raise ValueError(f"unsupported PNG color type {color_type}; expected RGB or RGBA")


def paeth_predictor(left: int, up: int, upper_left: int) -> int:
    estimate = left + up - upper_left
    left_distance = abs(estimate - left)
    up_distance = abs(estimate - up)
    upper_left_distance = abs(estimate - upper_left)
    if left_distance <= up_distance and left_distance <= upper_left_distance:
        return left
    if up_distance <= upper_left_distance:
        return up
    return upper_left


def read_png(path: pathlib.Path) -> PngImage:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path} is not a PNG file")

    offset = len(PNG_SIGNATURE)
    idat = bytearray()
    width = height = bit_depth = color_type = interlace = None

    while offset < len(data):
        chunk_length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_type = data[offset + 4 : offset + 8]
        chunk_data = data[offset + 8 : offset + 8 + chunk_length]
        offset += 12 + chunk_length

        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, compression, filter_method, interlace = struct.unpack(
                ">IIBBBBB", chunk_data
            )
            if compression != 0 or filter_method != 0:
                raise ValueError(f"{path} uses unsupported PNG compression/filter settings")
        elif chunk_type == b"IDAT":
            idat.extend(chunk_data)
        elif chunk_type == b"IEND":
            break

    if width is None or height is None or bit_depth != 8 or interlace != 0:
        raise ValueError(f"{path} must be an 8-bit non-interlaced PNG")
    if color_type not in (2, 6):
        raise ValueError(f"{path} uses unsupported PNG color type {color_type}; expected RGB or RGBA")

    bytes_per_pixel = 4 if color_type == 6 else 3
    stride = width * bytes_per_pixel
    raw = zlib.decompress(bytes(idat))
    rows: list[bytearray] = []
    previous = bytearray(stride)
    position = 0

    for _ in range(height):
        filter_type = raw[position]
        position += 1
        source = bytearray(raw[position : position + stride])
        position += stride
        row = bytearray(stride)

        for index, value in enumerate(source):
            left = row[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            up = previous[index]
            upper_left = previous[index - bytes_per_pixel] if index >= bytes_per_pixel else 0

            if filter_type == 0:
                row[index] = value
            elif filter_type == 1:
                row[index] = (value + left) & 0xFF
            elif filter_type == 2:
                row[index] = (value + up) & 0xFF
            elif filter_type == 3:
                row[index] = (value + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                row[index] = (value + paeth_predictor(left, up, upper_left)) & 0xFF
            else:
                raise ValueError(f"unsupported PNG filter type {filter_type}")

        rows.append(row)
        previous = row

    return PngImage(width, height, color_type, rows)


def write_chunk(output: bytearray, chunk_type: bytes, chunk_data: bytes) -> None:
    output.extend(struct.pack(">I", len(chunk_data)))
    output.extend(chunk_type)
    output.extend(chunk_data)
    checksum = zlib.crc32(chunk_type)
    checksum = zlib.crc32(chunk_data, checksum)
    output.extend(struct.pack(">I", checksum & 0xFFFFFFFF))


def write_png(path: pathlib.Path, image: PngImage) -> None:
    raw = bytearray()
    for row in image.rows:
        raw.append(0)
        raw.extend(row)

    color_type = image.color_type
    output = bytearray(PNG_SIGNATURE)
    write_chunk(output, b"IHDR", struct.pack(">IIBBBBB", image.width, image.height, 8, color_type, 0, 0, 0))
    write_chunk(output, b"IDAT", zlib.compress(bytes(raw), 9))
    write_chunk(output, b"IEND", b"")
    path.write_bytes(output)


def crop_png(image: PngImage, left: int, top: int, width: int, height: int) -> PngImage:
    bytes_per_pixel = image.bytes_per_pixel
    left = max(0, min(left, image.width - 1))
    top = max(0, min(top, image.height - 1))
    width = max(1, min(width, image.width - left))
    height = max(1, min(height, image.height - top))
    start = left * bytes_per_pixel
    end = (left + width) * bytes_per_pixel
    rows = [bytearray(row[start:end]) for row in image.rows[top : top + height]]
    return PngImage(width, height, image.color_type, rows)


def is_dark_pixel(image: PngImage, x: int, y: int) -> bool:
    offset = x * image.bytes_per_pixel
    row = image.rows[y]
    red, green, blue = row[offset], row[offset + 1], row[offset + 2]
    return (red + green + blue) / 3 < 90


def detect_top(image: PngImage, left: int, width: int) -> int:
    sample_left = max(0, min(left + 8, image.width - 1))
    sample_right = min(image.width, sample_left + min(width, 320))
    if sample_right <= sample_left + 8:
        return 0

    for y in range(0, min(image.height, 220)):
        dark = 0
        for x in range(sample_left, sample_right, 4):
            if is_dark_pixel(image, x, y):
                dark += 1
        ratio = dark / max(1, ((sample_right - sample_left + 3) // 4))
        if ratio >= 0.72:
            return max(0, y - 2)

    return 0


def load_manifest(path: pathlib.Path | None) -> dict:
    if not path or not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def crop_settings(args: argparse.Namespace, manifest: dict) -> tuple[int, int | None, int, int]:
    layout = manifest.get("layout") if isinstance(manifest.get("layout"), dict) else {}
    left = args.left if args.left is not None else int(layout.get("default_crop_left") or DEFAULT_LEFT)
    top = args.top
    width = args.width if args.width is not None else int(layout.get("panel_width") or DEFAULT_WIDTH)
    height = args.height if args.height is not None else int(layout.get("panel_height") or DEFAULT_HEIGHT)
    return left, top, width, height


def scene_frame_for_image(manifest: dict, image_name: str) -> dict | None:
    scenes = manifest.get("scenes")
    if not isinstance(scenes, list):
        return None
    for scene in scenes:
        if isinstance(scene, dict) and scene.get("file") == image_name and isinstance(scene.get("frame"), dict):
            return scene["frame"]
    return None


def frame_crop_settings(frame: dict) -> tuple[int, int, int, int] | None:
    location = frame.get("location")
    actual_size = frame.get("actual_size")
    if isinstance(location, dict) and isinstance(actual_size, dict):
        left = int(round(float(location.get("x", 0))))
        top = int(round(float(location.get("y", 0))))
        width = int(round(float(actual_size.get("width", 0))))
        height = int(round(float(actual_size.get("height", 0))))
        if width > 0 and height > 0:
            return left, top, width, height

    top_left = frame.get("top_left")
    bottom_right = frame.get("bottom_right")
    if isinstance(top_left, dict) and isinstance(bottom_right, dict):
        left = int(round(float(top_left.get("x", 0))))
        top = int(round(float(top_left.get("y", 0))))
        right = int(round(float(bottom_right.get("x", 0))))
        bottom = int(round(float(bottom_right.get("y", 0))))
        if right > left and bottom > top:
            return left, top, right - left, bottom - top

    return None


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=pathlib.Path, help="Snapshot manifest with layout metadata.")
    parser.add_argument("--output", type=pathlib.Path, required=True, help="Directory for cropped PNGs.")
    parser.add_argument("--left", type=int, help="Crop left coordinate override.")
    parser.add_argument("--top", type=int, help="Crop top coordinate override.")
    parser.add_argument("--width", type=int, help="Crop width override.")
    parser.add_argument("--height", type=int, help="Crop height override.")
    parser.add_argument("images", nargs="+", type=pathlib.Path)
    args = parser.parse_args(argv)

    manifest = load_manifest(args.manifest)
    fallback_left, top_override, fallback_width, fallback_height = crop_settings(args, manifest)
    args.output.mkdir(parents=True, exist_ok=True)

    for image_path in args.images:
        image = read_png(image_path)
        frame_settings = frame_crop_settings(scene_frame_for_image(manifest, image_path.name) or {})
        if frame_settings:
            left, top, width, height = frame_settings
        else:
            left = fallback_left
            width = fallback_width
            height = fallback_height
            top = top_override if top_override is not None else detect_top(image, left, width)
        cropped = crop_png(image, left, top, width, height)
        destination = args.output / image_path.name
        write_png(destination, cropped)
        print(f"{image_path.name}: crop {cropped.width}x{cropped.height} at {left},{top}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
