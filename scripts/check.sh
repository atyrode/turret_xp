#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python_bin="${PYTHON:-python3}"

"$python_bin" -m json.tool info.json >/dev/null
"$python_bin" -m json.tool docs/public-copy.json >/dev/null
scripts/generate-public-assets.py --check
scripts/lint-lua.sh

echo "Basic checks passed."
