# Technical Direction

## Current Stack

- Factorio 2.0 runtime mod.
- Lua control-stage implementation with runtime-global settings.
- Runtime XP settings plus a required `flib >= 0.16.4` dependency for shared GUI styles and an optional `bullet-trails >= 0.7.1` dependency for richer scripted projectile tracers.
- V0.9.1 uses modular runtime files under `scripts/control/` and modular data-stage files under `prototypes/`; `control.lua`, `data.lua`, and `data-final-fixes.lua` are entrypoints only. Shared stable gameplay IDs, progression caps, specialization/sub-specialization data, label presets, and generated variant-name helpers live in the pure `scripts/domain.lua` module so data stage, runtime, and headless tests do not maintain parallel domain tables. Gameplay state remains under `storage.turret_xp`.
- Incremental runtime refactors should move pure helper groups to explicit returned-table modules required by their callers. `scripts/control/label_colors.lua`, `scripts/control/compat.lua`, `scripts/control/bound_turret_items.lua`, `scripts/control/damage_accounting.lua`, and `scripts/control/gui_support.lua` use this pattern; larger subsystem moves should remain separate issue-sized changes.
- Factorio API compatibility guards should be searchable and intentional. `scripts/control/compat.lua` centralizes safe optional property reads, guarded single-call helpers, quality-name reads, entity inventory lookup, prototype-existence checks, and platform hub inventory lookup. It emits one-shot diagnostics for unexpected guarded failures only when the existing `/turret-xp-dev` controls are enabled for a player or when the private headless companion test mod is active, so normal play logs remain quiet.
- V0.10.x uses an invisible hidden feeder inventory entity colocated with the turret for passive Veteran Core element-rank material progress, with runtime routing that moves inserter-fed ammo back into the turret ammo inventory. Every selected element always exposes its next material rank requirement; nearby managed inserters that are actually sourcing needed materials are pointed at the hidden input and can receive multiple active element filters at once. Otherwise inserters are pointed back at the turret so ammo logistics remain normal. If a stale inserter hand or edge case still inserts an unsupported non-ammo item, routing ejects that invalid stack so element progress cannot be blocked by hidden junk. Hidden gun-turret body variants let specialization, sub-specialization, Range augment, and Max HP ranks change turret prototype stats, while the `item-with-tags` Veteran Core carries portable progression profiles. Those variants are generated in `data-final-fixes.lua` so they inherit final base turret prototype edits from mods such as Krastorio 2 Spaced Out. V0.10.3 also patches gun-turret accepted projectile ammo whose turret-source projectile range is lower than generated Turret XP ranges, preserving non-turret ammo behavior while preventing K2/K2SO-style realistic rifle ammo from under-reaching veteran sniper turrets. Resistance intentionally does not add another hidden variant axis; it uses `on_entity_damaged` to refund part of non-lethal final incoming damage after Factorio has applied vanilla resistances. Installed cores can opt into a bound quick-move item that is also `item-with-tags`; it places a hidden bound-only placeholder that build handling converts into a real gun turret, letting mining and placement carry the turret body snapshot plus core profile together without affecting normal gun-turret ghosts. Hidden bound item/placeholder preview variants are also generated in `data-final-fixes.lua` after turret variants, keyed by specialization, sub-specialization, and Range rank, because Factorio's native held-item range preview reads `place_result` prototypes rather than per-stack tags. Space-platform turrets use explicit Turret XP panel actions to install exact cores from the platform hub inventory and send installed cores back to that hub. Combat XP counters are weighted by surface and target type so asteroid defense on space platforms does not overlevel cores. The relative turret panel is split into bounded narrower left core/stat and right Evolution columns. The Evolution column follows the content-pane pattern: a static summary header outside a default scroll pane, with section and row widths derived from the right-column viewport rather than separately guessed constants. Level-ups emit a short local flying-text popup above the turret for connected same-force players when XP progression increases the installed core's level. Temporary electric beam visuals are created with an engine duration and tracked in `storage.turret_xp.visual_entities` for manual expiry if the beam entity outlives that duration. Fire and Toxic delayed damage use `storage.turret_xp.status_effects` so scripted damage-over-time ticks still award XP, contribute kill credit, and trigger lifesteal.
- V0.4.4 caches derived level progress so normal combat applies XP deltas instead of recalculating level progress from scratch on every damage event.
- V0.4.5 uses local tag-preserving Veteran Core slot transfer logic. `entity-gui-lib` inventory display was inspected, but its current transfer helper copies name/count/quality and would not preserve Veteran Core item tags.
- Python packaging script reused from `player_quality`.
- Shell scripts for checks, packaging, local install, GitHub release, and Mod Portal publishing.
- Lua formatting uses StyLua 2.5.2 with Lua 5.2 syntax and two-space indentation. Lua linting uses Luacheck 1.1.2 through Ubuntu's `lua-check` package. `scripts/check.sh` remains portable and skips unavailable host tools; `scripts/lint-lua.sh` becomes strict when `REQUIRE_LUA_TOOLS=1`, and `docker compose run --rm lua-tools` provides the same strict path locally without installing tools on the host. Luacheck suppresses global-family warnings only for the legacy `_ENV` runtime modules listed in `.luacheckrc`, where the current shared runtime module pattern intentionally exports and consumes globals until more helpers migrate to explicit returned-table modules.
- `scripts/download-mod-dependencies.py` downloads required Mod Portal dependency zips for isolated CI/headless test directories using `FACTORIO_SERVICE_USERNAME` and `FACTORIO_SERVICE_TOKEN`.
- `scripts/test-headless.sh` runs a temporary Factorio test mod against the packaged Turret XP zip before portal publishing. That companion mod activates the gated `turret_xp_test` remote interface; a separate smoke-test mod verifies production runs without the companion mod do not register that interface. Passing runs print the tracked hidden prototype budget so prototype-axis growth is visible in normal validation output.
- GitHub Actions runs strict Lua syntax/format/lint checks and package validation for pull requests and `main`; when Mod Portal download secrets are configured, it also downloads the official Factorio headless Linux build and runs the headless regression suite. Pull request CI uses `scripts/ci-change-scope.sh` so docs-only changes keep required checks green without running package/headless work, while runtime/tooling/workflow changes run the full path. Pushes to `main` and manual runs always run full validation. The workflows pin `STYLUA_VERSION`, `STYLUA_SHA256`, and `FACTORIO_HEADLESS_VERSION`; they cache the extracted Factorio directory plus dependency zips so repeated CI runs avoid redundant downloads without storing credentials. The release workflow is triggered by a GitHub Release/tag, validates the tag against `info.json`, attaches the built package to the GitHub Release, and publishes to the Factorio Mod Portal behind the `factorio-mod-portal` environment gate.
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
- Before redesigning the Veteran Core slot or replacing the turret panel with a full custom GUI, inspect source from large/popular GUI-heavy mods such as Factory Planner and any maintained inventory-slot/entity-GUI libraries. Reuse their proven patterns or dependencies when they solve tag-preserving slot transfer, player-inventory integration, or vanilla-like GUI ownership better than local code.

