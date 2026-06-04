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

cat > "$description_path" <<DESC
# Turret XP

Turret XP adds the first layer of per-turret progression for vanilla gun turrets.

Current prototype:

- Adds a Turret XP panel to the vanilla gun turret GUI.
- Tracks XP, level, kills, lifetime damage, and total XP per turret.
- Awards XP from damage dealt by gun turrets and a small kill bonus.
- Shows HP, attack speed, range, loaded ammo, estimated ammo damage, kills, total damage, and XP progress.
- Keeps combat balance unchanged for now: V0.1.0 tracks levels but does not apply level bonuses yet.

This is an early test release intended to validate the GUI placement, stat display, and XP pacing before adding actual level bonuses.

Source:
https://github.com/atyrode/turret_xp
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
      -F "source_url=https://github.com/atyrode/turret_xp" \
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
    -F "homepage=https://github.com/atyrode/turret_xp" \
    -F "source_url=https://github.com/atyrode/turret_xp" \
    "https://mods.factorio.com/api/v2/mods/edit_details"
)"; then
  printf '%s\n' "$edit_response" | "$python_bin" -m json.tool
else
  echo "Uploaded ${mod_name} ${version}, but editing portal details failed. Check the API key has ModPortal: Edit Mods." >&2
fi

echo "Published ${mod_name} ${version} to the Factorio Mod Portal."
