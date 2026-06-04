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
- [x] Rebalance default XP with low damage XP, kill-credit XP, and exponential level growth.
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

## Likely Next Work

- Decide first real level bonuses.
- Decide whether mined turrets retain XP.
- Prototype an `entity-gui-lib` branch before any full replacement of the turret GUI.
- Evaluate `quality-lib` and/or prototype `custom_tooltip_fields` before adding quality-scaled custom stats.
- Add a lightweight website generator so `docs/index.html` is derived from `info.json`, `changelog.txt`, README content, and docs where practical.
- Fold website freshness into release validation so public docs and Mod Portal homepage do not drift from the mod.
- Add headless Factorio smoke-test automation if a stable local binary is available.
