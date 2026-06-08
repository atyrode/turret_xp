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

Turret XP turns chosen vanilla gun turrets into movable Veteran Core defenses with XP, active stat upgrades, specializations, fueled elements, and element mastery.

Current prototype:

- Adds a Turret XP panel to the vanilla gun turret GUI.
- Adds non-stackable Veteran Cores that make selected gun turrets unique while ordinary turrets stay stackable.
- Tracks XP, level, kills, kill credit, lifetime damage, evolution choices, material projects, element fuel, custom names, and label preference on the installed core profile.
- Adds tag-preserving slot-style Veteran Core cursor transfer and swap behavior.
- Adds floating label color and level-suffix controls with a fixed larger readable label size.
- Adds a hidden turret-tile feeder inventory for inserter-fed element materials, element fuel, and ammo forwarding.
- Closes the hidden feeder at the visible element fuel cap instead of accepting excess ghost fuel.
- On space platforms, lists Veteran Cores from the platform hub inventory so a player can install the exact core they choose and send installed cores back to that hub.
- Reduces space-platform combat XP to 10% while keeping displayed damage and kill-credit stats as raw totals.
- Awards configurable XP from cored gun turret damage and proportional kill credit.
- Lets the player extract a core and install it in another turret, carrying progression with it.
- Returns or spills the installed core when a turret is mined.
- Shows HP, shooting speed, range, loaded ammo, estimated ammo damage, estimated DPS, kills, total damage, active custom stats, formula-style additive/multiplier breakdowns, and XP progress.
- Includes runtime-global settings for XP pacing.
- Uses Factorio Library (flib) styles and richer vanilla-like panel structure.
- Shows research bonuses in base plus bonus format.
- Shows HP and range quality summaries using Factorio quality prototypes and the real quality info marker.
- Uses a scrollable five-section Evolution list so the panel stays within the vanilla turret GUI height.
- Adds horizontal delimiters between Evolution choices for easier scanning.
- Shows element material requirements with item icons and hides feeder implementation status from the panel.
- Adds compact core upgrades, element material projects, furnace-like element fuel, element mastery ranks, a free specialization choice, Double Shot/Veteran Training/Range/Luck augments, and a second element combo path.
- Specialization choices and Range ranks now use hidden gun-turret body variants with real range, cooldown, damage modifier, and health values.
- Adds optional floating turret labels in "name (lvl N)" format, using hidden display-panel labels when available.
- Adds first-draft runtime upgrade effects and visuals for bonus damage, crits, bounce, double shots, Luck-adjusted proc odds, XP gain, Range ranks, fire, electric arcs, explosive splash, passive repair, and vampiric healing.
- Adds command-toggled dev controls for quick level, core, and material-project testing.
- Adds respec/reset controls for point allocation and local playtesting.
- Keeps Evolution scroll context after point allocation.
- Shows technical effect text for augments, elements, and specialization choices.
- Uses a custom solid XP bar style.

This is the first playable release line intended to validate Veteran Core mobility, the simplified scrollable Evolution list, material gates, furnace-like element fuel, element choices, specialization stats, upgrade effects, and XP pacing before deeper balance work.

0.6.2 reduces space-platform combat XP to 10% and adds Evolution choice delimiters. 0.6.1 added Luck, formula-style stat breakdowns, expected DPS from proc output, impact-origin Electric feedback, delayed Double Shot tracers, bounced-hit element procs, hidden fuel cap fixes, second-element fuel acceptance fixes, and explicit space-platform hub core selection.

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
    -F "summary=Turn chosen gun turrets into movable Veteran Core defenses with XP, upgrades, specializations, fueled elements, and mastery." \
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
