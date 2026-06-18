#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

fixture_name="turret-xp-lua-file-discovery-fixture-$$.lua"
fixture_dir="turret-xp-lua-file-discovery-fixture-$$"
fixtures=(
  ".codex_tmp/$fixture_dir/$fixture_name"
  ".factorio-ci/$fixture_dir/factorio/data/base/$fixture_name"
  "case_study/$fixture_dir/$fixture_name"
  "dist/$fixture_dir/$fixture_name"
)

cleanup() {
  rm -rf \
    ".codex_tmp/$fixture_dir" \
    ".factorio-ci/$fixture_dir" \
    "case_study/$fixture_dir" \
    "dist/$fixture_dir"
}
trap cleanup EXIT

for fixture in "${fixtures[@]}"; do
  mkdir -p "$(dirname "$fixture")"
  printf 'this is intentionally invalid Lua for file-discovery validation\n' >"$fixture"
done

file_list="$(scripts/lua-files.sh)"

if ! printf '%s\n' "$file_list" | grep -Fx -- "control.lua" >/dev/null; then
  echo "Lua file discovery did not include tracked source file control.lua." >&2
  exit 1
fi

for fixture in "${fixtures[@]}"; do
  if printf '%s\n' "$file_list" | grep -Fx -- "$fixture" >/dev/null; then
    echo "Lua file discovery included excluded local/runtime file: $fixture" >&2
    exit 1
  fi

  if printf '%s\n' "$file_list" | grep -Fx -- "./$fixture" >/dev/null; then
    echo "Lua file discovery included excluded local/runtime file: ./$fixture" >&2
    exit 1
  fi
done

echo "Lua file discovery checks passed."
