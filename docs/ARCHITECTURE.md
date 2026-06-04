# Architecture

## Repository Layout

- `info.json`: Factorio mod metadata.
- `control.lua`: runtime XP/core tracking, GUI handling, floating labels, and command fallback.
- `data.lua`: data-stage Veteran Core item/recipe definitions and GUI style definitions.
- `settings.lua`: runtime-global XP pacing settings.
- `locale/en/turret-xp.cfg`: English GUI strings.
- `scripts/`: validation, packaging, install, release, and portal publishing.
- `docs/`: project context, playtest guidance, and the GitHub Pages homepage.

## Runtime State

```lua
storage.turret_xp = {
  turrets = {
    [unit_number] = {
      chip_id = <string>,
      entity = <LuaEntity>
    }
  },
  chips = {
    [chip_id] = {
      chip_id = <string>,
      chip_quality = "normal",
      custom_name = "",
      show_name_label = false,
      xp = 0,
      total_xp = 0,
      level = 1,
      kills = 0,
      kill_credit = 0,
      damage = 0,
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
        specialization = <specialization_id>,
        element_project = {
          slot = 1|2,
          element = <element_id>,
          requirements = {
            { name = <item_name>, count = <uint> }
          },
          delivered = {
            [item_name] = <uint>
          }
        }
      },
      entity = <LuaEntity>,
      name_render = <LuaRenderObject>
    }
  },
  next_chip_id = 1,
  targets = {
    [unit_number] = {
      total_damage = 0,
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
  }
}
```

## Runtime Responsibilities

- `on_entity_damaged`: track lifetime damage for gun turrets with installed Veteran Cores, cache per-target damage contribution, and apply runtime evolution damage effects.
- `on_entity_died`: award proportional kill credit to contributing core profiles, track kills, and delete installed core profiles when a turret dies.
- `on_runtime_mod_setting_changed`: resync derived XP/level state and refresh open panels.
- `on_pre_player_mined_item` and `on_robot_pre_mined`: detach and return/spill installed Veteran Cores for mined gun turrets.
- `on_gui_opened`: attach the Turret XP panel to the opened vanilla gun turret GUI.
- `on_gui_closed`: remove the panel.
- `on_nth_tick(60)`: refresh open panels while the vanilla GUI remains open.
- `rendering.draw_text`: draw optional chip-carried labels above currently installed turret bodies as `name (lvl N)`.
- `/turret-xp`: fallback command for opening the selected turret's GUI/panel.

## Boundaries

- `control.lua` owns runtime state and GUI.
- Data-stage files should stay minimal and only define styles/prototypes needed by the runtime GUI.
- Release scripts should stay data-driven from `info.json` where practical.
- The website should stay tightly coupled to mod metadata and docs. As it grows, prefer a small generator over manually maintaining duplicate homepage content.
