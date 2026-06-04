# Technical Direction

## Current Stack

- Factorio 2.0 runtime mod.
- Lua control-stage implementation with runtime-global settings.
- No custom prototypes beyond runtime XP settings and standard empty `data.lua` placeholder.
- Python packaging script reused from `player_quality`.
- Shell scripts for checks, packaging, local install, GitHub release, and Mod Portal publishing.
- Static GitHub Pages homepage served from `docs/index.html`.

## Website Direction

- Keep the public website current whenever the mod version, user-visible behavior, documentation, or release status changes.
- Treat the website as a generated or mostly generated project surface, not as independent marketing copy.
- Prefer deriving website content from existing sources such as `info.json`, `changelog.txt`, `README.md`, locale strings, and the Markdown docs.
- Avoid duplicating version numbers, feature lists, playtest steps, and roadmap notes in hand-written HTML when a script can read them from existing files.
- Near-term acceptable state: a simple static page with a documented obligation to keep it aligned.
- Target state: a small generator updates `docs/index.html` from repo metadata/docs, and release/publish workflows run or check that generator before publishing.

## Dependency Check Policy

- Before implementing a feature with substantial custom GUI plumbing, migration machinery, data structures, scheduling, debugging UI, or workaround-style code, check the Factorio Mod Portal for maintained libraries that already solve that class of problem.
- Prefer documented, Factorio 2.0 compatible, well-adopted libraries over local reimplementation when they reduce risk and maintenance cost.
- Keep `flib` as the first library to re-evaluate for richer GUI and migration work.
- If a feature remains custom after the check, document why the local implementation is small enough or more appropriate than adding a dependency.

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
- `entity-gui-lib`:
  - Factorio 2.0 library for replacing or extending vanilla entity GUIs with vanilla-styled custom entity interfaces.
  - Includes quality-aware item/tooltips and entity GUI helpers.
  - Consider if Turret XP outgrows a small relative panel and needs a full custom entity GUI, tabs, inventory display, or multi-mod GUI conflict handling.
- `quality-lib`:
  - Factorio 2.0 library for modders to interface with Quality and add quality stats to items/entities.
  - Consider when Turret XP starts adding quality-scaled custom stats such as crit chance, crit damage, XP gain, or skill-tree effects.
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
- `LuaEntity::quality`, `sprite-button` quality overlays, and `elem_tooltip` with `entity-with-quality` allow the panel's turret icon to use vanilla quality tooltip behavior.
- `LuaForce::get_gun_speed_modifier` exposes force shooting-speed research bonuses by ammo category.
- `LuaForce::get_ammo_damage_modifier` exposes force ammo-damage research bonuses by ammo category.

## Risks

- Damage estimation only covers direct damage effects in ammo prototype data. More complex projectile or nested modded ammo may show `Unknown`.
- Contribution-based kill credit is based on recent tracked target damage and prunes stale target entries after five minutes.
- Per-entity combat stat mutation is not designed yet. Factorio exposes force-wide modifiers more readily than individual turret attack modifiers.
- Mined turret persistence is intentionally out of scope for V0.1.x.
- Rebuilding the panel every 60 ticks is simple and reliable for the prototype, but later versions should update named elements in place if the GUI grows.
- Adding `flib` would make users install an extra dependency, but it is common and handled by the in-game dependency manager.
- `entity-gui-lib` is promising for full GUI replacement, but it would be a larger dependency and ownership shift than this V0.1.x relative-panel polish needs.
- `quality-lib` may be valuable once Turret XP owns quality-scaled custom stats; for now the HP marker uses the direct runtime prototype API.
- The website can become stale if it stays hand-maintained; keep generation from mod metadata/docs on the roadmap before the site grows.

## Validation Path

- Run `scripts/check.sh`.
- Run `scripts/package.sh`.
- Inspect the zip layout.
- If a local Factorio binary is available, run a headless load smoke test.
- Confirm the GitHub Pages homepage still matches the current release and documentation.
- Publish the current version, install from the in-game Mods interface, and manually test opening a turret plus turret combat.
