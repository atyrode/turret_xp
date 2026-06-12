# Architecture

## Repository Layout

- `.github/workflows/`: GitHub Actions CI and release automation.
- `info.json`: Factorio mod metadata.
- `changelog.txt`: canonical Factorio-compatible release history.
- `control.lua`: runtime entrypoint that loads modules from `scripts/control/`.
- `scripts/domain.lua`: pure shared gameplay domain definitions and variant-name helpers used by data stage, runtime, and headless tests.
- `scripts/control/`: runtime modules for storage, profiles, progression, feeder logistics, stats, GUI, core-slot actions, combat effects, events, commands, headless-test remotes, and explicit helper modules such as Factorio API compatibility, label-color matching, bound turret item handling, migration compatibility, damage accounting, combat effect budgets, generic GUI support, and reusable GUI components.
- `data.lua`: data-stage entrypoint that loads prototype modules from `prototypes/`.
- `data-final-fixes.lua`: final-fixes entrypoint that loads hidden turret variant generation from `prototypes/`.
- `prototypes/`: data-stage modules for names, items, bound-turret placeholder and preview variants, feeder, label panels, styles, effects, and turret variants.
- `migrations/`: Factorio one-time prototype migration files, currently used to collapse retired hidden Range/Max HP variants onto current prototypes.
- `settings.lua`: runtime-global XP pacing settings.
- `locale/en/turret-xp.cfg`: English GUI strings.
- `scripts/`: validation, public-asset generation, packaging, dependency download, install, release, and portal publishing.
- `.stylua.toml`, `.luacheckrc`, `compose.yaml`, and `tools/lua/Dockerfile`: Lua format/lint configuration and the optional local strict-tooling container.
- `tests/headless/turret_xp_headless_tests/`: temporary Factorio test mod used by `scripts/test-headless.sh`; `control.lua` owns runner lifecycle, `support.lua` owns shared assertions/helpers, and `suite.lua` owns behavior checks.
- `tests/headless/turret_xp_remote_policy_tests/`: separate headless smoke-test mod used by `scripts/test-headless.sh` to verify private test remotes are absent when the companion suite is not active.
- `docs/`: project context, playtest guidance, shared public copy, and the generated GitHub Pages homepage.

## Runtime State

