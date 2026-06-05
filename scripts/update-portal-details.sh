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

Turret XP turns chosen vanilla gun turrets into movable Veteran Core defenses with XP, active stat upgrades, specializations, fueled elements, and element mastery.

Current prototype:

- Adds a Turret XP panel to the vanilla gun turret GUI.
- Adds non-stackable Veteran Cores that make selected gun turrets unique while ordinary turrets stay stackable.
- Tracks XP, level, kills, kill credit, lifetime damage, evolution choices, material projects, element fuel, custom names, and label preference on the installed core profile.
- Adds a hidden turret-tile feeder inventory for inserter-fed element materials, element fuel, and ammo forwarding.
- Awards configurable XP from cored gun turret damage and proportional kill credit.
- Lets the player extract a core and install it in another turret, carrying progression with it.
- Returns or spills the installed core when a turret is mined.
- Shows HP, shooting speed, range, loaded ammo, estimated ammo damage, estimated DPS, kills, total damage, active custom stats, and XP progress.
- Includes runtime-global settings for XP pacing.
- Uses Factorio Library (flib) styles and richer vanilla-like panel structure.
- Shows research bonuses in base plus bonus format.
- Shows HP and range quality summaries using Factorio quality prototypes and the real quality info marker.
- Uses a scrollable five-section Evolution list so the panel stays within the vanilla turret GUI height.
- Shows element material requirements with item icons and hides feeder implementation status from the panel.
- Adds compact core upgrades, element material projects, furnace-like element fuel, element mastery ranks, a free specialization choice, Double Shot/Veteran Training/Range augments, and a second element combo path.
- Specialization choices and Range ranks now use hidden gun-turret body variants with real range, cooldown, damage modifier, and health values.
- Adds optional floating turret labels in "name (lvl N)" format, using hidden display-panel labels when available.
- Adds first-draft runtime upgrade effects and visuals for bonus damage, crits, bounce, double shots, XP gain, fire, electric arcs, explosive splash, passive repair, and vampiric healing.
- Adds command-toggled dev controls for quick level, core, and material-project testing.
- Keeps Evolution scroll context after point allocation.
- Shows technical effect text for augments, elements, and specialization choices.
- Uses a custom solid XP bar style.

This is the first playable release line intended to validate Veteran Core mobility, the simplified scrollable Evolution list, material gates, furnace-like element fuel, element choices, specialization stats, upgrade effects, and XP pacing before deeper balance work.

0.6.0 adds dynamic active stats, element mastery ranks, display-panel floating labels, clearer specialization rows, vanilla burn bars, stronger element visuals, full respec reset, better kill accounting, and coherent fuel buffering.

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
    -F "summary=Turn chosen gun turrets into movable Veteran Core defenses with XP, upgrades, specializations, fueled elements, and mastery." \
    -F "description=<${description_path}" \
    -F "category=tweaks" \
    -F "tags=combat" \
    -F "homepage=${homepage_url}" \
    -F "source_url=${source_url}" \
    "https://mods.factorio.com/api/v2/mods/edit_details"
)"

printf '%s\n' "$response" | "$python_bin" -m json.tool
echo "Updated ${mod_name} Mod Portal details."
