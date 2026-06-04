# Project Spec

## Version 0.3.1

V0.3.1 is a focused skill-tree and XP-bar polish release. It keeps the vanilla turret GUI as the main interaction while changing the Turret XP relative panel's skill section from a fixed row into a scrollable technology-style tree surface.

## Runtime Behavior

- State lives under `storage.turret_xp`.
- A turret state record is keyed by the turret entity `unit_number`.
- New turret records start at level 1 with zero XP, kills, kill credit, damage, total XP, and skill ranks.
- XP is derived from lifetime damage and kill credit using runtime-global mod settings.
- Default damage XP is `0.02` XP per final damage point.
- Default kill-credit XP is `20` XP per full kill credit.
- Default level XP starts at `100` and grows by a `1.65` exponential multiplier each level.
- Kill credit is split proportionally by damage contribution so turrets are not fully denied XP when another source lands the final hit.
- Skill points equal `level - 1 - spent_points`.
- Ballistics Drill increases damage XP, Kill Chain increases kill-credit XP, Targeting Data increases all XP, and Field Repairs slowly repairs damaged skilled turrets.
- Skill hover tooltips show only the next allocated effect, with rich-text coloring.
- The central gun-turret root node summarizes currently allocated bonuses on hover.
- Destroyed or mined turrets remove their state.

## GUI Behavior

- `on_gui_opened` detects vanilla `gun-turret`.
- The mod creates a frame in `player.gui.relative` anchored to `defines.relative_gui_type.turret_gui` on the right side.
- If relative anchoring fails, the panel falls back to `player.gui.left`.
- `on_gui_closed` destroys the panel and clears the remembered player/turret link.
- The panel updates named elements every 60 ticks while the turret GUI remains open, without destroying and rebuilding the whole panel.
- The GUI depends on `flib >= 0.16.4` for shared Factorio-style slot, technology-slot, pusher, scroll-pane, and indicator styles.
- The XP bar uses a custom solid progressbar style defined in `data.lua`.

## Release Target

- Mod name: `turret_xp`
- Current version: `0.3.1`
- GitHub repository: `atyrode/turret_xp`
- Factorio Mod Portal title: `Turret XP`
