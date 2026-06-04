# Architecture

## Repository Layout

- `info.json`: Factorio mod metadata.
- `control.lua`: runtime XP tracking, GUI handling, and command fallback.
- `data.lua`: currently runtime-only placeholder.
- `settings.lua`: runtime-global XP pacing settings.
- `locale/en/turret-xp.cfg`: English GUI strings.
- `scripts/`: validation, packaging, install, release, and portal publishing.
- `docs/`: project context, playtest guidance, and the GitHub Pages homepage.

## Runtime State

```lua
storage.turret_xp = {
  turrets = {
    [unit_number] = {
      xp = 0,
      total_xp = 0,
      level = 1,
      kills = 0,
      kill_credit = 0,
      damage = 0
    }
  },
  targets = {
    [unit_number] = {
      total_damage = 0,
      tick = <MapTick>,
      turrets = {
        [unit_number] = {
          damage = 0,
          entity = <LuaEntity>
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

- `on_entity_damaged`: track lifetime damage for vanilla gun turrets and cache per-target damage contribution.
- `on_entity_died`: award proportional kill credit to contributing gun turrets, track kills, and clean up turret state when a turret dies.
- `on_runtime_mod_setting_changed`: resync derived XP/level state and refresh open panels.
- `on_pre_player_mined_item` and `on_robot_pre_mined`: remove tracked state for mined gun turrets.
- `on_gui_opened`: attach the Turret XP panel to the opened vanilla gun turret GUI.
- `on_gui_closed`: remove the panel.
- `on_nth_tick(60)`: refresh open panels while the vanilla GUI remains open.
- `/turret-xp`: fallback command for opening the selected turret's GUI/panel.

## Boundaries

- `control.lua` owns runtime state and GUI.
- Data-stage files should stay minimal until the mod needs new prototypes, sprites, or shortcuts.
- Release scripts should stay data-driven from `info.json` where practical.
- The website should stay tightly coupled to mod metadata and docs. As it grows, prefer a small generator over manually maintaining duplicate homepage content.
