# Project Brief

`turret_xp` is a Factorio 2.0 mod that adds progression to vanilla gun turrets.

The first playable releases should make progression visible and testable: selected gun turrets earn XP from combat through installed Veteran Cores, gain levels, display current progress and combat stats inside or alongside the vanilla turret GUI, and evolve through simple point and material choices.

## V0.4.0 Scope

- Track XP, level, kills, kill credit, lifetime damage, total XP, and evolution choices per vanilla `gun-turret`.
- Award XP from damage dealt by gun turrets and proportional kill credit.
- Provide runtime-global settings for XP per damage, XP per kill credit, base level XP, and level XP growth.
- Extend the vanilla gun turret GUI with a Turret XP panel.
- Show HP, shooting speed, range, loaded ammo, estimated ammo damage, estimated DPS, kills, damage, current level, and XP to next level.
- Use Factorio Library (`flib`) GUI styles and follow Factory Planner-style rich text info markers where appropriate.
- Replace the experimental skill tree with a five-section Evolution list.
- Let core upgrades be allocated infinitely for one point per rank.
- Unlock the first element at level 10 through a material project.
- Unlock a free specialization choice at level 20.
- Unlock powerful augments at level 30 with point costs that double each rank.
- Unlock a second element and automatic combo identity at level 40.
- Add dev buttons for quick level grants and material-project completion while playtesting.
- Package and publish as version `0.4.0` so the mod can be installed from the Factorio Mod Portal.

## Non-Goals For V0.4.0

- Do not support laser, flamethrower, artillery, or modded turret prototypes yet.
- Do not persist mined turret XP through item pickup yet.
- Do not add custom art or new item prototypes yet.
- Do not reintroduce the scrollable skill-tree canvas until a reliable interaction model is confirmed.

## V0.4.1 Scope

- Follow up the V0.4.0 playtest release with chip-based progression and GUI fit fixes.
- Add a craftable, non-stackable Veteran Core item that stores progression as item tags.
- Keep ordinary gun turrets stackable and progression-free until the player installs a core.
- Let the player extract a core and install it into another turret, moving XP, upgrades, element projects, custom name, and label preference.
- Return or spill the core when a turret is mined.
- Let a core profile display an optional floating `name (lvl N)` label above its current turret body.

## Open Product Questions

- Which parts of the long-term progression direction in [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) should ship first: archetype branches, material gates, element slots, combo nodes, or infinite mastery?
- Should destroyed turrets destroy their installed core, drop a damaged core, or have a recovery chance?
- Should XP eventually include waves survived, ammo consumed, or other behavior beyond damage and kill credit?
- Should material investment be manual at first, automated through logistics, or both?
