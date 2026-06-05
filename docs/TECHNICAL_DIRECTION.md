# Technical Direction

## Current Stack

- Factorio 2.0 runtime mod.
- Lua control-stage implementation with runtime-global settings.
- Runtime XP settings plus a required `flib >= 0.16.4` dependency for shared GUI styles.
- V0.6.1 uses an invisible hidden feeder inventory entity colocated with the turret for Veteran Core material inputs and element fuel, with runtime routing that moves inserter-fed ammo back into the turret ammo inventory. Element fuel is stored as a small burner buffer that fills to capacity and burns over time; the hidden input closes/destroys itself at the visible cap instead of holding excess valid fuel. Hidden gun-turret body variants let specialization multipliers and Range augment ranks change turret prototype stats, while the `item-with-tags` Veteran Core carries portable progression profiles. Space-platform turrets use explicit Turret XP panel actions to install exact cores from the platform hub inventory and send installed cores back to that hub.
- V0.4.4 caches derived level progress so normal combat applies XP deltas instead of recalculating from level 1 on every damage event.
- V0.4.5 uses local tag-preserving Veteran Core slot transfer logic. `entity-gui-lib` inventory display was inspected, but its current transfer helper copies name/count/quality and would not preserve Veteran Core item tags.
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
- Keep `flib` as the default first choice for richer GUI, migration, and shared utility work.
- If a feature remains custom after the check, document why the local implementation is small enough or more appropriate than adding a dependency.

## Libraries

`flib` is a dependency as of V0.2.0. Revisit the other libraries when a feature needs enough shared machinery to justify adding another dependency.

### Current Dependency

- `flib` / Factorio Library:
  - Factorio 2.0 compatible internal library mod.
  - Large adoption signal on the Mod Portal, with over 1M downloads and hundreds of dependent mods.
  - V0.4.x uses `flib` GUI styles for slot buttons, pushers, and compact panel structure.
  - Useful future modules for this project may include `gui`, `migration`, `dictionary`, `on-tick-n`, `queue`, `format`, `table`, and position/geometry helpers.

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
  - Source inspection of version 0.1.9 shows registration/priority handling, vanilla replacement or keep-vanilla mode, titlebar/preview/status scaffolding, tab helpers, live update callbacks, interactive inventory displays, and optional player inventory panels.
  - It still composes standard runtime GUI primitives such as frames, tables, scroll panes, and sprite buttons. It does not expose a research-tree canvas or add child-widget drag-panning beyond normal screen-frame dragging.
  - Treat this as the leading candidate if Turret XP moves from a right-side relative panel to a full custom turret GUI that owns inventory/status/preview layout and progression tabs.
  - Do not add it merely for the current Evolution list; `flib` plus local frame/table composition covers the 0.4.x UI without a lifecycle rewrite.
