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
homepage_url="https://atyrode.github.io/turret_xp/"
source_url="https://github.com/atyrode/turret_xp"

mkdir -p dist

cat > "$description_path" <<DESC
# Turret XP

Turret XP adds the first layer of per-turret progression for vanilla gun turrets.

Current prototype:

- Adds a Turret XP panel to the vanilla gun turret GUI.
- Tracks XP, level, kills, lifetime damage, and total XP per turret.
- Awards XP from damage dealt by gun turrets and a small kill bonus.
- Shows HP, attack speed, range, loaded ammo, estimated ammo damage, kills, total damage, and XP progress.
- Keeps combat balance unchanged for now: V0.1.x tracks levels but does not apply level bonuses yet.

This is an early test release intended to validate the GUI placement, stat display, and XP pacing before adding actual level bonuses.

Source:
${source_url}

Homepage:
${homepage_url}
DESC

response="$(
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
)"

printf '%s\n' "$response" | "$python_bin" -m json.tool
echo "Updated ${mod_name} Mod Portal details."
