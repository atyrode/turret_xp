#!/usr/bin/env python3
import json
import pathlib
import zipfile


ROOT = pathlib.Path(__file__).resolve().parents[1]
ZIP_TIMESTAMP = (1980, 1, 1, 0, 0, 0)


def load_info():
    with (ROOT / "info.json").open("r", encoding="utf-8") as handle:
        return json.load(handle)


def package_files():
    files = [
        "info.json",
        "data.lua",
        "data-final-fixes.lua",
        "settings.lua",
        "control.lua",
        "README.md",
        "changelog.txt",
    ]

    if (ROOT / "thumbnail.png").is_file():
        files.append("thumbnail.png")

    files.extend(str(path.relative_to(ROOT)) for path in sorted((ROOT / "locale").rglob("*")) if path.is_file())
    files.extend(str(path.relative_to(ROOT)) for path in sorted((ROOT / "scripts").glob("*.lua")) if path.is_file())
    files.extend(str(path.relative_to(ROOT)) for path in sorted((ROOT / "scripts" / "control").rglob("*.lua")) if path.is_file())
    files.extend(str(path.relative_to(ROOT)) for path in sorted((ROOT / "prototypes").rglob("*.lua")) if path.is_file())
    return files


def main():
    info = load_info()
    package_root = f"{info['name']}_{info['version']}"
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    output = dist / f"{package_root}.zip"

    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for relative in package_files():
            archive_path = f"{package_root}/{relative}"
            info = zipfile.ZipInfo(archive_path, date_time=ZIP_TIMESTAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, (ROOT / relative).read_bytes())

    print(output)


if __name__ == "__main__":
    main()
