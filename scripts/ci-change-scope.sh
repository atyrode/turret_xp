#!/usr/bin/env bash
set -euo pipefail

event_name="${GITHUB_EVENT_NAME:-}"
base_sha="${BASE_SHA:-}"
head_sha="${HEAD_SHA:-}"
output_path="${GITHUB_OUTPUT:-/dev/stdout}"

package_changed=true
headless_changed=true
changed_files=""

if [ "$event_name" = "pull_request" ]; then
  if [ -z "$base_sha" ] || [ -z "$head_sha" ]; then
    echo "Missing BASE_SHA or HEAD_SHA for pull_request change detection." >&2
    exit 1
  fi

  changed_files="$(git diff --name-only "$base_sha" "$head_sha")"
  package_changed=false
  headless_changed=false

  while IFS= read -r path; do
    [ -n "$path" ] || continue

    case "$path" in
      README.md|AGENTS.md|*.md|docs/*|changelog.txt|thumbnail.png)
        ;;
      *)
        package_changed=true
        headless_changed=true
        ;;
    esac
  done <<EOF
$changed_files
EOF
fi

{
  echo "package_changed=$package_changed"
  echo "headless_changed=$headless_changed"
  echo "changed_files<<EOF"
  printf '%s\n' "$changed_files"
  echo "EOF"
} >> "$output_path"