## Libraries

`flib` is a dependency as of V0.2.0. Revisit the other libraries when a feature needs enough shared machinery to justify adding another dependency.

### Current Dependencies

- `flib` / Factorio Library:
  - Factorio 2.0 compatible internal library mod.
  - Large adoption signal on the Mod Portal, with over 1M downloads and hundreds of dependent mods.
  - V0.4.x uses `flib` GUI styles for slot buttons, pushers, and compact panel structure.
  - Useful future modules for this project may include `gui`, `migration`, `dictionary`, `on-tick-n`, `queue`, `format`, `table`, and position/geometry helpers.
- Optional `bullet-trails`:
  - Version 0.7.1 was downloaded and verified against the Mod Portal release hash before being considered.
  - Source inspection shows data-stage hidden `explosion` prototypes such as `bullet-beam-yellow`, `bullet-beam-cyan`, and `bullet-beam-orange`, plus ammo prototype patching through `target_effects`.
  - It does not expose a runtime remote interface. Turret XP treats its trail prototypes as optional visual entities and falls back to local render lines when the mod is absent.
  - Use it for scripted bounce, double-shot, and element tracer readability only; do not make combat logic depend on it.
- Reference only: `inventory-selector`:
  - Source inspection shows the robust Factorio 2.0 pattern for inserter ambiguity is to manage `LuaEntity.drop_target` through hidden proxy/container targets instead of relying on overlapping entities being chosen correctly.
  - Turret XP does not depend on it for V0.9.x because the needed behavior is narrower: temporarily point nearby material inserters at the hidden feeder, prioritize the current material request, and restore them to the turret when element input is not needed.

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
  - Do not add it merely for the current two-column Evolution UI; `flib` plus local frame/table composition covers the current attached-panel flow without a lifecycle rewrite.
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
- `AmmoType::source_type` allows data-stage ammo behavior to differ for `"turret"` versus default/player/vehicle use. V0.10.3 uses this to raise projectile `max_range` only for turret-fired gun-turret ammo when another mod's ammo cap is lower than Turret XP's generated turret range.
- `ProjectileTriggerDelivery::max_range` limits how far a physical projectile delivery can travel independently from the firing turret's `attack_parameters.range`. K2/K2SO realistic rifle ammo uses this field, so raising only turret range can otherwise create unreachable targets.
- Factorio 2.0 removed the old `flying-text` entity type. In-world popup text should use `LuaPlayer::create_local_flying_text` for each connected player that should see the notification.
- `LuaEntity::quality`, `sprite-button` quality overlays, and `elem_tooltip` with `entity-with-quality` allow the panel's turret icon to use vanilla quality tooltip behavior.
- `LuaGuiElement::quality` is only a sprite-button overlay; it is not the same thing as the vanilla blue stat marker plus built-in quality delta popover shown in native entity/tooltips.
- `LuaGuiElement` supports slot-like `sprite-button` controls with quality overlays and item tooltips, but the runtime API does not expose an arbitrary native inventory-slot widget that can be inserted into the vanilla turret GUI. Veteran Core slot work must therefore be scripted and tag-preserving, or be handled by a separate full custom GUI design.
- `Prototype::custom_tooltip_fields` can add quality-aware values to native tooltips and Factoriopedia during the data stage, but it does not provide a direct runtime GUI element for arbitrary custom stat rows.
- Tagged `item-with-tags` stacks can receive runtime `custom_description` values, and Turret XP uses that for Veteran Core and bound turret item build summaries. Placed `LuaEntity` hover tooltips do not expose an equivalent runtime per-entity custom description, and `custom_tooltip_fields` is static prototype data, so the live per-core build summary belongs in the attached panel rather than the native placed-entity tooltip.
- Runtime custom GUI cannot instantiate the native Factoriopedia quality popover as a widget. The panel uses the real `[img=quality_info]` marker with a custom tooltip summary generated from Factorio quality prototypes for HP and range, filtering hidden fallback qualities.
- Runtime custom GUI also cannot instantiate the engine's internal technology-tree canvas as a reusable widget. V0.4.0 removes the experimental tree and uses a simple list while gameplay direction is tested.
- The local Factorio install exposes data/prototype/style Lua, but not the engine source for the research-tree canvas. Research-tree click-drag panning appears to be engine GUI behavior rather than reusable mod Lua.
- V0.3.2 attempted an embedded drag-pan spike. Playtesting showed no useful drag behavior in the relative turret GUI, so V0.4.0 removes the spike instead of keeping a misleading interaction.
- `LuaForce::get_gun_speed_modifier` exposes force shooting-speed research bonuses by ammo category.
- `LuaForce::get_ammo_damage_modifier` exposes force ammo-damage research bonuses by ammo category.
- `LuaForce::get_turret_attack_modifier` exposes turret-specific force damage bonuses; gun turret damage display needs this in addition to ammo damage.
- `LuaForce::set_turret_attack_modifier` can synchronize hidden turret variants with the vanilla gun-turret damage research modifier at runtime. V0.7.0 uses this instead of copying every `turret-attack` technology effect onto every hidden variant.
- `LuaEntityPrototype::attack_parameters`, `AttackParameters::range`, and `LuaEntityPrototype::turret_range` are runtime read-only. Real per-entity range, cooldown, damage modifier, health, and rotation-speed changes still require data-stage prototype variants unless the mod replaces the vanilla turret attack loop with scripted targeting.
- `LuaItemPrototype::ammo_category` and `AttackParameters::ammo_categories` are the correct bonus category sources for loaded ammo and fallback turret attack parameters.
- `ItemWithTagsPrototype` and `ItemStackDefinition.tags` support storing a core profile directly on a non-stackable item when it is extracted from a turret.
- `ItemWithTagsPrototype` inherits normal item placement fields, including `place_result`, but a tagged bound veteran turret item must not place vanilla `gun-turret` directly. If it does, vanilla gun-turret ghosts can display or request the bound item as an equivalent replacement. V0.9.2 uses a hidden bound-only placeholder turret as the bound item's `place_result`, then converts that placeholder into a real vanilla gun turret during build handling while installing the stored core profile.
- `LuaItemStack::get_tag` and `LuaItemStack::set_tag` expose runtime tag access for tagged item stacks.
- Build events expose enough item context to restore bound turret tags: `on_built_entity` can provide `consumed_items`, and robot/platform build events can provide the source stack. The mod checks both paths.
- `mod-openable`/`on_mod_item_opened` is not used for unbinding a specific bound item in inventory because the event gives item-with-quality counts rather than a real tagged `LuaItemStack`.
- `LuaRendering::draw_text` supports entity targets with offsets, which remains a fallback for optional `name (lvl N)` turret labels if no hidden display-panel prototype exists.
- `LuaDisplayPanelControlBehavior` messages expose text, icon, and condition at runtime, but not arbitrary runtime text color. Custom RGB turret labels therefore use generated hidden display-panel prototype variants with quantized text colors so they keep the display-panel background and sizing.
- Runtime GUI rows are not inserter-targetable inventories. The current implementation uses a real hidden chest-like feeder entity on the turret tile so selected element rank materials can be fed like machine inventory without showing a fake chest. Because overlapping inserter targets are ambiguous, V0.10.x manages nearby inserter `drop_target` values and temporary filters while element material is actually needed. The feeder can expose multiple active element resources in filter slots, still routes ammo stacks into the turret ammo inventory if ammo lands in the hidden input, and uses a bounded custom inventory with a bar so material progress can buffer normal inserter throughput between routing ticks.
- `LuaSurface::platform` exposes the platform for platform surfaces, `LuaSpacePlatform::hub` exposes the hub entity, and `defines.inventory.hub_main` is the hub inventory used for explicit platform Veteran Core selection. This keeps core choice deterministic when multiple tagged cores are present.
- The same `LuaSurface::platform` check is used for the space-combat XP multiplier. Raw `damage` and `kill_credit` stay display/credit totals, while `xp_damage` and `xp_kill_credit` are the counters used by progression math. V0.7.0 also stores target context for recent damage contribution so asteroid, unit, worm, spawner, and miscellaneous enemy targets can receive different XP weights.
- `on_space_platform_mined_entity` is registered only when the runtime exposes it, and is used as a best-effort return path for installed cores mined on platforms.
- The V0.9.x Evolution UI is a bounded right-side content pane with fixed top-level dimensions, a static header, and one default scroll pane for section bodies. `LuaGuiElement::scroll_to_element` remains guarded to preserve context after allocation. Allocation refreshes and body swaps must keep the whole vanilla turret GUI from moving by avoiding top-level size churn and deferring prototype swaps.
- Factorio content panes should avoid wrapping a scroll pane in an additional padded frame when the scrollbar needs to align cleanly. The GUI style guide recommends `inside_shallow_frame_with_padding` for normal content panes, but using `inside_shallow_frame` when placing a scroll pane or toolbar directly. V0.9.3 applies that pattern to the Evolution column. Source notes: <https://github-wiki-see.page/m/raiguard/Factorio-SmallMods/wiki/GUI-Style-Guide> and <https://forums.factorio.com/viewtopic.php?t=132903>.
- The headless test mod intentionally patches vanilla gun turret range during `data-updates.lua`, then asserts Turret XP's `data-final-fixes.lua` variants inherit that range. It also gives firearm magazines a K2-style projectile `max_range` of 30 and asserts the turret-source ammo type is raised high enough for the generated Turret XP range while the non-turret ammo type keeps the original cap.
- `LuaSurface::create_entity` can spawn vanilla electric beams, fire flashes, poison smoke visuals, slowdown stickers, explosions, and Bullet Trails hidden trail entities for short-lived visual feedback. These are used as cosmetic feedback around runtime-applied damage and are guarded by prototype-existence checks. Turret XP avoids spawning the vanilla `poison-cloud` damage entity directly because its damage would bypass Turret XP XP/lifesteal accounting; Toxic uses scripted poison damage plus a short custom visual puff instead.

