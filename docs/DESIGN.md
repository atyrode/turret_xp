# Design

## Gameplay Direction

The mod should make defensive infrastructure feel more personal without making early defenses trivial or turning every cheap turret into inventory metadata. A turret becomes notable when the player installs a Veteran Core and that core survives, fights, grows, and moves between turret bodies.

The current design priority is specialization over universal upgrades. A sniper turret, machine-gun turret, bulwark turret, brawler turret, and duo-element turret should feel meaningfully different instead of becoming the same stat line at different power levels.

## Public Identity

Public copy should be short and player-facing: chosen turrets become veterans, Veteran Cores carry progression, combat earns upgrades, specializations create identity, and material-fed elements add build variety. Avoid implementation-first wording such as runtime, prototype-backed, hidden feeder, or first playable except in internal docs.

The portal image should be simple, sober, and specific to the mod. Prefer Factorio-native visual language: a gun turret, a Veteran Core/chip motif, an XP or level accent, and at most one restrained elemental indicator. Do not use generic action-scene art that looks detached from Factorio's UI and item language.

## Current UX Direction

- Keep the vanilla turret GUI as the main interaction.
- Treat the attached GUI contract in [GUI_SPEC.md](GUI_SPEC.md) as the source of truth for visible surfaces, layout rules, and acceptance criteria.
- Attach Turret XP as a bounded panel beside the vanilla turret GUI. Installed cores use a compact status strip, focused view navigation, and one active content pane. Empty turrets use a separate picker workflow instead of the installed-core dashboard.
- Treat the GUI redesign as a player-workflow reset, not a visual patch. The core gameplay loop remains Veteran Cores earning XP and progression, but progression, stats, specialization, elements, labels, and automation may be regrouped if that creates a clearer and more enjoyable interface.
- Keep the panel living beside the opened turret while adopting the hierarchy, icon language, spacing, and action discoverability shown by mature utility mods such as Factory Planner.
- Use a Factorio-style titlebar, compact status strip, shallow navigation, and one main scrollable content area as the default frame language. Do not return to the old permanent left-stats/right-evolution split.
- Keep Overview calm: identity, XP, current role, next goal, and primary actions only. Full stat tables, progression allocation lists, and build-target details belong behind focused views.
- Let Progression own spendable decisions. Core upgrades, specialization, sub-specialization, augments, elements, combos, and material ranks may be grouped by player intent instead of implementation category.
- Let Stats be a detail view. It keeps the grouped value contract, stable label/value alignment, and formula hovers without occupying first-screen space.
- Let Automation own Build mode, Follow build, copied/blueprinted target summaries, planned spending, and conflicts. Only compact build state and primary actions may surface outside that view.
- Use direct labels, compact controls, restrained rich text markers, and vanilla-like layout rhythm.
- Keep decorative Evolution icons in fixed cells with stretched sprites so Factorio interface scale changes cannot let icon artwork collide with adjacent labels or action controls.
- Keep Evolution rank allocation controls as consistent compact steppers: normal click changes one rank, Shift-click changes up to ten, and Ctrl-click spends or refunds the whole applicable amount.
- Keep stat rows scannable: show final values in the panel, put formulas in the stat-name info hover, and reserve the quality diamond for quality-specific HP/range breakdowns.
- Keep dev controls hidden by default and toggled through `/turret-xp-dev`.
- Hide Dev-only controls in GUI snapshot review mode so screenshots show the player-facing layout even when local development controls are enabled.
- Use the Veteran Core slot as a scripted tag-preserving control. Do not imply native arbitrary inventory-slot support inside the vanilla turret GUI.
- When no core is installed, use the whole Turret XP body as an exact core picker: keep the scripted Veteran Core slot and short explanation at the top, then show tagged Veteran Cores from the player's inventory in an adaptive-height table. The list should keep stable row/header metrics, show up to a small capped number of rows before scrolling, and avoid dead vertical slabs when only a few cores are available. Clickable headers for level, name, specialization, HP, attack speed, and range cycle active direction with a compact right-side table-header cue and then clear back to the default strongest-core ordering; level descending is the visible default sorted state. `All` is the default filter and Base/Sniper/Machine gun/Bulwark/Brawler checkboxes narrow visible rows; sort and filter choices persist across closing, reopening, and switching turrets. Unnamed cores stay last when sorting by name. Rows should use plain neutral level/stat preview labels so red/green remain reserved for nerf/boost semantics in the installed-core stats UI, a separate specialization column with shared specialization colors, striped row backgrounds, one header/body divider, and a compact `+` action for the exact inventory slot. Do not repeat the item icon in every row; show one Veteran Core display slot in the picker header. Kills and lifetime damage are historical context, not picker-decision columns.
- Keep platform core selection explicit: when multiple tagged cores are in a platform hub, the player chooses the exact separated row using level, specialization, and neutral preview stats rather than lifetime history counters or buff/penalty colors.
- Keep the installed Veteran Core status focused on the core's name, level, XP, bound/unbound state, and primary actions because bound turret movement is an opt-in quick-move mode for that core/turret pair.
- Expose installed-core extraction both through the scripted slot interaction and through a clear compact action that moves the core to the player inventory when there is room.
- Render installed-core naming and floating-label controls as a compact shallow form: the custom-name field stays separate from independent `Name`, `Level`, and `Unspent` display toggles, and the conditional label-color row keeps a small square swatch plus color-picker trigger. The trigger opens Turret XP's own draggable `player.gui.screen` popup for presets and RGB sliders. The native train/player color picker is not exposed to runtime mod GUIs, so Turret XP should mimic the swatch-plus-picker interaction without implying the engine popup is available.
- Keep automation explicit and Factorio-native: Build mode previews a target path, Follow build executes that path in live mode, and copied/blueprinted target builds are the primary automation path for repeated defenses. Native blueprints should act as the build library; a copied turret target can request or manually receive a fresh core and spend toward the source build over time without cloning XP, history, names, or exact identity.
- Keep the installed shell progressive: the status strip owns only durable identity and primary actions. Target level, core and augment budgets, specialization, element, formula details, and conflict handling belong in Automation or Progression views, not in the always-visible chrome.
- Do not let copied target builds silently overwrite manual specialization, sub-specialization, or element identity choices that conflict with the target. Surface the conflict and continue spending only the compatible parts of the build.
- Let copied/blueprinted empty turrets with pending target builds request a Veteran Core through logistics in the same spirit as vanilla requester-driven machine setup, but present it as Turret XP setup fulfillment rather than a native turret inventory slot. The pending slot should also accept manual Veteran Core placement, and the hidden requester should stay invisible, narrow, and cleanup-safe.
- Keep numeric value coloring precise: unchanged values stay neutral, beneficial deltas use muted green, harmful deltas use muted red, units/prose stay neutral, and element colors are reserved for elemental damage numbers.
- Prefer `gui_support` rich-value and specialization-caption helpers for repeated numeric and identity captions so level, history, formulas, summaries, and specialization labels do not hand-roll rich-text color tags. The empty-core picker decision columns are the exception: level, HP, attack, and range stay plain neutral labels.
- Use optional Bullet Trails and vanilla visual prototypes for readability, but keep fallback visuals lightweight and avoid visual spam.
- Prefer custom local GUI helpers and focused domain widgets over a generic one-off panel file. `flib` is an accepted foundation for vanilla-like styles and helper patterns, but Turret XP should own the Veteran Core, stats, Evolution, element, and action interaction model directly.
- GUI changes that add a new view or mode must update shared shell/content helpers first when spacing, padding, or background treatment changes. A visual fix is not complete until the headless structural contract still proves the focused-view layout and a graphical screenshot review confirms the result at common UI scales.

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
