# Technical Direction

## Current Stack

- Factorio 2.0 runtime mod.
- Lua control-stage implementation only.
- No custom prototypes beyond standard empty `data.lua` and `settings.lua` placeholders.
- Python packaging script reused from `player_quality`.
- Shell scripts for checks, packaging, local install, GitHub release, and Mod Portal publishing.

## API Notes

- `on_gui_opened` provides the opened entity for entity GUIs.
- `defines.relative_gui_type.turret_gui` is the intended anchor for extending the vanilla turret GUI.
- `LuaGuiElement.add` supports `anchor` when adding to `player.gui.relative`.
- `LuaItemPrototype::get_ammo_type("turret")` exposes loaded ammo prototype data for best-effort damage estimates.

## Risks

- Damage estimation only covers direct damage effects in ammo prototype data. More complex projectile or nested modded ammo may show `Unknown`.
- Per-entity combat stat mutation is not designed yet. Factorio exposes force-wide modifiers more readily than individual turret attack modifiers.
- Mined turret persistence is intentionally out of scope for V0.1.0.
- Rebuilding the panel every 60 ticks is simple and reliable for the prototype, but later versions should update named elements in place if the GUI grows.

## Validation Path

- Run `scripts/check.sh`.
- Run `scripts/package.sh`.
- Inspect the zip layout.
- If a local Factorio binary is available, run a headless load smoke test.
- Publish `0.1.0`, install from the in-game Mods interface, and manually test a turret shooting enemies.
