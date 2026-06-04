# Project Spec

## Version 0.1.0

V0.1.0 is a UI and tracking prototype. It proves that per-turret progression can be tracked in live saves and shown in the vanilla gun turret workflow.

## Runtime Behavior

- State lives under `storage.turret_xp`.
- A turret state record is keyed by the turret entity `unit_number`.
- New turret records start at level 1 with zero XP, kills, damage, and total XP.
- XP needed for the next level starts at 100 and increases by 50 per level.
- Damage XP is currently one XP per final damage point.
- Kill XP is currently 20 XP.
- Destroyed or mined turrets remove their state.

## GUI Behavior

- `on_gui_opened` detects vanilla `gun-turret`.
- The mod creates a frame in `player.gui.relative` anchored to `defines.relative_gui_type.turret_gui` on the right side.
- If relative anchoring fails, the panel falls back to `player.gui.left`.
- `on_gui_closed` destroys the panel and clears the remembered player/turret link.
- The panel refreshes every 60 ticks while the turret GUI remains open.

## Release Target

- Mod name: `turret_xp`
- Version: `0.1.0`
- GitHub repository: `atyrode/turret_xp`
- Factorio Mod Portal title: `Turret XP`
