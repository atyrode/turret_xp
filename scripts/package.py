#!/usr/bin/env python3
import json
import pathlib
import zipfile


ROOT = pathlib.Path(__file__).resolve().parents[1]


def load_info():
    with (ROOT / "info.json").open("r", encoding="utf-8") as handle:
        return json.load(handle)


def package_files():
    files = [
        "info.json",
        "data.lua",
        "settings.lua",
        "control.lua",
        "README.md",
        "changelog.txt",
    ]

    files.extend(str(path.relative_to(ROOT)) for path in sorted((ROOT / "locale").rglob("*")) if path.is_file())
    files.extend(str(path.relative_to(ROOT)) for path in sorted((ROOT / "docs").rglob("*.md")) if path.is_file())
    return files


def main():
    info = load_info()
    package_root = f"{info['name']}_{info['version']}"
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    output = dist / f"{package_root}.zip"

    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for relative in package_files():
            archive.write(ROOT / relative, f"{package_root}/{relative}")

    print(output)


if __name__ == "__main__":
    main()
