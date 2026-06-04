# Project Spec

## Version 0.2.0

V0.2.0 is a UI polish and tracking prototype. It keeps the vanilla turret GUI as the main interaction while making the Turret XP relative panel feel closer to Factorio's own GUI language.

## Runtime Behavior

- State lives under `storage.turret_xp`.
- A turret state record is keyed by the turret entity `unit_number`.
- New turret records start at level 1 with zero XP, killing blows, kill credit, damage, and total XP.
- XP is derived from lifetime damage and kill credit using runtime-global mod settings.
- Default damage XP is `0.02` XP per final damage point.
- Default kill-credit XP is `20` XP per full kill credit.
- Default level XP starts at `100` and grows by a `1.65` exponential multiplier each level.
- Kill credit is split proportionally by damage contribution so turrets are not fully denied XP when another source lands the final hit.
- Destroyed or mined turrets remove their state.

## GUI Behavior

- `on_gui_opened` detects vanilla `gun-turret`.
- The mod creates a frame in `player.gui.relative` anchored to `defines.relative_gui_type.turret_gui` on the right side.
- If relative anchoring fails, the panel falls back to `player.gui.left`.
- `on_gui_closed` destroys the panel and clears the remembered player/turret link.
- The panel updates named elements every 60 ticks while the turret GUI remains open, without destroying and rebuilding the whole panel.
- The GUI depends on `flib >= 0.16.4` for shared Factorio-style slot, pusher, and indicator styles.

## Release Target

- Mod name: `turret_xp`
- Current version: `0.2.0`
- GitHub repository: `atyrode/turret_xp`
- Factorio Mod Portal title: `Turret XP`
