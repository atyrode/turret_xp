#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python_bin="${PYTHON:-python3}"

"$python_bin" -m json.tool info.json >/dev/null

if command -v luac >/dev/null 2>&1; then
  mapfile -t lua_files < <(find . -path "./dist" -prune -o -name "*.lua" -print | sort)
  luac -p "${lua_files[@]}"
else
  echo "luac not found; skipped Lua syntax check." >&2
fi

echo "Basic checks passed."
