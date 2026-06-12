#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python_bin="${PYTHON:-python3}"
version="$("$python_bin" -c 'import json; print(json.load(open("info.json"))["version"])')"
tag="v${version}"
notes_path="dist/release-notes-${version}.md"

scripts/generate-public-assets.py --check
scripts/generate-public-assets.py --release-notes "$notes_path"

package_path="$(scripts/package.sh | tail -n 1)"

if gh release view "$tag" >/dev/null 2>&1; then
  gh release upload "$tag" "$package_path" --clobber
  gh release edit "$tag" --title "Turret XP ${version}" --notes-file "$notes_path"
else
  gh release create "$tag" "$package_path" --target "$(git rev-parse HEAD)" --title "Turret XP ${version}" --notes-file "$notes_path"
fi

gh release view "$tag" --web=false
