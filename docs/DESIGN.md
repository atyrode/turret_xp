# Design

## Gameplay Direction

The mod should make defensive infrastructure feel more personal without making early defenses trivial or turning every cheap turret into inventory metadata. A turret becomes notable when the player installs a Veteran Core and that core survives, fights, grows, and moves between turret bodies.

The current design priority is specialization over universal upgrades. A sniper turret, machine-gun turret, bulwark turret, brawler turret, and duo-element turret should feel meaningfully different instead of becoming the same stat line at different power levels.

## Public Identity

Public copy should be short and player-facing: chosen turrets become veterans, Veteran Cores carry progression, combat earns upgrades, specializations create identity, and material-fed elements add build variety. Avoid implementation-first wording such as runtime, prototype-backed, hidden feeder, or first playable except in internal docs.

The portal image should be simple, sober, and specific to the mod. Prefer Factorio-native visual language: a gun turret, a Veteran Core/chip motif, an XP or level accent, and at most one restrained elemental indicator. Do not use generic action-scene art that looks detached from Factorio's UI and item language.

## Current UX Direction

- Keep the vanilla turret GUI as the main interaction.
- Attach Turret XP as a bounded panel beside the vanilla turret GUI. Installed cores use a two-column layout: Veteran Core identity, XP, dev controls, and stats on the left; Evolution on the right. Empty turrets use one full-width Veteran Core picker instead of a split dashboard.
- Treat the 0.11 GUI glowup as an anchored custom interface, not a move away from the vanilla turret GUI unless the relative GUI API blocks a required interaction. The panel should keep living beside the opened turret while adopting the hierarchy, icon language, spacing, and action discoverability shown by mature utility mods such as Factory Planner.
- Use a Factorio-style header plus shallow content panes as the default frame language: the Turret XP shell owns the anchored frame and top-level columns, while section modules own their local content.
- Keep the Evolution column stable: a fixed summary header, one scrollable section body, section widths derived from the viewport, and no content rendering under the scrollbar.
- Keep Evolution choice-card actions in one title-row action slot so descriptions and technical rows can use the full card width.
- Keep locked Evolution sections scannable by showing the section name and level gate in the same header rhythm as unlocked sections.
- Keep the Stats pane visually parallel to Evolution: a fixed header and a bounded scroll body with distinct native subheader strips for identity, defense, offense, ammo, history, and active effects.
- Use direct labels, compact controls, restrained rich text markers, and vanilla-like layout rhythm.
- Keep Evolution rank allocation controls as consistent compact steppers: normal click changes one rank, Shift-click changes up to ten, and Ctrl-click spends or refunds the whole applicable amount.
- Keep stat rows scannable: show final values in the panel, put formulas in the stat-name info hover, and reserve the quality diamond for quality-specific HP/range breakdowns.
- Keep dev controls hidden by default and toggled through `/turret-xp-dev`.
- Use the Veteran Core slot as a scripted tag-preserving control. Do not imply native arbitrary inventory-slot support inside the vanilla turret GUI.
- When no core is installed, use the whole Turret XP body as an exact core picker: keep the scripted Veteran Core slot and short explanation at the top, then dedicate the remaining space to tagged Veteran Cores from the player's inventory. The list should read as a Factorio table: clickable headers for level, name, specialization, HP, attack speed, and range cycle active direction with a compact right-side table-header sprite cue and then clear back to the default strongest-core ordering; level descending is the visible default sorted state. `All` is the default filter and specific Base/Sniper/Machine gun/Bulwark/Brawler checkboxes narrow visible rows; sort and filter choices persist across closing, reopening, and switching turrets. Unnamed cores stay last when sorting by name. Rows should use plain neutral level/stat preview labels so red/green remain reserved for nerf/boost semantics in the installed-core stats UI, a separate specialization column with shared specialization colors, striped row backgrounds, one header/body divider, and a compact `+` action for the exact inventory slot. Do not repeat the item icon in every row; show one Veteran Core display slot in the picker header. Kills and lifetime damage are historical context, not picker-decision columns.
- Keep platform core selection explicit: when multiple tagged cores are in a platform hub, the player chooses the exact separated row using level, specialization, and neutral preview stats rather than lifetime history counters or buff/penalty colors.
- Keep the installed Veteran Core header focused on the core's name, level, and bound/unbound state, with extract and Bind/Unbind grouped as the right-side action toolbar because bound turret movement is an opt-in quick-move mode for that core/turret pair.
- Expose installed-core extraction both through the scripted slot interaction and through a clear compact action that moves the core to the player inventory when there is room.
- Render installed-core naming and floating-label controls as a compact shallow form: the name row keeps `Show` beside the text field, and the conditional label-color row keeps a small square swatch, color-picker trigger, and `Level` suffix toggle together. The trigger opens Turret XP's own draggable `player.gui.screen` popup for presets and RGB sliders. The native train/player color picker is not exposed to runtime mod GUIs, so Turret XP should mimic the swatch-plus-picker interaction without implying the engine popup is available.
- Keep numeric value coloring precise: unchanged values stay neutral, beneficial deltas use muted green, harmful deltas use muted red, units/prose stay neutral, and element colors are reserved for elemental damage numbers.
- Prefer `gui_support` rich-value and specialization-caption helpers for repeated numeric and identity captions so level, history, formulas, summaries, and specialization labels do not hand-roll rich-text color tags. The empty-core picker decision columns are the exception: level, HP, attack, and range stay plain neutral labels.
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
- Open-GUI refreshes should not destroy and recreate interactive controls unless a relevant state key changed; steady-state polling should update stable content in place or skip work so clicks do not race timer rebuilds.