```lua
storage.turret_xp = {
  turrets = {
    [unit_number] = {
      chip_id = <string>,
      entity = <LuaEntity>,
      body_sync_target = <entity_name>
    }
  },
  chips = {
    [chip_id] = {
      chip_id = <string>,
      chip_quality = "normal",
      custom_name = "",
      show_name_label = false,
      show_label_level = true,
      label_color = { 1, 0.86, 0.46 },
      label_color_preset = "gold"|"custom"|<preset_id>,
      bound_turret = false,
      xp = 0,
      total_xp = 0,
      level = 0,
      kills = 0,
      kill_credit = 0,
      damage = 0,
      xp_damage = 0,
      xp_kill_credit = 0,
      dev_xp = 0,
      shield = 0,
      evolution = {
        base = {
          [upgrade_id] = <rank>
        },
        augments = {
          [augment_id] = <rank>
        },
        elements = {
          [1] = <element_id>,
          [2] = <element_id>
        },
        element_mastery = {
          [element_id] = {
            rank = <uint>,
            delivered = <uint>
          }
        },
        specialization = <specialization_id>,
        sub_specialization = <sub_specialization_id>
      },
      entity = <LuaEntity>,
      name_render = <LuaRenderObject>,
      shield_bar = {
        health_background = <LuaRenderObject>,
        health_fill = <LuaRenderObject>,
        health_border = <LuaRenderObject>,
        shield_background = <LuaRenderObject>,
        shield_fill = <LuaRenderObject>,
        shield_border = <LuaRenderObject>
      },
      feeder = <LuaEntity>
      _body_sync_pending = <boolean>
    }
  },
  next_chip_id = 1,
  feeders = {
    [unit_number] = <chip_id>
  },
  pending_bound_mined = {
    [entity_tracking_key] = {
      profile = <serialized_core_profile>,
      turret = {
        quality = <quality_name>,
        health_ratio = <double>,
        ammo = {
          { name = <item_name>, count = <uint>, quality = <quality_name> }
        }
      },
      tick = <MapTick>
    }
  },
  pending_visuals = {
    {
      tick = <MapTick>,
      surface = <LuaSurface>,
      from = <MapPosition>,
      to = <MapPosition>,
      color = <Color>,
      width = <double>
      trail_name = <entity_name>,
      force = <force_name>
    }
  },
  status_effects = {
    {
      target = <LuaEntity>,
      turret = <LuaEntity>,
      chip_id = <uint>,
      damage_type = <string>,
      remaining = <double>,
      per_tick = <double>,
      next_tick = <MapTick>,
      expires = <MapTick>
    }
  },
  combat_effect_budget = {
    tick = <MapTick>,
    surfaces = {
      [surface_index] = {
        render_lines = <uint>,
        render_sprites = <uint>,
        visual_entities = <uint>,
        short_effects = <uint>,
        sounds = <uint>
      }
    },
    global = {
      status_effect_ticks = <uint>
    },
    skipped = {
      [budget_name] = <uint>
    }
  },
  targets = {
    [unit_number] = {
      total_damage = 0,
      target_context = {
        name = <entity_name>,
        type = <entity_type>,
        max_health = <double>,
        force_name = <force_name>
      },
      tick = <MapTick>,
      turrets = {
        [unit_number] = {
          damage = 0,
          entity = <LuaEntity>,
          chip_id = <string>
        }
      }
    }
  },
  players = {
    [player_index] = {
      entity = <LuaEntity>,
      unit_number = <uint>
    }
  },
  player_settings = {
    [player_index] = {
      dev_controls = <boolean>
    }
  }
}
```

## Runtime Responsibilities

