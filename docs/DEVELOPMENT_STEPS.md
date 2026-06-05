# Development Steps

## Completed For V0.1.0

- [x] Copy reusable scaffold from `player_quality`.
- [x] Rename metadata to `turret_xp`.
- [x] Add per-gun-turret XP, level, kill, and damage tracking.
- [x] Add GUI extension for vanilla gun turret.
- [x] Add command fallback with `/turret-xp`.
- [x] Update locale, README, docs, changelog, and release scripts.

## Validation

- [x] Run `scripts/check.sh`.
- [x] Run `scripts/package.sh`.
- [x] Inspect zip layout.
- [x] Initialize git repository and commit.
- [x] Create/push `atyrode/turret_xp`.
- [x] Create GitHub release `v0.1.0`.
- [x] Publish `0.1.0` to the Factorio Mod Portal.
- [ ] Run an in-game or headless Factorio smoke test once a Factorio binary is available locally.

## Completed For V0.1.1

- [x] Fix crash when opening a gun turret caused by reading max health from `LuaEntityPrototype`.
- [x] Move HP stat display to `LuaEntity::max_health` and harden optional prototype stat reads.
- [x] Document library/framework candidates to consider for future features.

## Completed For V0.1.2

- [x] Add runtime-global XP pacing settings.
- [x] Rebalance default XP with low damage XP, kill-credit XP, and configurable level growth.
- [x] Add contribution-based kill credit so final-hit stealing does not erase turret XP.
- [x] Align range and shooting-speed displays more closely with vanilla hover stats.
- [x] Add quality-aware turret icon and reorganize the panel for readability.

## Completed For V0.1.3

- [x] Rework the panel toward vanilla GUI styling with an inner shallow frame, slot-style ammo, compact section headers, and row info affordances.
- [x] Move the prototype note behind the top info button.
- [x] Show force research bonuses for shooting speed and ammo damage in base plus bonus format.
- [x] Re-check Mod Portal libraries for GUI and quality support; document `entity-gui-lib` and `quality-lib` as future candidates without adding them yet.

## Completed For V0.1.4

- [x] Fix research bonus lookup by deriving ammo category from loaded ammo or attack parameters.
- [x] Include gun-turret attack research when estimating damage per shot.
- [x] Remove the experimental custom quality stat marker because it did not reuse vanilla quality stat marker/popover behavior.
- [x] Replace gray framed info buttons with the exposed vanilla `utility/tip_icon` sprite, and stop rendering a custom fallback marker when that sprite is unavailable.
- [x] Document that exact vanilla quality stat pills are deferred until a supported API path or dependency is confirmed.

## Completed For V0.2.0

- [x] Add `flib >= 0.16.4` as the first production dependency.
- [x] Rebuild the right-side relative panel with vanilla-like shallow/deep frames, subheaders, flib slot styling, and flib status indicators.
- [x] Replace `utility/tip_icon` with Factory Planner-style `[img=info]` rich text markers.
- [x] Add `[img=quality_info]` markers with custom HP/range quality summary tooltips derived from runtime quality prototypes.
- [x] Add estimated DPS, damage XP, and kill-credit XP rows.
- [x] Update the panel in place every refresh tick instead of destroying and rebuilding the full GUI.

## Completed For V0.3.0

- [x] Simplify the main panel into one compact stat table.
- [x] Move ammo and turret icon into the title row.
- [x] Remove the quality text row, top info marker, no-bonuses note, progression section, and XP source rows.
- [x] Filter hidden `quality-unknown` out of quality summaries.
- [x] Add a first skill tree panel with four allocatable skill nodes.
- [x] Add active baseline skill effects for XP modifiers and passive repairs.

## Completed For V0.3.1

- [x] Rebuild the skill row into a scrollable technology-style skill tree surface.
- [x] Center the tree around a gun-turret root node with four branching baseline skills.
- [x] Reduce skill hover text to the next allocated effect only.
- [x] Add a root-node tooltip summarizing currently allocated bonuses.
- [x] Replace the XP progress bar with a custom solid bar style.
- [x] Inspect `entity-gui-lib` source and document it as the leading candidate for a future full custom turret GUI, not a requirement for the 0.3.x relative panel.

