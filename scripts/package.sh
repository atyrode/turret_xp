#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python_bin="${PYTHON:-python3}"

scripts/check.sh
"$python_bin" scripts/package.py
