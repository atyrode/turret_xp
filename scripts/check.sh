#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python_bin="${PYTHON:-python3}"

"$python_bin" -m json.tool info.json >/dev/null

if command -v luac >/dev/null 2>&1; then
  luac -p data.lua settings.lua control.lua
else
  echo "luac not found; skipped Lua syntax check." >&2
fi

echo "Basic checks passed."