- `on_entity_damaged`: track lifetime damage for gun turrets with installed Veteran Cores, add target- and surface-weighted damage into `xp_damage`, cache per-target damage contribution and target context, and apply runtime evolution damage effects.
- `on_entity_died`: award proportional kill credit to contributing core profiles, add target- and surface-weighted kill credit into `xp_kill_credit`, track visible kills including scripted element-damage kills, and delete installed core profiles when a turret dies.
- Feeder lifecycle: create a hidden Veteran Core feeder inventory colocated with installed-core turrets while selected elements need next-rank material, point/filter nearby material inserters toward it only while needed, expose currently needed element resources in available inserter filter slots, restore normal turret drop targets otherwise, forward ammo from that hidden inventory into the turret ammo inventory, consume materials into `element_mastery[element_id].delivered`, expose a bounded buffer for smooth inserter throughput, avoid redundant input-bar writes, stop spilling unexpected items during normal routing, and destroy/spill leftovers only when the core leaves the turret.
- Platform core transfer: when the opened turret is on a space platform, list Veteran Cores from the platform hub inventory for exact install selection and allow sending the installed core back to that hub.
- Bound turret quick move: `on_pre_player_mined_item` and `on_robot_pre_mined` snapshot bound turret profile, health ratio, quality, and ammo before vanilla mining removes the entity, then clear the live turret ammo inventory so vanilla cannot also return that same ammo separately. The live profile stays attached until final conversion. `on_player_mined_entity` and `on_robot_mined_entity` then detach the profile, remove vanilla gun turret/ammo outputs from the mining buffer, and insert or spill one tagged bound veteran turret item. The bound item places a hidden bound-only placeholder entity, so normal `gun-turret` ghosts cannot request it. Newly created bound stacks use hidden item/placeholder preview variants keyed by specialization and sub-specialization so Factorio's native cursor range preview matches the restored turret range where possible. Build events read the item's tags, convert any bound placeholder variant into a real `gun-turret`, refund placement-time ammo, restore the saved ammo snapshot, and reinstall the profile.
- Bound turret item ownership: `scripts/control/bound_turret_items.lua` owns tagged bound turret stack creation, decoding, inventory lookup from build events, vanilla mining-output cleanup, and insert-or-spill delivery. `profiles.lua` still owns profile schema/serialization and live turret snapshot/restore helpers; `events.lua` owns live mining/build event orchestration.
- Combat XP pacing: raw `damage` and `kill_credit` remain display totals, but XP counters are weighted by combat context. Space-platform surfaces apply a surface reduction, asteroids and asteroid chunks apply a target reduction, and larger enemies, worms, and spawners can pay more kill-credit XP than small enemies.
- Damage accounting ownership: `scripts/control/damage_accounting.lua` owns target damage buckets, contributor tracking, proportional kill-credit awards, visible-kill fallback selection, and stale target cleanup. `stats.lua` still owns stat display formatting and exposes compatibility wrappers for existing event handlers.
- Factorio API compatibility ownership: `scripts/control/compat.lua` owns safe optional API reads, guarded single-call helpers, quality-name reads, entity inventory lookup, prototype-existence checks, platform hub inventory lookup, and one-shot diagnostics for unexpected failures. Runtime modules should use it for known optional API paths instead of adding anonymous `pcall` wrappers.
- Hidden turret variant sync: runtime sync copies the force's vanilla `gun-turret` attack modifier to hidden `turret-xp-gun-turret-*` variants on init, configuration change, force creation, and research completion. This keeps research bonuses correct without adding every hidden variant to technology effect lists.
- Shield/HP status rendering: `profiles.lua` owns a small two-row `LuaRendering::draw_rectangle` status stack attached to the turret entity. The stack is runtime-only, follows body swaps through profile cleanup/recreation, shows HP above Shield with equal row widths when the shield is depleted, recharging, or the turret GUI is open, and is destroyed with the profile.
- Open-GUI body swaps: specialization, sub-specialization, install, extract, and section resets can require swapping the underlying turret prototype. While the vanilla turret GUI is open, those swaps are queued on the profile or host and applied after close so the whole vanilla window does not jump back to its default position.
- GUI support ownership: `scripts/control/gui_support.lua` owns generic GUI rich-text formatting and repeated Evolution width helpers. `scripts/control/gui_components.lua` owns reusable panel primitives such as stat rows, stat tables, Evolution section shells, summary labels, delimiters, and generic choice rows. `gui_panels.lua` still owns domain-specific panel composition, wording decisions, action tags, and refresh behavior.
- Migration compatibility ownership: `scripts/control/migrations.lua` owns published old-save/profile shape upgrades such as legacy element slot encodings, active element projects, retired element fuel buffers, retired augment IDs, and old skill-tree ranks. Normal progression code should express current passive element state, not carry old project UI or dead action paths.
- Data-final variant generation: `data-final-fixes.lua` creates hidden specialization and sub-specialization turret variants after every mod has run `data-updates.lua`. This keeps prototype-backed Turret XP variants aligned with modded base gun-turret range, cooldown, damage modifier, health, and rotation speed before Turret XP adds its own role modifiers.
- Hidden prototype budget: the headless suite measures the current tracked generated budget as 258 prototypes: 12 hidden turret bodies, 12 bound preview items, 12 bound preview placeholders, and 222 label display panels. The `migrations/turret_xp_0.10.4.json` prototype migration collapses old Range/Max HP body variants and old range-preview bound variants onto the new specialization-only prototypes. New prototype-backed stat axes, higher caps, or broader label color grids must update the budget assertion and explain the added load/startup cost in the owning issue or PR before they are accepted.
- Ammo range compatibility: after turret variants exist, `prototypes/ammo_range_compat.lua` scans ammo categories accepted by vanilla `gun-turret`. If projectile ammo in those categories has a shorter delivery range than the generated Turret XP turret range, it adds or patches a `source_type = "turret"` ammo type with a longer projectile `max_range`, leaving default/player/vehicle ammo behavior intact.
- Combat effect ownership: `scripts/control/combat_effects.lua` owns combat effect descriptors, proc routing, runtime damage application, VFX/sound calls, passive combat effects, and delayed status damage processing. `scripts/control/combat_budget.lua` owns per-tick visual/sound/status-work budget accounting. Combat damage and progression effects must keep running even when visual or sound feedback is skipped by budget limits.
- Runtime visual feedback: scripted bounce, double-shot, crit, and element effects prefer optional Bullet Trails entity names when present, then fall back to render lines. Element procs reuse vanilla electric, fire, poison/slowdown, explosion, and weapon sound prototypes where practical. Visual entities, render lines, render sprites, short effects, sounds, pending visuals, and status-effect processing are explicitly budgeted so busy defenses remain readable and bounded. Delayed burn and poison ticks are processed from `status_effects` so they remain tied to the Veteran Core for XP, kill credit, and lifesteal.
- Runtime damage mitigation: Shield and Resistance are core upgrades handled in `on_entity_damaged`. Shield restores absorbed non-lethal damage before it reaches HP and tracks a rechargeable per-core buffer; Resistance then refunds part of the remaining non-lethal final incoming damage after vanilla resistances. Both intentionally avoid adding hidden turret variant dimensions.
- `on_runtime_mod_setting_changed`: resync derived XP/level state and refresh open panels.
- `on_built_entity`, `on_robot_built_entity`, and `on_space_platform_built_entity`, when available: restore bound veteran turret profiles from tagged placeable turret items after converting the bound-only placeholder into a real gun turret.
- `on_pre_player_mined_item` and `on_robot_pre_mined`: detach and return/spill installed Veteran Cores for mined unbound gun turrets, or snapshot bound turrets for mining-buffer replacement while leaving the bound profile attached until conversion.
- `on_player_mined_entity`, `on_robot_mined_entity`, and `on_space_platform_mined_entity`, when available: complete bound turret mining-buffer replacement or return/spill installed Veteran Cores for platform-mined unbound gun turrets.
- `on_gui_opened`: attach the Turret XP panel to the opened vanilla gun turret GUI. The attached panel is a fixed-width two-column layout: core, XP, dev controls, and scrollable stats on the left; a shallow Evolution content pane with a static summary header and one bounded scrollable section body on the right.
- `on_gui_closed`: remove the panel.
- `on_nth_tick(60)`: refresh open panels while the vanilla GUI remains open.
- Hidden display-panel label entities: draw optional chip-carried labels above currently installed turret bodies as `name (lvl N)`. Preset colors and RGB slider colors use hidden display-panel variants; custom RGB is quantized to the nearest generated prototype color because display-panel text color is prototype-defined.
- `/turret-xp`: fallback command for opening the selected turret's GUI/panel.
- `/turret-xp-dev`: per-player toggle for dev controls in the attached panel.
- `remote.interfaces.turret_xp_test`: controlled test-only API used by the headless test mod to install cores, inspect sanitized profile state, drive feeder state, reset individual evolution sections, and create tagged test stacks. `control.lua` registers this interface only when `script.active_mods["turret_xp_headless_tests"]` is present, so gameplay and other mods must not depend on it.

