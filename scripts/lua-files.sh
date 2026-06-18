#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

excluded_roots=(
  ".codex_tmp"
  ".factorio-ci"
  ".git"
  "case_study"
  "dist"
)

is_excluded_path() {
  local path="${1#./}"
  local root

  for root in "${excluded_roots[@]}"; do
    case "$path" in
      "$root"|"$root"/*)
        return 0
        ;;
    esac
  done

  return 1
}

emit_non_excluded_lua_files() {
  local path

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if ! is_excluded_path "$path"; then
      printf '%s\n' "$path"
    fi
  done | sort -u
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files --cached --others --exclude-standard -- "*.lua" | emit_non_excluded_lua_files
  exit 0
fi

find . \
  -path "./.codex_tmp" -prune -o \
  -path "./.git" -prune -o \
  -path "./.factorio-ci" -prune -o \
  -path "./case_study" -prune -o \
  -path "./dist" -prune -o \
  -name "*.lua" -print | emit_non_excluded_lua_files