## Completed For V0.3.2

- [x] Inspect the local Factorio install for reusable research-tree Lua and confirm the pan behavior is not exposed as moddable source.
- [x] Add an embedded click-drag skill-tree pan spike using a hidden `open-gui` custom input and logical tree-cell scroll targets.
- [x] Keep the skill tree inside the existing Turret XP relative panel with no new window, screen overlay, full GUI replacement, or new library dependency.

## Completed For V0.4.0

- [x] Remove the failed embedded skill-tree drag implementation and data-stage custom input.
- [x] Replace the skill tree with a five-section Evolution list.
- [x] Add infinite core upgrades, first/second element projects, specialization choice, and powerful augments.
- [x] Add material-project progress, carried-item deposits, and dev completion buttons.
- [x] Add dev level buttons for fast level-gate testing.
- [x] Add first-draft runtime combat effects for core upgrades, augments, elements, combos, passive repair, and vampiric healing.
- [x] Migrate old 0.3.x skill ranks into 0.4.0 core ranks where possible.

## Completed For V0.4.1

- [x] Publish V0.4.0 to the Factorio Mod Portal before continuing V0.4.1 work.
- [x] Add a non-stackable Veteran Core `item-with-tags` prototype and recipe.
- [x] Make ordinary gun turrets stay stackable and progression-free until a Veteran Core is installed.
- [x] Move XP, kills, damage, evolution choices, material projects, and dev XP onto the installed core profile.
- [x] Add install and extract controls to the Turret XP panel.
- [x] Return/spill the installed Veteran Core when a turret is mined.
- [x] Add core-carried custom names and optional floating labels in `name (lvl N)` format.
- [x] Add a dev core button for local testing.
- [x] Make the Evolution area vertically scrollable so it does not expand beyond the turret GUI.
- [x] Move playtest dev controls above the Evolution scroll area.
- [x] Simplify locked sections, core upgrade rows, and remove the Elements/Specialization summary line.

## Completed For V0.4.2

- [x] Add hidden gun-turret prototype variants for Sniper, Machine Gun, Bulwark, and Brawler.
- [x] Swap specialized turret bodies when a Veteran Core specialization is chosen.
- [x] Revert the turret body to vanilla `gun-turret` when the Veteran Core is extracted.
- [x] Replace exponential level scaling with linear per-level scaling.
- [x] Give powerful augments one augment point every ten levels instead of doubling rank costs.
- [x] Remove material deposit buttons and auto-consume the matching carried element material while the turret is open.
- [x] Add element mastery milestones and short visual feedback for bounce, pierce, fire, electric, and explosive upgrade effects.

## Completed For V0.4.3

- [x] Add a real Veteran Core feeder inventory entity.
- [x] Create the feeder near the turret when a Veteran Core is installed.
- [x] Consume element unlock and mastery materials from the feeder instead of the player inventory.
- [x] Show feeder status in the Evolution panel.
- [x] Destroy the feeder and spill leftover feeder contents when the core is extracted or the turret is mined.

## Completed For V0.4.4

- [x] Fix fresh Veteran Core install crash in legacy skill migration.
- [x] Cache derived level progress so high-level combat damage does not rescan every prior level.
- [x] Add user Respec and dev Reset controls.
- [x] Replace cropped text allocation buttons with vanilla-style icon buttons and useful hover text.

## Likely Next Work

- Playtest V0.4.4 from the Mod Portal and integrate feedback, especially around feeder placement, inserter usability, and high-level turret combat performance.
- Playtest and tune level gates, material costs, point costs, core recipe cost, specialization stats, and upgrade effect strength.
- Decide whether destroyed turrets should always lose cores, drop damaged cores, or have a recovery chance.
- Prototype an `entity-gui-lib` branch before any full replacement of the turret GUI.
- Evaluate `quality-lib` and/or prototype `custom_tooltip_fields` before adding quality-scaled custom stats.
- Add a lightweight website generator so `docs/index.html` is derived from `info.json`, `changelog.txt`, README content, and docs where practical.
- Fold website freshness into release validation so public docs and Mod Portal homepage do not drift from the mod.
- Add headless Factorio smoke-test automation if a stable local binary is available.