- `quality-lib`:
  - Factorio 2.0 library for modders to interface with Quality and add quality stats to items/entities.
  - Consider when Turret XP starts adding quality-scaled custom stats such as crit chance, crit damage, XP gain, or evolution effects.
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
- `LuaGuiElement::quality` is only a sprite-button overlay; it is not the same thing as the vanilla blue stat marker plus built-in quality delta popover shown in native entity/tooltips.
- `Prototype::custom_tooltip_fields` can add quality-aware values to native tooltips and Factoriopedia during the data stage, but it does not provide a direct runtime GUI element for arbitrary custom stat rows.
- Runtime custom GUI cannot instantiate the native Factoriopedia quality popover as a widget. The panel uses the real `[img=quality_info]` marker with a custom tooltip summary generated from Factorio quality prototypes for HP and range, filtering hidden fallback qualities.
- Runtime custom GUI also cannot instantiate the engine's internal technology-tree canvas as a reusable widget. V0.4.0 removes the experimental tree and uses a simple list while gameplay direction is tested.
- The local Factorio install exposes data/prototype/style Lua, but not the engine source for the research-tree canvas. Research-tree click-drag panning appears to be engine GUI behavior rather than reusable mod Lua.
- V0.3.2 attempted an embedded drag-pan spike. Playtesting showed no useful drag behavior in the relative turret GUI, so V0.4.0 removes the spike instead of keeping a misleading interaction.
- `LuaForce::get_gun_speed_modifier` exposes force shooting-speed research bonuses by ammo category.
- `LuaForce::get_ammo_damage_modifier` exposes force ammo-damage research bonuses by ammo category.
- `LuaForce::get_turret_attack_modifier` exposes turret-specific force damage bonuses; gun turret damage display needs this in addition to ammo damage.
- `LuaItemPrototype::ammo_category` and `AttackParameters::ammo_categories` are the correct bonus category sources for loaded ammo and fallback turret attack parameters.
- `ItemWithTagsPrototype` and `ItemStackDefinition.tags` support storing a core profile directly on a non-stackable item when it is extracted from a turret.
- `LuaItemStack::get_tag` and `LuaItemStack::set_tag` expose runtime tag access for tagged item stacks.
- `LuaRendering::draw_text` supports entity targets with offsets, which is used for optional `name (lvl N)` turret labels.
- Runtime GUI rows are not inserter-targetable inventories. V0.6.1 uses a real hidden chest-like feeder entity on the turret tile so material inputs and element-fuel storage can be fed like machine inventory without showing a fake chest. Because overlapping inserter targets can receive ammo first, the runtime routes ammo stacks from the hidden input into the turret ammo inventory. The feeder uses a one-slot custom-stack inventory with a bar so the input is open only while a project or burner needs resources.
- `LuaSurface::platform` exposes the platform for platform surfaces, `LuaSpacePlatform::hub` exposes the hub entity, and `defines.inventory.hub_main` is the hub inventory used for explicit platform Veteran Core selection. This keeps core choice deterministic when multiple tagged cores are present.
- `on_space_platform_mined_entity` is registered only when the runtime exposes it, and is used as a best-effort return path for installed cores mined on platforms.
- `LuaGuiElement::scroll_to_element` is used after Evolution list rebuilds to keep the clicked allocation row visible. Factorio does not expose a normal persisted scroll offset for this use case.

## Risks

- Damage estimation only covers direct damage effects in ammo prototype data. More complex projectile or nested modded ammo may show `Unknown`.
- Contribution-based kill credit is based on recent tracked target damage and prunes stale target entries after five minutes.
- Per-entity combat stat mutation is not designed yet. Factorio exposes force-wide modifiers more readily than individual turret attack modifiers.
- V0.4.1 implements mined turret persistence through the Veteran Core item. Destroyed turret recovery remains an open design question.
- Evolution points are derived from core profile level and stored under `state.evolution`.
- Runtime GUI cannot add a true extra slot inside the vanilla turret inventory, so Veteran Core install/extract uses explicit controls in the attached Turret XP panel.
- V0.6.1 specialization and Range augment stats are prototype-backed. Feeder placement is an invisible colocated input with ammo forwarding and cap-closing fuel behavior; edge cases around full turret ammo inventories, unsupported ammo, furnace-like element fuel readability, unusual inserter layouts, platform hub inventory fullness, or platform mining buffers still need playtesting.
- Core upgrades, augments, elements, combos, passive repair, and vampiric healing still need playtest balance and clearer feedback.
- The panel updates named elements in place every 60 ticks; new GUI work should preserve stable hover/read behavior.
- `flib` adds a dependency, but it is common and handled by the in-game dependency manager.
- `entity-gui-lib` is promising for full GUI replacement, but it would be a larger dependency and ownership shift than the current relative-panel polish needs.
- `entity-gui-lib` may still be useful for non-profile inventories or a full GUI replacement, but do not use its current inventory transfer helper for `item-with-tags` Veteran Cores unless tag preservation is added or wrapped.
- `quality-lib` may be valuable once Turret XP owns quality-scaled custom stats, but adding it should be an intentional dependency decision because it changes prototype/data-stage behavior.
- The website can become stale if it stays hand-maintained; keep generation from mod metadata/docs on the roadmap before the site grows.

## Validation Path

- Run `scripts/check.sh`.
- Run `scripts/package.sh`.
- Inspect the zip layout.
- If a local Factorio binary is available, run a headless load smoke test.
- Confirm the GitHub Pages homepage still matches the current release and documentation.
- Publish the current version, install from the in-game Mods interface, and manually test opening a turret plus turret combat.
