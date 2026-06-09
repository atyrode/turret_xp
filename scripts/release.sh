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

Turn ordinary gun turrets into veteran defenders with portable cores, XP, upgrades, specializations, elemental material ranks, and names.

Highlights:

- Veteran Cores store a turret's XP, upgrades, elements, name, and history.
- Ordinary turrets stay stackable until you choose to install a core.
- Turrets earn XP from combat and kill contribution.
- Specializations and sub-specializations create snipers, machine guns, bulwarks, and brawlers.
- Passive elemental material ranks unlock fire, electric, explosive, toxic, and combo effects.
- Space-platform turrets can choose exact cores from the platform hub.
- Readable upgrade panels and slower space-combat XP keep long playthroughs manageable.

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
