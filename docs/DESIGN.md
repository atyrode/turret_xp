# Design

## Gameplay Direction

The mod should make defensive infrastructure feel more personal without making early defenses trivial or turning every cheap turret into inventory metadata. A turret becomes notable when the player installs a Veteran Core and that core survives, fights, grows, and moves between turret bodies.

The current design priority is specialization over universal upgrades. A sniper turret, machine-gun turret, bulwark turret, brawler turret, and duo-element turret should feel meaningfully different instead of becoming the same stat line at different power levels.

## Public Identity

Public copy should be short and player-facing: chosen turrets become veterans, Veteran Cores carry progression, combat earns upgrades, specializations create identity, and material-fed elements add build variety. Avoid implementation-first wording such as runtime, prototype-backed, hidden feeder, or first playable except in internal docs.

The portal image should be simple, sober, and specific to the mod. Prefer Factorio-native visual language: a gun turret, a Veteran Core/chip motif, an XP or level accent, and at most one restrained elemental indicator. Do not use generic action-scene art that looks detached from Factorio's UI and item language.

## Current UX Direction

- Keep the vanilla turret GUI as the main interaction.
- Attach Turret XP as a bounded two-column panel: Veteran Core identity, XP, dev controls, and stats on the left; Evolution on the right.
- Treat the 0.11 GUI glowup as an anchored custom interface, not a move away from the vanilla turret GUI unless the relative GUI API blocks a required interaction. The panel should keep living beside the opened turret while adopting the hierarchy, icon language, spacing, and action discoverability shown by mature utility mods such as Factory Planner.
- Use a Factorio-style header plus shallow content panes as the default frame language: the Turret XP shell owns the anchored frame and top-level columns, while section modules own their local content.
- Keep the Evolution column stable: a fixed summary header, one scrollable section body, section widths derived from the viewport, and no content rendering under the scrollbar.
- Keep the Stats pane visually parallel to Evolution: a fixed header and a bounded scroll body for stat rows and ammo readouts.
- Use direct labels, compact controls, restrained rich text markers, and vanilla-like layout rhythm.
- Keep stat rows scannable: show final values in the panel, put formulas in the stat-name info hover, and reserve the quality diamond for quality-specific HP/range breakdowns.
- Keep dev controls hidden by default and toggled through `/turret-xp-dev`.
- Use the Veteran Core slot as a scripted tag-preserving control. Do not imply native arbitrary inventory-slot support inside the vanilla turret GUI.
- When no core is installed, use the left-column Veteran Core panel as an exact core picker: list tagged Veteran Cores from the player's inventory, sort highest level first, show name, level, specialization, and compact HP/attack-speed/range preview values, and install the chosen row through a compact `+` action.
- Keep platform core selection explicit: when multiple tagged cores are in a platform hub, the player chooses the exact row.
- Keep Bind/Unbind visually attached to the installed Veteran Core, because bound turret movement is an opt-in quick-move mode for that core/turret pair.
- Keep floating-label controls top-down and conditional: name field plus `Show`, RGB sliders/preset controls only when the label is shown, then the `Level` option.
- Keep numeric value coloring precise: unchanged values stay neutral, beneficial deltas use muted green, harmful deltas use muted red, units/prose stay neutral, and element colors are reserved for elemental damage numbers.
- Use optional Bullet Trails and vanilla visual prototypes for readability, but keep fallback visuals lightweight and avoid visual spam.
- Prefer custom local GUI helpers and focused domain widgets over a generic one-off panel file. `flib` is an accepted foundation for vanilla-like styles and helper patterns, but Turret XP should own the Veteran Core, stats, Evolution, element, and action interaction model directly.

## Progression Direction

The long-term progression design is captured in [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md). The current playable draft uses a level-gated Evolution list:

- Core upgrades are available immediately once a Veteran Core is installed.
- Specialization unlocks at level 10.
- First element unlocks at level 20.
- Augments unlock at level 30.
- Sub-specialization unlocks at level 40.
- Second element and combo identity unlock at level 50.

Combat XP grants levels and points. Materials express industrial commitment: selected elements expose their next material rank and accept passive inserter-fed progress through the hidden turret-tile input.

New progression-system scope is frozen while the current playable loop is hardened. Balance, readability, GUI quality, validation, and bug fixes can continue; new branches, elements, mastery loops, or prototype-backed axes need their own approved issue.

## Balance Direction

- Early levels should arrive fast enough for testing and feedback, but long-term curves should not let one turret replace full defensive planning.
- Damage should contribute relatively little XP because damage totals grow quickly.
- Kill credit should be based on damage contribution so final-hit stealing does not erase turret progress.
- Space-platform combat and asteroid defense should not passively overlevel cores.
- Strong roles should carry tradeoffs: range for fire rate, fire rate for damage per shot, survivability for peak damage, XP gain for immediate power.
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
