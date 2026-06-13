#!/usr/bin/env bash
set -euo pipefail

event_name="${GITHUB_EVENT_NAME:-}"
base_sha="${BASE_SHA:-}"
head_sha="${HEAD_SHA:-}"
output_path="${GITHUB_OUTPUT:-/dev/stdout}"

package_changed=true
headless_changed=true
lua_changed=true
changed_files=""

is_package_payload_path() {
  case "$1" in
    info.json|data.lua|data-final-fixes.lua|settings.lua|control.lua|README.md|changelog.txt|thumbnail.png)
      return 0
      ;;
    locale/*|scripts/*.lua|scripts/control/*|prototypes/*)
      return 0
      ;;
  esac

  return 1
}

is_headless_runtime_path() {
  case "$1" in
    info.json|data.lua|data-final-fixes.lua|settings.lua|control.lua)
      return 0
      ;;
    locale/*|scripts/*.lua|scripts/control/*|prototypes/*|tests/headless/*)
      return 0
      ;;
  esac

  return 1
}

is_validation_infra_path() {
  case "$1" in
    .github/workflows/*|compose.yaml|tools/lua/*|scripts/check.sh|scripts/lint-lua.sh|scripts/lua-files.sh|scripts/package.py|scripts/package.sh|scripts/release-preflight.sh|scripts/release.sh|scripts/publish-portal.sh|scripts/test-headless.sh|scripts/download-mod-dependencies.py)
      return 0
      ;;
  esac

  return 1
}

is_lua_validation_path() {
  case "$1" in
    *.lua|.luacheckrc|.stylua.toml|compose.yaml|tools/lua/*|scripts/lint-lua.sh|scripts/lua-files.sh)
      return 0
      ;;
  esac

  return 1
}

if [ "$event_name" = "pull_request" ]; then
  if [ -z "$base_sha" ] || [ -z "$head_sha" ]; then
    echo "Missing BASE_SHA or HEAD_SHA for pull_request change detection." >&2
    exit 1
  fi

  changed_files="$(git diff --name-only "$base_sha" "$head_sha")"
  package_changed=false
  headless_changed=false
  lua_changed=false

  while IFS= read -r path; do
    [ -n "$path" ] || continue

    if is_package_payload_path "$path" || is_validation_infra_path "$path"; then
      package_changed=true
    fi

    if is_headless_runtime_path "$path" || is_validation_infra_path "$path"; then
      headless_changed=true
    fi

    if is_lua_validation_path "$path"; then
      lua_changed=true
    fi
  done <<EOF
$changed_files
EOF
fi

{
  echo "package_changed=$package_changed"
  echo "headless_changed=$headless_changed"
  echo "lua_changed=$lua_changed"
  echo "changed_files<<EOF"
  printf '%s\n' "$changed_files"
  echo "EOF"
} >> "$output_path"