## Invisible Feeder Contract

The invisible feeder is the accepted material-input architecture for the current line. It is intentionally narrow:

- A feeder may exist only for an installed Veteran Core whose selected active elements have a remaining next-rank material requirement.
- The feeder is colocated with the turret, is not player-facing, is not a general storage chest, and should not become a second inventory surface for unrelated behavior.
- The feeder may hold selected element materials long enough for bounded inserter throughput between routing ticks.
- Inserter-fed ammo that lands in the feeder is forwarded into the turret ammo inventory.
- Unsupported non-ammo items that reach the feeder are ejected so hidden junk cannot block future material progress.
- When no selected element needs material, the feeder input is closed and the feeder is destroyed once no contents remain.
- Removing, mining, or resetting the installed core destroys the feeder and spills owned leftover contents according to the calling flow.
- `storage.turret_xp.feeders` must map live feeder unit numbers to the owning core only while the feeder is valid.

Managed inserters are also intentionally narrow:

- Only nearby same-force inserters that already target the turret/feeder tile are eligible.
- An inserter is temporarily managed only while the turret needs material and the inserter either has an allowed material at its pickup source, already has an allowed filter, or is already managed from an earlier active routing pass.
- Temporary filters should prioritize allowed materials actually present at that inserter's pickup source, then fall back to the turret-wide material priority.
- Original inserter filters must be restored and the inserter must be pointed back at the turret when material input is no longer needed.
- Managed inserter tracking must be scoped to the owning turret/feeder and stale or invalid managed entries must be restored or forgotten during feeder update and teardown paths.
- Headless tests must cover lifecycle, ownership cleanup, source-aware filter priority, no-source non-management, filter restoration, ammo forwarding, wrong-item cleanup, mixed-element requests, and passive material progress before feeder behavior is expanded.

