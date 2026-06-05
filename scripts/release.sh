#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python_bin="${PYTHON:-python3}"
version="$("$python_bin" -c 'import json; print(json.load(open("info.json"))["version"])')"
tag="v${version}"
package_path="$(scripts/package.sh | tail -n 1)"
notes_path="dist/release-notes-${version}.md"

cat > "$notes_path" <<NOTES
Turret XP ${version}.

- Adds a Turret XP panel to the vanilla gun turret GUI.
- Adds non-stackable Veteran Cores that make selected gun turrets unique while ordinary turrets stay stackable.
- Tracks XP, level, kills, kill credit, lifetime damage, evolution choices, material projects, custom names, and label preference on the installed core profile.
- Adds a real Veteran Core feeder inventory for inserter-fed element materials.
- Awards configurable XP from cored gun turret damage and proportional kill credit.
- Lets the player extract a core and install it in another turret, carrying progression with it.
- Returns or spills the installed core when a turret is mined.
- Adds runtime-global settings for damage XP, kill-credit XP, base level XP, and level XP growth.
- Shows HP, shooting speed, range, loaded ammo, estimated ammo damage, estimated DPS, kills, damage dealt, and XP progress.
- Shows force research bonuses for shooting speed and damage in base plus bonus format.
- Uses Factorio Library (flib) GUI styles for a more vanilla-like relative panel.
- Shows quality summaries for HP and range while filtering Factorio's hidden unknown quality prototype.
- Uses a scrollable five-section Evolution list so the panel stays within the vanilla turret GUI height.
- Adds compact core upgrades, level-gated element projects, specialization choices, powerful augments, and second-element combo text.
- Specialization choices use hidden gun-turret body variants with real range, cooldown, damage modifier, and health values.
- Adds optional floating turret labels in "name (lvl N)" format.
- Adds first-draft runtime upgrade effects for bonus damage, crits, bounce, pierce, fire, electric arcs, explosive splash, passive repair, and vampiric healing.
- Adds always-visible dev controls for quick level, core, and material-project testing.
- Adds respec/reset controls for point allocation and local playtesting.
- Uses a custom solid XP bar style.
- Updates the panel in place while open instead of destroying and rebuilding it every refresh.

Validation:
- Packaged zip layout checked.
- See changelog.txt for version-specific changes.

Playtest guide:
https://github.com/atyrode/turret_xp/blob/main/docs/PLAYTEST.md
NOTES

if gh release view "$tag" >/dev/null 2>&1; then
  gh release upload "$tag" "$package_path" --clobber
  gh release edit "$tag" --title "Turret XP ${version}" --notes-file "$notes_path"
else
  gh release create "$tag" "$package_path" --target "$(git rev-parse HEAD)" --title "Turret XP ${version}" --notes-file "$notes_path"
fi

gh release view "$tag" --web=false
