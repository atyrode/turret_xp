# Design

## Gameplay Direction

The mod should make defensive infrastructure feel more personal without making early defenses trivial or turning every cheap turret into inventory metadata. A turret becomes notable when the player installs a Veteran Core and that core survives, fights, grows, and moves between turret bodies.

The current design priority is specialization over universal upgrades. A sniper turret, machine-gun turret, bulwark turret, brawler turret, and duo-element turret should feel meaningfully different instead of becoming the same stat line at different power levels.

## Public Identity

Public copy should be short and player-facing: chosen turrets become veterans, Veteran Cores carry progression, combat earns upgrades, specializations create identity, and material-fed elements add build variety. Avoid implementation-first wording such as runtime, prototype-backed, hidden feeder, or first playable except in internal docs.

The portal image should be simple, sober, and specific to the mod. Prefer Factorio-native visual language: a gun turret, a Veteran Core/chip motif, an XP or level accent, and at most one restrained elemental indicator. Do not use generic action-scene art that looks detached from Factorio's UI and item language.

## Current UX Direction

- Keep the vanilla turret GUI as the main interaction and attach Turret XP beside it when the relative GUI API allows it.
- Treat the current two-column installed-core panel as current implemented behavior, not the future design target. Exact current behavior remains described in [PROJECT_SPEC.md](PROJECT_SPEC.md) until a replacement lands.
- Restart the next major GUI redesign through the spec-first workflow in [GUI_SPEC_FACTORY.md](GUI_SPEC_FACTORY.md), with the concrete future design captured in [TURRET_XP_GUI_SPEC.md](TURRET_XP_GUI_SPEC.md).
- The next installed-core direction is a Veteran Core Workbench: progression editing, Build Plan mode, Follow build state, and key stat consequences must be visible together instead of split across unrelated tabs or old left/right implementation sections.
- The next empty-turret direction is still a focused Core Picker. Preserve the successful table-first picker behavior unless a later spec gives a better concrete replacement.
- Do not carry forward the failed focused-tabs layout or the old left-stats/right-Evolution dashboard as a layout source. Preserve gameplay features and interaction contracts, not the previous nesting structure.
- Keep numeric value coloring precise: unchanged values stay neutral, beneficial deltas use muted green, harmful deltas use muted red, units/prose stay neutral, and element colors are reserved for elemental damage numbers.
- Keep dev controls hidden by default and toggled through `/turret-xp-dev`.
- Use the Veteran Core slot as a scripted tag-preserving control. Do not imply native arbitrary inventory-slot support inside the vanilla turret GUI.
- Use optional Bullet Trails and vanilla visual prototypes for readability, but keep fallback visuals lightweight and avoid visual spam.

## Progression Direction

The long-term progression design is captured in [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md). The current playable draft uses a level-gated Evolution list. Core upgrades are available immediately once a Veteran Core is installed. Specialization, first element, augments, sub-specialization, and second element/combo unlock gates are defined once in `scripts/domain.lua` as `domain.gates`.

Combat XP grants levels and points. Materials express industrial commitment: selected elements expose their next material rank and accept passive inserter-fed progress through the hidden turret-tile input.

New progression-system scope is frozen while the current playable loop is hardened. Balance, readability, GUI quality, validation, and bug fixes can continue; new branches, elements, mastery loops, or prototype-backed axes need their own approved issue.

## Balance Direction

- Early levels should arrive fast enough for testing and feedback, but long-term curves should not let one turret replace full defensive planning.
- Damage should contribute relatively little XP because damage totals grow quickly.
- Kill credit should be based on damage contribution so final-hit stealing does not erase turret progress.
- Space-platform combat and asteroid defense should not passively overlevel cores.
- Strong roles should carry tradeoffs: range for fire rate, fire rate for damage per shot, survivability for peak damage, XP gain for immediate power.
- Build mode automation is setup convenience, not a new balance layer. It spends the same point economy a player can spend manually.
- Native stat identity should stay limited to specialization and sub-specialization bodies. Repeatable Range or Max HP prototype axes, quality-backed chassis rewrites, and range-band rewrites are out of scope for the current direction.
- Scripted effects such as bounce, chain arcs, status damage, and visuals need explicit performance and readability budgets before they grow.

## Compatibility Direction

- Start with vanilla `gun-turret`.
- Hidden turret variants are acceptable for real specialization and sub-specialization body stats when Factorio exposes no per-entity runtime setter. New variant dimensions are not accepted by default.
- Resistance should remain scripted unless a better per-core defense model appears, because it avoids another hidden prototype axis.
- Ammo range compatibility should preserve non-turret ammo behavior while fixing turret-fired projectile caps for upgraded specialist turret ranges.
- Later support for modded ammo turrets should be prototype-driven.
- Laser, flamethrower, artillery, and electric turrets likely need separate stat, XP, and UI rules.

## Feedback Direction

- The GUI should show the turret's current identity, next useful goal, and active tradeoffs without requiring the player to read implementation details.
- Material progress should be visible as progress toward a goal, not hidden in tooltips.
- Elemental and critical feedback should be noticeable enough to verify during play, but quiet enough for busy defenses.
- Open-GUI interactions must not move the whole vanilla turret GUI. Prototype body swaps should stay deferred until the turret GUI closes.
- Open-GUI refreshes should not destroy and recreate interactive controls unless a relevant state key changed; steady-state polling should update stable content in place or skip work so clicks do not race timer rebuilds.
