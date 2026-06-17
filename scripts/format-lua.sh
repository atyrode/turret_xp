#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

stylua_bin="${STYLUA:-stylua}"

lua_files=()
if [ "$#" -gt 0 ]; then
  for file in "$@"; do
    lua_files+=("$file")
  done
else
  while IFS= read -r file; do
    lua_files+=("$file")
  done < <(scripts/lua-files.sh)
fi

if [ "${#lua_files[@]}" -eq 0 ]; then
  echo "No Lua files found."
  exit 0
fi

if ! command -v "$stylua_bin" >/dev/null 2>&1; then
  echo "$stylua_bin not found; run through Docker with: docker compose run --rm lua-format" >&2
  exit 2
fi

"$stylua_bin" "${lua_files[@]}"
echo "Lua files formatted."
