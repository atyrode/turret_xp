#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if command -v node >/dev/null 2>&1; then
  node --check tools/gui-prototype/fixtures.js >/dev/null
  node --check tools/gui-prototype/app.js >/dev/null
else
  echo "node not found; skipping JavaScript parse checks for GUI prototype." >&2
fi

python3 scripts/check-gui-prototype.py

echo "GUI prototype checks passed."
