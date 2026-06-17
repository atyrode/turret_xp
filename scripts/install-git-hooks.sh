#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

hooks_path="scripts/git-hooks"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run from inside a Git worktree." >&2
  exit 2
fi

echo "Configuring this clone to use tracked Git hooks from ${hooks_path}."
echo "+ git config core.hooksPath ${hooks_path}"
git config core.hooksPath "$hooks_path"

echo "Git hooks installed for this clone."