## Boundaries

- Runtime state remains under `storage.turret_xp`; modules must not create separate save roots for core gameplay state.
- `control.lua` should stay a small loader. New runtime work belongs in the owning module under `scripts/control/`. Stable gameplay IDs, progression caps, specialization definitions, label presets, and generated variant names belong in `scripts/domain.lua`; runtime-only GUI layout and event behavior stay in runtime modules.
- Save/profile compatibility for Mod Portal-published versions belongs in named migration helpers or Factorio `migrations/` files when appropriate. Tagged Veteran Core and bound turret items still require runtime normalization because old profile shapes can live in item tags outside live `storage`.
- New pure helper groups should prefer explicit returned-table modules required directly by their callers. Existing `_ENV`/`M` exports can remain during incremental migration, but new helpers should not add hidden dependencies to the shared runtime environment unless they are part of a deliberately broad subsystem boundary.
- Bound turret item/tag behavior belongs in `scripts/control/bound_turret_items.lua`; live profile installation, detachment, and entity replacement should call that module rather than duplicating tag or mining-buffer logic.
- Combat accounting behavior belongs in `scripts/control/damage_accounting.lua`; stat display, formula formatting, and GUI captions should not mutate target damage buckets or kill-credit counters.
- Combat effect refactors should be behavior-preserving unless a separate balance issue approves gameplay changes. New combat effects should add or extend descriptors and use the shared budget helper for visual, sound, pending-visual, and status-work paths.
- Optional or version-sensitive Factorio API access belongs in `scripts/control/compat.lua` when it fits the existing helper shapes. Keep local guards only for deliberate fallback probes such as trying a quality-aware entity creation and then retrying without quality.
- Generic GUI formatting and repeated width helpers belong in `scripts/control/gui_support.lua`; reusable GUI primitives belong in `scripts/control/gui_components.lua`; domain-specific panel sections should stay in `gui_panels.lua` unless they become repeated components with clear ownership.
- `scripts/control/core_slot.lua` owns tag-preserving Veteran Core install/extract/swap, platform core selection, bind/unbind actions, and future inventory-list selection work.
- Data-stage entrypoints should stay minimal. New prototypes belong in `prototypes/`, should reuse `scripts/domain.lua` for shared IDs/names, and hidden turret body variants must stay generated from `data-final-fixes.lua` so they see other mods' final base prototype edits.
- Release scripts should stay data-driven from `info.json`, `changelog.txt`, and `docs/public-copy.json` where practical.
- CI and release workflows should reuse the same scripts as local operators where practical, so GitHub package/release behavior does not drift from local validation.
- `scripts/download-mod-dependencies.py` owns authenticated Mod Portal dependency downloads for CI/headless tests. It must read credentials from environment variables and must not print token-bearing URLs.
- The headless test companion mod may exercise private internals through `turret_xp_test`, but those hooks must stay gated to the companion mod and must not be documented or stabilized as third-party integration surface.
- `scripts/generate-public-assets.py` owns generated public assets. Edit `docs/public-copy.json`, `info.json`, or `changelog.txt`, then regenerate `docs/index.html` instead of hand-editing duplicated homepage, release-note, or portal-copy text.
