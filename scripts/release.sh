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
- Tracks per-turret XP, level, kills, kill credit, lifetime damage, and skill allocations.
- Awards configurable XP from gun turret damage and proportional kill credit.
- Adds runtime-global settings for damage XP, kill-credit XP, base level XP, and level XP growth.
- Shows HP, shooting speed, range, loaded ammo, estimated ammo damage, estimated DPS, kills, damage dealt, and XP progress.
- Shows force research bonuses for shooting speed and damage in base plus bonus format.
- Uses Factorio Library (flib) GUI styles for a more vanilla-like relative panel.
- Shows quality summaries for HP and range while filtering Factorio's hidden unknown quality prototype.
- Adds a scrollable technology-style skill tree surface with allocatable points from turret levels.
- Uses effect-only skill hover text and a root turret tooltip that summarizes allocated bonuses.
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
