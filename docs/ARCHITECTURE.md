# Architecture

## Repository Layout

- `info.json`: Factorio mod metadata.
- `control.lua`: runtime XP tracking, GUI handling, and command fallback.
- `data.lua`: currently runtime-only placeholder.
- `settings.lua`: currently no settings.
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
      damage = 0
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

- `on_entity_damaged`: award damage XP and track lifetime damage when a vanilla gun turret is the cause.
- `on_entity_died`: award kill XP when a vanilla gun turret is the cause and clean up turret state when a turret dies.
- `on_pre_player_mined_item` and `on_robot_pre_mined`: remove tracked state for mined gun turrets.
- `on_gui_opened`: attach the Turret XP panel to the opened vanilla gun turret GUI.
- `on_gui_closed`: remove the panel.
- `on_nth_tick(60)`: refresh open panels while the vanilla GUI remains open.
- `/turret-xp`: fallback command for opening the selected turret's GUI/panel.

## Boundaries

- `control.lua` owns runtime state and GUI.
- Data-stage files should stay minimal until the mod needs new prototypes, settings, sprites, or shortcuts.
- Release scripts should stay data-driven from `info.json` where practical.
- The website should stay tightly coupled to mod metadata and docs. As it grows, prefer a small generator over manually maintaining duplicate homepage content.
