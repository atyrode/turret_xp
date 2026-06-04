# Technical Direction

## Current Stack

- Factorio 2.0 runtime mod.
- Lua control-stage implementation only.
- No custom prototypes beyond standard empty `data.lua` and `settings.lua` placeholders.
- Python packaging script reused from `player_quality`.
- Shell scripts for checks, packaging, local install, GitHub release, and Mod Portal publishing.

## Libraries To Consider

These libraries are not dependencies today. Revisit them when a feature needs enough shared machinery to justify adding a dependency.

### Strong Candidate

- `flib` / Factorio Library:
  - Factorio 2.0 compatible internal library mod.
  - Large adoption signal on the Mod Portal, with over 1M downloads and hundreds of dependent mods.
  - Useful future modules for this project include `gui`, `migration`, `dictionary`, `on-tick-n`, `queue`, `format`, `table`, and position/geometry helpers.
  - Consider adding `flib >= 0.16.5` before building a richer upgrade UI, player-configurable GUI, substantial migration logic, or queued/deferred processing.

### Possible But Lower Priority

- `stdlib2` / Factorio Standard Library 2.0:
  - Factorio 2.0 compatible fork of the older Stdlib project.
  - Potentially useful for event and GUI helpers, but current 2.0 maintenance/adaptation looks less clear than `flib`.
  - Consider only if a specific module is clearly better than `flib` or local code.
- `Kux-GuiLib` / `Kux-CoreLib`:
  - Factorio 2.0 compatible libraries used by Kuxynator mods.
  - Could be useful for GUI-specific work, but they are less general-purpose for this project than `flib`.
- `gvv`:
  - Debugging tool, not a production dependency.
  - Consider as a local playtest/dev dependency if inspecting `storage.turret_xp` in game becomes useful.

### Avoid For Now

- `gui-modules`:
  - Factorio 2.0 compatible, but low adoption, no documentation, and the Mod Portal page warns that usage may change.
- `zk-lib`:
  - Broad WIP framework with many addons. Too large and experimental for `turret_xp` right now.
- `eradicators-library`:
  - Useful historical runtime framework, but the Mod Portal release checked targets Factorio 1.1, not 2.0.

## API Notes

- `on_gui_opened` provides the opened entity for entity GUIs.
- `defines.relative_gui_type.turret_gui` is the intended anchor for extending the vanilla turret GUI.
- `LuaGuiElement.add` supports `anchor` when adding to `player.gui.relative`.
- `LuaItemPrototype::get_ammo_type("turret")` exposes loaded ammo prototype data for best-effort damage estimates.

## Risks

- Damage estimation only covers direct damage effects in ammo prototype data. More complex projectile or nested modded ammo may show `Unknown`.
- Per-entity combat stat mutation is not designed yet. Factorio exposes force-wide modifiers more readily than individual turret attack modifiers.
- Mined turret persistence is intentionally out of scope for V0.1.x.
- Rebuilding the panel every 60 ticks is simple and reliable for the prototype, but later versions should update named elements in place if the GUI grows.
- Adding `flib` would make users install an extra dependency, but it is common and handled by the in-game dependency manager.

## Validation Path

- Run `scripts/check.sh`.
- Run `scripts/package.sh`.
- Inspect the zip layout.
- If a local Factorio binary is available, run a headless load smoke test.
- Publish the current version, install from the in-game Mods interface, and manually test opening a turret plus turret combat.
