#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

scripts/release-preflight.sh "Mod Portal publish"

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

api_key="${FACTORIO_MOD_PORTAL_API_KEY:-${FACTORIO_API_KEY:-}}"
if [ -z "$api_key" ]; then
  cat >&2 <<'EOF'
Missing FACTORIO_MOD_PORTAL_API_KEY or FACTORIO_API_KEY.

Create an API key at https://factorio.com/profile with these usages:
- ModPortal: Publish Mods
- ModPortal: Upload Mods
- ModPortal: Edit Mods

Then run:
  FACTORIO_MOD_PORTAL_API_KEY=<your-api-key> scripts/publish-portal.sh

Or put this in an ignored .env file:
  FACTORIO_API_KEY=<your-api-key>

Do not commit the key or paste it into chat.
EOF
  exit 2
fi

python_bin="${PYTHON:-python3}"
mod_name="$("$python_bin" -c 'import json; print(json.load(open("info.json"))["name"])')"
version="$("$python_bin" -c 'import json; print(json.load(open("info.json"))["version"])')"
description_path="dist/mod-portal-description.md"
metadata_path="dist/mod-portal-metadata.env"
curl_config_dir=""
auth_config_path=""

cleanup() {
  if [ -n "$curl_config_dir" ]; then
    rm -rf "$curl_config_dir"
  fi
}
trap cleanup EXIT

write_auth_config() {
  curl_config_dir="$(mktemp -d)"
  auth_config_path="${curl_config_dir}/mod-portal-auth.curl"
  chmod 600 "$auth_config_path"
  printf 'header = "Authorization: Bearer %s"\n' "$api_key" >"$auth_config_path"
  unset api_key FACTORIO_MOD_PORTAL_API_KEY FACTORIO_API_KEY
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
  chmod 600 "$url_config_path"
  printf 'url = "%s"\n' "$url" >"$url_config_path"

  curl_mod_portal "$label" --config "$url_config_path" "$@"
}

write_auth_config

scripts/generate-public-assets.py --check
scripts/generate-public-assets.py --portal-description "$description_path" --portal-metadata "$metadata_path"
. "$metadata_path"

if [ "${SKIP_HEADLESS_TESTS:-}" = "1" ]; then
  echo "Skipping headless tests because SKIP_HEADLESS_TESTS=1."
else
  scripts/test-headless.sh
fi

package_path="$(scripts/package.sh | tail -n 1)"

if curl -fsS "https://mods.factorio.com/api/mods/${mod_name}" >/dev/null 2>&1; then
  init_url="https://mods.factorio.com/api/v2/mods/releases/init_upload"
  mode="release"
else
  init_url="https://mods.factorio.com/api/v2/mods/init_publish"
  mode="publish"
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
  echo "Uploaded ${mod_name} ${version}, but editing portal details failed. Check the API key has ModPortal: Edit Mods." >&2
fi

echo "Published ${mod_name} ${version} to the Factorio Mod Portal."
