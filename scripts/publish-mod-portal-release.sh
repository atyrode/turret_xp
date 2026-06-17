#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
  cat >&2 <<'EOF'
scripts/publish-mod-portal-release.sh is CI-only.

Publish releases by creating a GitHub Release named v<info.json version>.
The Release workflow builds and attaches the package, then publishes that
exact GitHub Release package to the Factorio Mod Portal.
EOF
  exit 2
fi

if [ "$#" -ne 3 ]; then
  echo "Usage: scripts/publish-mod-portal-release.sh <release-package.zip> <mod-portal-description.md> <mod-portal-metadata.env>" >&2
  exit 2
fi

package_path="$1"
description_path="$2"
metadata_path="$3"
if [ ! -f "$package_path" ]; then
  echo "Release package was not found: $package_path" >&2
  exit 2
fi
if [ ! -f "$description_path" ]; then
  echo "Generated Mod Portal description was not found: $description_path" >&2
  exit 2
fi
if [ ! -f "$metadata_path" ]; then
  echo "Generated Mod Portal metadata was not found: $metadata_path" >&2
  exit 2
fi

api_key="${FACTORIO_MOD_PORTAL_API_KEY:-}"
if [ -z "$api_key" ]; then
  echo "Missing FACTORIO_MOD_PORTAL_API_KEY secret for Mod Portal publishing." >&2
  exit 2
fi

python_bin="${PYTHON:-python3}"
mod_name="${MOD_NAME:-}"
version="${MOD_VERSION:-}"
release_tag="${RELEASE_TAG:-}"
actual_package_name="$(basename "$package_path")"
curl_config_dir=""
auth_config_path=""

if [ -z "$mod_name" ] || [ -z "$version" ]; then
  echo "Missing MOD_NAME or MOD_VERSION from the Release workflow." >&2
  exit 2
fi

if [ -z "$release_tag" ]; then
  echo "Missing RELEASE_TAG from the Release workflow." >&2
  exit 2
fi

expected_tag="v${version}"
expected_package_name="${mod_name}_${version}.zip"
if [ "$release_tag" != "$expected_tag" ]; then
  echo "Release tag $release_tag does not match release version $version." >&2
  exit 1
fi

if [ "$actual_package_name" != "$expected_package_name" ]; then
  echo "Release package $actual_package_name does not match expected package $expected_package_name." >&2
  exit 1
fi

cleanup() {
  if [ -n "$curl_config_dir" ]; then
    rm -rf "$curl_config_dir"
  fi
}
trap cleanup EXIT

write_auth_config() {
  curl_config_dir="$(mktemp -d)"
  auth_config_path="${curl_config_dir}/mod-portal-auth.curl"
  printf 'header = "Authorization: Bearer %s"\n' "$api_key" >"$auth_config_path"
  chmod 600 "$auth_config_path"
  unset api_key FACTORIO_MOD_PORTAL_API_KEY
}

print_response_body() {
  local body_path="$1"
  if [ ! -s "$body_path" ]; then
    echo "(empty response)" >&2
    return
  fi

  "$python_bin" -m json.tool "$body_path" >&2 || cat "$body_path" >&2
}

curl_mod_portal() {
  local label="$1"
  shift

  local body_path
  body_path="$(mktemp)"

  local status
  if ! status="$(curl -sS -w "%{http_code}" -o "$body_path" "$@")"; then
    echo "${label} failed before receiving a complete Mod Portal response:" >&2
    print_response_body "$body_path"
    rm -f "$body_path"
    return 1
  fi

  if [ "$status" -lt 200 ] || [ "$status" -ge 300 ]; then
    echo "${label} failed with HTTP ${status}:" >&2
    print_response_body "$body_path"
    rm -f "$body_path"
    return 1
  fi

  cat "$body_path"
  rm -f "$body_path"
}

curl_mod_portal_auth() {
  local label="$1"
  shift

  curl_mod_portal "$label" --config "$auth_config_path" "$@"
}

curl_mod_portal_url() {
  local label="$1"
  local url="$2"
  shift 2

  local url_config_path
  url_config_path="$(mktemp "${curl_config_dir}/mod-portal-url.XXXXXX")"
  printf 'url = "%s"\n' "$url" >"$url_config_path"
  chmod 600 "$url_config_path"

  curl_mod_portal "$label" --config "$url_config_path" "$@"
}

write_auth_config

. "$metadata_path"

package_sha1="$(sha1sum "$package_path" | awk '{print $1}')"
mod_response=""
release_sha1=""
if mod_response="$(curl -fsS "https://mods.factorio.com/api/mods/${mod_name}/full")"; then
  mode="release"
  release_sha1="$(
    printf '%s' "$mod_response" | "$python_bin" -c '
import json
import sys

version = sys.argv[1]
data = json.load(sys.stdin)
for release in data.get("releases", []):
    if release.get("version") == version:
        print(release.get("sha1", ""))
        break
' "$version"
  )"
else
  mode="publish"
fi

if [ -n "$release_sha1" ]; then
  if [ "$release_sha1" != "$package_sha1" ]; then
    cat >&2 <<EOF
${mod_name} ${version} already exists on the Factorio Mod Portal with sha1 ${release_sha1}.
The GitHub Release package sha1 is ${package_sha1}; refusing to publish mismatched artifacts.
EOF
    exit 1
  fi

  echo "${mod_name} ${version} already exists on the Factorio Mod Portal with matching package sha1; skipping package upload."
else
  if [ "$mode" = "release" ]; then
    init_url="https://mods.factorio.com/api/v2/mods/releases/init_upload"
  else
    init_url="https://mods.factorio.com/api/v2/mods/init_publish"
  fi

  init_response="$(
    curl_mod_portal_auth "Initializing Mod Portal ${mode} upload" \
      --data-urlencode "mod=${mod_name}" \
      "$init_url"
  )"

  upload_url="$(
    printf '%s' "$init_response" | "$python_bin" -c 'import json, sys; data=json.load(sys.stdin); print(data["upload_url"])'
  )"

  if [ "$mode" = "publish" ]; then
    upload_response="$(
      curl_mod_portal_url "Publishing ${mod_name} ${version}" "$upload_url" \
        -F "file=@${package_path}" \
        -F "description=<${description_path}" \
        -F "category=${MOD_PORTAL_CATEGORY}" \
        -F "source_url=${MOD_PORTAL_SOURCE_URL}"
    )"
  else
    upload_response="$(
      curl_mod_portal_url "Uploading ${mod_name} ${version}" "$upload_url" \
        -F "file=@${package_path}"
    )"
  fi

  printf '%s\n' "$upload_response" | "$python_bin" -m json.tool
fi

if edit_response="$(
  curl_mod_portal_auth "Editing ${mod_name} Mod Portal details" \
    -F "mod=${mod_name}" \
    -F "title=${MOD_PORTAL_TITLE}" \
    -F "summary=${MOD_PORTAL_SUMMARY}" \
    -F "description=<${description_path}" \
    -F "category=${MOD_PORTAL_CATEGORY}" \
    -F "tags=${MOD_PORTAL_TAGS}" \
    -F "homepage=${MOD_PORTAL_HOMEPAGE}" \
    -F "source_url=${MOD_PORTAL_SOURCE_URL}" \
    "https://mods.factorio.com/api/v2/mods/edit_details"
)"; then
  printf '%s\n' "$edit_response" | "$python_bin" -m json.tool
else
  echo "Package state is valid, but editing portal details failed. Check the API key has ModPortal: Edit Mods." >&2
fi

echo "Published ${mod_name} ${version} from GitHub Release package ${actual_package_name}."
