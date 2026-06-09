# Architecture

## Repository Layout

- `info.json`: Factorio mod metadata.
- `control.lua`: runtime entrypoint that loads modules from `scripts/control/`.
- `scripts/control/`: runtime modules for storage, profiles, progression, feeder logistics, stats, GUI, core-slot actions, combat effects, events, commands, and headless-test remotes.
- `data.lua`: data-stage entrypoint that loads prototype modules from `prototypes/`.
- `data-final-fixes.lua`: final-fixes entrypoint that loads hidden turret variant generation from `prototypes/`.
- `prototypes/`: data-stage modules for names, items, bound-turret placeholder and preview variants, feeder, label panels, styles, effects, and turret variants.
- `settings.lua`: runtime-global XP pacing settings.
- `locale/en/turret-xp.cfg`: English GUI strings.
- `scripts/`: validation, packaging, install, release, and portal publishing.
- `tests/headless/turret_xp_headless_tests/`: temporary Factorio test mod used by `scripts/test-headless.sh`.
- `docs/`: project context, playtest guidance, and the GitHub Pages homepage.

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
- Bound turret quick move: `on_pre_player_mined_item` and `on_robot_pre_mined` snapshot bound turret profile, health ratio, quality, and ammo before vanilla mining removes the entity, but keep the live profile attached until final conversion. `on_player_mined_entity` and `on_robot_mined_entity` then detach the profile, remove vanilla gun turret/ammo outputs from the mining buffer, and insert or spill one tagged bound veteran turret item. The bound item places a hidden bound-only placeholder entity, so normal `gun-turret` ghosts cannot request it. Newly created bound stacks use hidden item/placeholder preview variants keyed by specialization, sub-specialization, and Range rank so Factorio's native cursor range preview matches the restored turret range where possible. Build events read the item's tags, convert any bound placeholder variant into a real `gun-turret`, reconcile any placement-time ammo against the saved ammo snapshot, and reinstall the profile.
- Combat XP pacing: raw `damage` and `kill_credit` remain display totals, but XP counters are weighted by combat context. Space-platform surfaces apply a surface reduction, asteroids and asteroid chunks apply a target reduction, and larger enemies, worms, and spawners can pay more kill-credit XP than small enemies.
- Hidden turret variant sync: runtime sync copies the force's vanilla `gun-turret` attack modifier to hidden `turret-xp-gun-turret-*` variants on init, configuration change, force creation, and research completion. This keeps research bonuses correct without adding every hidden variant to technology effect lists.
- Open-GUI body swaps: specialization, sub-specialization, Range, Max HP, install, extract, and section resets can require swapping the underlying turret prototype. While the vanilla turret GUI is open, those swaps are queued on the profile or host and applied after close so the whole vanilla window does not jump back to its default position.
- Data-final variant generation: `data-final-fixes.lua` creates hidden specialization, sub-specialization, Range, and Max HP turret variants after every mod has run `data-updates.lua`. This keeps prototype-backed Turret XP variants aligned with modded base gun-turret range, cooldown, damage modifier, health, and rotation speed before Turret XP adds its own rank/specialization modifiers.
- Runtime visual feedback: scripted bounce, double-shot, crit, and element effects prefer optional Bullet Trails entity names when present, then fall back to render lines. Element procs reuse vanilla electric, fire, poison/slowdown, explosion, and weapon sound prototypes where practical. Delayed burn and poison ticks are processed from `status_effects` so they remain tied to the Veteran Core for XP, kill credit, and lifesteal.
- Runtime damage mitigation: Resistance is a core upgrade handled in `on_entity_damaged` by refunding part of non-lethal final incoming damage after vanilla resistances. It intentionally avoids adding another hidden turret variant dimension.
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
- `remote.interfaces.turret_xp_test`: controlled test-only API used by the headless test mod to install cores, inspect sanitized profile state, drive feeder state, reset individual evolution sections, and create tagged test stacks. Gameplay should not depend on this interface.

## Boundaries

- Runtime state remains under `storage.turret_xp`; modules must not create separate save roots for core gameplay state.
- `control.lua` should stay a small loader. New runtime work belongs in the owning module under `scripts/control/`, with shared constants in `config.lua`.
- `scripts/control/core_slot.lua` owns tag-preserving Veteran Core install/extract/swap, platform core selection, bind/unbind actions, and future inventory-list selection work.
- Data-stage entrypoints should stay minimal. New prototypes belong in `prototypes/`, and hidden turret body variants must stay generated from `data-final-fixes.lua` so they see other mods' final base prototype edits.
- Release scripts should stay data-driven from `info.json` where practical.
- The website should stay tightly coupled to mod metadata and docs. As it grows, prefer a small generator over manually maintaining duplicate homepage content.
