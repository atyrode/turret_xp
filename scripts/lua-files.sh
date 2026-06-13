#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files --cached --others --exclude-standard -- "*.lua" | sort -u
  exit 0
fi

find . \
  -path "./.git" -prune -o \
  -path "./.factorio-ci" -prune -o \
  -path "./case_study" -prune -o \
  -path "./dist" -prune -o \
  -name "*.lua" -print | sort
