#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import pathlib
import re
import sys
import urllib.error
import urllib.parse
import urllib.request


ROOT = pathlib.Path(__file__).resolve().parents[1]
MOD_PORTAL = "https://mods.factorio.com"


def parse_version(value):
    parts = []
    for part in str(value).split("."):
        if not part.isdigit():
            match = re.match(r"^(\d+)", part)
            if not match:
                break
            part = match.group(1)
        parts.append(int(part))
    return tuple(parts)


def compare_versions(left, right):
    left_parts = list(parse_version(left))
    right_parts = list(parse_version(right))
    max_len = max(len(left_parts), len(right_parts))
    left_parts.extend([0] * (max_len - len(left_parts)))
    right_parts.extend([0] * (max_len - len(right_parts)))
    if left_parts < right_parts:
        return -1
    if left_parts > right_parts:
        return 1
    return 0


def satisfies(version, operator, expected):
    if not operator:
        return True
    comparison = compare_versions(version, expected)
    return {
        "=": comparison == 0,
        "==": comparison == 0,
        ">": comparison > 0,
        ">=": comparison >= 0,
        "<": comparison < 0,
        "<=": comparison <= 0,
    }[operator]


def parse_dependency(raw):
    spec = raw.strip()
    optional = False

    if spec.startswith("(?)"):
        optional = True
        spec = spec[3:].strip()
    elif spec.startswith("?"):
        optional = True
        spec = spec[1:].strip()
    elif spec.startswith("!"):
        return None

    if spec.startswith("~"):
        spec = spec[1:].strip()

    match = re.match(r"^([A-Za-z0-9_.-]+)(?:\s*(<=|>=|==|=|<|>)\s*([A-Za-z0-9_.+-]+))?$", spec)
    if not match:
        raise ValueError(f"Could not parse dependency spec: {raw!r}")

    return {
        "name": match.group(1),
        "operator": match.group(2),
        "version": match.group(3),
        "optional": optional,
        "raw": raw,
    }


def load_info(path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def request_json(url):
    request = urllib.request.Request(url, headers={"User-Agent": "turret-xp-ci/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        print(f"Mod Portal API request failed with HTTP {error.code}.", file=sys.stderr)
        raise SystemExit(1) from error
    except urllib.error.URLError as error:
        print(f"Mod Portal API request failed: {error.reason}", file=sys.stderr)
        raise SystemExit(1) from error


def select_release(mod_name, dependency, factorio_version):
    data = request_json(f"{MOD_PORTAL}/api/mods/{urllib.parse.quote(mod_name)}/full")
    releases = data.get("releases", [])
    candidates = []

    for release in releases:
        info_json = release.get("info_json", {})
        if info_json.get("factorio_version") != factorio_version:
            continue
        if not satisfies(release.get("version", ""), dependency["operator"], dependency["version"]):
            continue
        candidates.append(release)

    if not candidates:
        raise SystemExit(
            f"No {mod_name} release found for Factorio {factorio_version} "
            f"matching {dependency['raw']!r}."
        )

    return max(candidates, key=lambda release: parse_version(release.get("version", "0")))


def sha1_file(path):
    digest = hashlib.sha1()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_release(release, mods_dir, username, token):
    file_name = release["file_name"]
    target = mods_dir / file_name
    expected_sha1 = release.get("sha1")

    if target.is_file() and expected_sha1 and sha1_file(target) == expected_sha1:
        print(f"Using cached {file_name}.")
        return target

    query = urllib.parse.urlencode({"username": username, "token": token})
    url = f"{MOD_PORTAL}{release['download_url']}?{query}"
    tmp_target = target.with_suffix(target.suffix + ".tmp")

    request = urllib.request.Request(url, headers={"User-Agent": "turret-xp-ci/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            with tmp_target.open("wb") as handle:
                for chunk in iter(lambda: response.read(1024 * 1024), b""):
                    handle.write(chunk)
    except urllib.error.HTTPError as error:
        print(f"Downloading {file_name} failed with HTTP {error.code}.", file=sys.stderr)
        raise SystemExit(1) from error
    except urllib.error.URLError as error:
        print(f"Downloading {file_name} failed: {error.reason}", file=sys.stderr)
        raise SystemExit(1) from error

    if expected_sha1 and sha1_file(tmp_target) != expected_sha1:
        tmp_target.unlink(missing_ok=True)
        raise SystemExit(f"Downloaded {file_name}, but its sha1 did not match the Mod Portal release.")

    tmp_target.replace(target)
    print(f"Downloaded {file_name}.")
    return target


def dependency_specs(info, include_optional, extra_specs):
    for raw in info.get("dependencies", []):
        dependency = parse_dependency(raw)
        if not dependency or dependency["name"] == "base":
            continue
        if dependency["optional"] and not include_optional:
            continue
        yield dependency

    for raw in extra_specs:
        dependency = parse_dependency(raw)
        if dependency and dependency["name"] != "base":
            yield dependency


def main():
    parser = argparse.ArgumentParser(description="Download Factorio Mod Portal dependencies for CI/headless tests.")
    parser.add_argument("--info-json", type=pathlib.Path, default=ROOT / "info.json")
    parser.add_argument("--mods-dir", type=pathlib.Path, default=pathlib.Path(os.getenv("FACTORIO_MODS_DIR", ".factorio/mods")))
    parser.add_argument("--include-optional", action="store_true")
    parser.add_argument("--dependency", action="append", default=[], help="Extra dependency spec to download.")
    args = parser.parse_args()

    username = os.getenv("FACTORIO_SERVICE_USERNAME") or os.getenv("FACTORIO_USERNAME")
    token = os.getenv("FACTORIO_SERVICE_TOKEN") or os.getenv("FACTORIO_TOKEN")
    if not username or not token:
        raise SystemExit(
            "Missing FACTORIO_SERVICE_USERNAME/FACTORIO_SERVICE_TOKEN "
            "for authenticated Mod Portal downloads."
        )

    info = load_info(args.info_json)
    factorio_version = info["factorio_version"]
    args.mods_dir.mkdir(parents=True, exist_ok=True)

    downloaded = []
    for dependency in dependency_specs(info, args.include_optional, args.dependency):
        release = select_release(dependency["name"], dependency, factorio_version)
        downloaded.append(download_release(release, args.mods_dir, username, token))

    if downloaded:
        print(f"Prepared {len(downloaded)} Mod Portal dependency zip(s) in {args.mods_dir}.")
    else:
        print("No Mod Portal dependencies needed.")


if __name__ == "__main__":
    main()