## Risks

- Damage estimation only covers direct damage effects in ammo prototype data. More complex projectile or nested modded ammo may show `Unknown`.
- Contribution-based kill credit is based on recent tracked target damage and prunes stale target entries after five minutes.
- Per-entity combat stat mutation is not designed yet. Factorio exposes force-wide modifiers more readily than individual turret attack modifiers.
- V0.4.1 implements mined turret persistence through the Veteran Core item. Destroyed turret recovery remains an open design question.
- Evolution points are derived from core profile level and stored under `state.evolution`.
- Runtime GUI cannot add a true extra slot inside the vanilla turret inventory, so Veteran Core install/extract uses explicit controls in the attached Turret XP panel.
- V0.10.x specialization, sub-specialization, Range augment, and Max HP stats are prototype-backed, but variants are generated after other mods' data updates and research damage bonuses are runtime-synced so hidden variants do not clutter technology effects. The current measured tracked hidden prototype budget is 6,498 generated prototypes: 5,732 hidden turret bodies, 272 bound preview items, 272 bound preview placeholders, and 222 label display panels. Max HP is capped because true per-entity max health is not runtime-writable; making it infinite would require unbounded hidden prototypes or a separate damage-buffer mechanic. Any added prototype-backed axis or cap increase should be treated as a design decision with budget data, not as a routine implementation detail. Resistance is scripted rather than prototype-backed, so it is per-core without variant growth but only mitigates non-lethal hits after the engine has resolved damage. Ammo Recovery regenerates discrete ammo items because Factorio ammo does not expose per-round durability to refill. Open-GUI body swaps are deferred until the turret GUI closes to avoid resetting the vanilla window location. Feeder placement is an invisible colocated input with ammo forwarding, active-project material request priority, and managed inserter targeting/filtering. Bound turret mining relies on pre-mine plus mined-entity event pairing to replace vanilla outputs with one tagged item. Edge cases around full turret ammo inventories, unsupported ammo, mixed-material belts, unusual inserter layouts, platform hub inventory fullness, platform mining buffers, asteroid XP pacing, bound turret mining buffers, optional VFX density, and the scripted Veteran Core slot UX still need playtesting.
- Core upgrades, augments, elements, combos, passive repair, and vampiric healing still need playtest balance and clearer feedback.
- The panel updates named elements in place every 60 ticks; new GUI work should preserve stable hover/read behavior.
- `flib` adds a dependency, but it is common and handled by the in-game dependency manager.
- `entity-gui-lib` is promising for full GUI replacement, but it would be a larger dependency and ownership shift than the current relative-panel polish needs.
- `entity-gui-lib` may still be useful for non-profile inventories or a full GUI replacement, but do not use its current inventory transfer helper for `item-with-tags` Veteran Cores unless tag preservation is added or wrapped.
- `quality-lib` may be valuable once Turret XP owns quality-scaled custom stats, but adding it should be an intentional dependency decision because it changes prototype/data-stage behavior.
- The website can become stale if it stays hand-maintained; keep generation from mod metadata/docs on the roadmap before the site grows.

