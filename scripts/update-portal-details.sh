#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

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
- ModPortal: Edit Mods

Then run:
  FACTORIO_MOD_PORTAL_API_KEY=<your-api-key> scripts/update-portal-details.sh

Or put this in an ignored .env file:
  FACTORIO_API_KEY=<your-api-key>

Do not commit the key or paste it into chat.
EOF
  exit 2
fi

python_bin="${PYTHON:-python3}"
mod_name="$("$python_bin" -c 'import json; print(json.load(open("info.json"))["name"])')"
description_path="dist/mod-portal-description.md"
metadata_path="dist/mod-portal-metadata.env"

mkdir -p dist

scripts/generate-public-assets.py --check
scripts/generate-public-assets.py --portal-description "$description_path" --portal-metadata "$metadata_path"
. "$metadata_path"

response="$(
  curl -fsS \
    -H "Authorization: Bearer ${api_key}" \
    -F "mod=${mod_name}" \
    -F "title=${MOD_PORTAL_TITLE}" \
    -F "summary=${MOD_PORTAL_SUMMARY}" \
    -F "description=<${description_path}" \
    -F "category=${MOD_PORTAL_CATEGORY}" \
    -F "tags=${MOD_PORTAL_TAGS}" \
    -F "homepage=${MOD_PORTAL_HOMEPAGE}" \
    -F "source_url=${MOD_PORTAL_SOURCE_URL}" \
    "https://mods.factorio.com/api/v2/mods/edit_details"
)"

printf '%s\n' "$response" | "$python_bin" -m json.tool
echo "Updated ${mod_name} Mod Portal details."
