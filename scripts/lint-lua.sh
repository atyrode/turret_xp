#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

require_tools="${REQUIRE_LUA_TOOLS:-0}"
luac_bin="${LUAC:-luac}"
stylua_bin="${STYLUA:-stylua}"
luacheck_bin="${LUACHECK:-luacheck}"

mapfile -t lua_files < <(scripts/lua-files.sh)

missing_tool() {
  local tool="$1"
  if [ "$require_tools" = "1" ]; then
    echo "$tool not found; strict Lua tooling requires it." >&2
    exit 2
  fi

  echo "$tool not found; skipped related Lua check." >&2
}

if [ "${#lua_files[@]}" -eq 0 ]; then
  echo "No Lua files found."
  exit 0
fi

if command -v "$luac_bin" >/dev/null 2>&1; then
  "$luac_bin" -p "${lua_files[@]}"
else
  missing_tool "luac"
fi

if command -v "$stylua_bin" >/dev/null 2>&1; then
  "$stylua_bin" --check "${lua_files[@]}"
else
  missing_tool "stylua"
fi

if command -v "$luacheck_bin" >/dev/null 2>&1; then
  "$luacheck_bin" "${lua_files[@]}"
else
  missing_tool "luacheck"
fi

echo "Lua lint checks completed."