## Validation Path

- Run `scripts/check.sh`; it skips Lua tools that are not installed on the host.
- Run `docker compose run --rm lua-tools` for strict local Lua syntax, StyLua, and Luacheck validation without mutating the host.
- Run `scripts/package.sh`.
- Run `scripts/test-headless.sh`. It packages the current mod, assembles an isolated mod directory with flib and `tests/headless/turret_xp_headless_tests`, creates a save, benchmark-runs it for deterministic ticks, and fails if the test mod does not log `PASS`. It then runs `tests/headless/turret_xp_remote_policy_tests` separately to verify the private `turret_xp_test` remote interface is absent without the companion suite.
- In GitHub Actions, CI runs package validation on pull requests and `main`. The headless job runs when `FACTORIO_SERVICE_USERNAME` and `FACTORIO_SERVICE_TOKEN` secrets are available; release publishing requires those download credentials plus `FACTORIO_MOD_PORTAL_API_KEY`.
- Inspect the zip layout.
- If a local Factorio binary is available, run a headless load smoke test.
- `scripts/publish-portal.sh` runs the headless suite before uploading unless `SKIP_HEADLESS_TESTS=1` is set for a machine that cannot run Factorio locally.
- Confirm the GitHub Pages homepage still matches the current release and documentation.
- Publish the current version, install from the in-game Mods interface, and manually test opening a turret plus turret combat.
