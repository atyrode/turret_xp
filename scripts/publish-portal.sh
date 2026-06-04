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
package_path="$(scripts/package.sh | tail -n 1)"
description_path="dist/mod-portal-description.md"
homepage_url="https://atyrode.github.io/turret_xp/"
source_url="https://github.com/atyrode/turret_xp"

cat > "$description_path" <<DESC
# Turret XP

Turret XP adds the first layer of per-turret progression for vanilla gun turrets.

Current prototype:

- Adds a Turret XP panel to the vanilla gun turret GUI.
- Tracks XP, level, kills, kill credit, lifetime damage, and skill allocations per turret.
- Awards configurable XP from damage dealt by gun turrets and proportional kill credit.
- Shows HP, shooting speed, range, loaded ammo, estimated ammo damage, estimated DPS, kills, total damage, and XP progress.
- Includes runtime-global settings for XP pacing.
- Uses Factorio Library (flib) styles and richer vanilla-like panel structure.
- Shows research bonuses in base plus bonus format.
- Shows HP and range quality summaries using Factorio quality prototypes and the real quality info marker.
- Adds a scrollable technology-style skill tree surface with four allocatable skills: Ballistics Drill, Kill Chain, Field Repairs, and Targeting Data.
- Uses effect-only skill hover text, a central turret root summary, and a custom solid XP bar style.

This is an early test release intended to validate the simplified GUI, quality summaries, skill-tree shape, and XP pacing before deeper combat bonuses.

Source:
${source_url}

Homepage:
${homepage_url}
DESC

if curl -fsS "https://mods.factorio.com/api/mods/${mod_name}" >/dev/null 2>&1; then
  init_url="https://mods.factorio.com/api/v2/mods/releases/init_upload"
  mode="release"
else
  init_url="https://mods.factorio.com/api/v2/mods/init_publish"
  mode="publish"
fi

init_response="$(
  curl -fsS \
    -H "Authorization: Bearer ${api_key}" \
    -F "mod=${mod_name}" \
    "$init_url"
)"

upload_url="$(
  printf '%s' "$init_response" | "$python_bin" -c 'import json, sys; data=json.load(sys.stdin); print(data["upload_url"])'
)"

if [ "$mode" = "publish" ]; then
  upload_response="$(
    curl -fsS \
      -F "file=@${package_path}" \
      -F "description=<${description_path}" \
      -F "category=tweaks" \
      -F "source_url=${source_url}" \
      "$upload_url"
  )"
else
  upload_response="$(
    curl -fsS \
      -F "file=@${package_path}" \
      "$upload_url"
  )"
fi

printf '%s\n' "$upload_response" | "$python_bin" -m json.tool

if edit_response="$(
  curl -fsS \
    -H "Authorization: Bearer ${api_key}" \
    -F "mod=${mod_name}" \
    -F "title=Turret XP" \
    -F "summary=Track XP, levels, and combat stats for vanilla gun turrets." \
    -F "description=<${description_path}" \
    -F "category=tweaks" \
    -F "tags=combat" \
    -F "homepage=${homepage_url}" \
    -F "source_url=${source_url}" \
    "https://mods.factorio.com/api/v2/mods/edit_details"
)"; then
  printf '%s\n' "$edit_response" | "$python_bin" -m json.tool
else
  echo "Uploaded ${mod_name} ${version}, but editing portal details failed. Check the API key has ModPortal: Edit Mods." >&2
fi

echo "Published ${mod_name} ${version} to the Factorio Mod Portal."
