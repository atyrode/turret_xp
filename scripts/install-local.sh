#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mods_dir="${FACTORIO_MODS_DIR:-$HOME/.factorio/mods}"
package_path="$(scripts/package.sh | tail -n 1)"

mkdir -p "$mods_dir"
cp "$package_path" "$mods_dir/"

echo "$mods_dir/$(basename "$package_path")"
