#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

find . \
  -path "./.git" -prune -o \
  -path "./.factorio-ci" -prune -o \
  -path "./dist" -prune -o \
  -name "*.lua" -print | sort
