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

Turret XP makes gun turrets grow into named veteran defenders.

Install a Veteran Core in a turret and let it earn XP from real fights. As it levels up, shape it into the defender your factory needs: a long-range sniper, a rapid machine gun, a tough bulwark, or a brutal close-range brawler.

Veteran Cores carry a turret's level, upgrades, elements, name, and combat history. Move the core to a new turret when the front line shifts, or keep it on a trusted defender and watch it grow.

Highlights:

- Only chosen turrets become unique, so ordinary gun turrets stay stackable.
- Earn XP from damage and kill contribution.
- Spend points on damage, regeneration, lifesteal, crits, range, luck, double shots, XP gain, and bouncing bullets.
- Pick specializations with strong tradeoffs.
- Feed fire, electric, explosive, or toxic resources into passive element ranks to strengthen elemental effects and combos.
- Name favorite turrets and show their level above them.
- Choose exact Veteran Cores from platform hubs for space-platform defenses.
- Tune XP pacing in mod settings.

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
    -F "summary=Make chosen gun turrets level up, specialize, and carry Veteran Core progression between battlefields." \
    -F "description=<${description_path}" \
    -F "category=tweaks" \
    -F "tags=combat" \
    -F "homepage=${homepage_url}" \
    -F "source_url=${source_url}" \
    "https://mods.factorio.com/api/v2/mods/edit_details"
)"

printf '%s\n' "$response" | "$python_bin" -m json.tool
echo "Updated ${mod_name} Mod Portal details."
