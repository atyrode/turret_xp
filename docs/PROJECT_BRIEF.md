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

## V0.4.2 Scope

- Make specialization choices change real turret stats through hidden gun-turret prototype variants.
- Add Sniper, Machine Gun, Bulwark, and Brawler turret bodies generated from multipliers on vanilla turret range, cooldown, damage modifier, health, and rotation speed.
- Revert specialized bodies back to the normal gun turret when the Veteran Core is extracted.
- Replace exponential level scaling with linear per-level scaling.
- Replace doubling augment costs with one augment point every ten levels.
- Remove material deposit buttons and consume the matching carried element resource automatically during open-panel playtesting.
- Add first-pass element fuel and visual feedback for bounce, double shot, fire, electric, explosive, and combo effects.

## V0.4.3 Scope

- Replace player-inventory material feeding with a real Veteran Core feeder inventory entity.
- Create the feeder next to the turret when a Veteran Core is installed, and show its status in the Evolution panel.
- Consume element unlock materials and element fuel from the feeder over time, even when the turret GUI is closed.
- Destroy the feeder and spill leftover feeder contents when the core is extracted or the turret is mined.

## V0.4.4 Scope

- Fix fresh Veteran Core installation after the feeder release.
- Remove level-scaled progression recalculation from normal combat damage.
- Add user respec and dev reset controls.
- Polish allocation button visuals and hover text.

## V0.4.5 Scope

- Make the Veteran Core control behave more like an inventory slot while preserving tagged profile data.
- Add floating label color, size, and level-suffix controls.
- Compact dev controls and remove redundant installed-core profile id text from the panel.

## V0.4.6 Scope

- Remove the visible adjacent feeder chest from play.
- Keep material progression inserter-fed by using an invisible hidden input colocated with the turret.
- Forward inserter-fed ammo from the hidden input into the turret ammo inventory so normal turret ammo logistics still work.
- Remove feeder status from the Evolution panel.
- Standardize floating labels to the larger readable size, keep color and level-suffix controls, and move labels higher above the turret.
- Polish core upgrade rows, allocation button styling, material requirement icons, and no-ammo damage text.
- Replace Longshot and Piercing augments with Double Shot and Veteran Training.

## V0.4.7 Scope

- Fix hidden-input ammo detection by using `prototypes.item` instead of `game.item_prototypes`.
- Add a prototype-backed Range augment with up to 20 ranks.
- Generate specialization bodies from multipliers on vanilla turret stats instead of fixed flat stat assignments.
- Increase first element unlock material costs by 10x.
- Replace post-unlock element mastery ranks with an element fuel buffer consumed by element combat effects.
- Put the name field and label controls on one row and lower the floating world label from the 0.4.6 offset.

## V0.6.0 Scope

- Treat the release as the first playable Veteran Core turret playthrough.
- Hide dev controls by default and add `/turret-xp-dev` to toggle them for testing.
- Rework unlocked element fuel into a coherent furnace-like burner: inserters fill to capacity, valid excess fuel is buffered instead of spilled, one item burns for 30 seconds, and element effects run while burning.
- Add element mastery ranks that spend regular core points after unlock.
- Show active custom stats only when present, with specialization multipliers next to affected values.
- Preserve Evolution list context after allocating points by scrolling back to the clicked row.
- Split naming and floating-label controls into compact rows that fit the attached turret panel.
- Show explicit technical effect text for augments and specialization choices.
- Fix killed-target runtime crashes in upgrade visual feedback.
- Enlarge allocation controls so the `+` button is not cropped.

## Open Product Questions

- What final mod name, short description, portal category, and sober Factorio-native portal image best communicate Veteran Core turret progression once the core loop stabilizes?
- Which parts of the long-term progression direction in [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) should ship first: archetype branches, material gates, element slots, combo nodes, element fuel, or infinite mastery?
- Should destroyed turrets destroy their installed core, drop a damaged core, or have a recovery chance?
- Should XP eventually include waves survived, ammo consumed, or other behavior beyond damage and kill credit?
- Does the hidden turret-tile input plus ammo-forwarding behavior feel reliable with inserters in practical layouts, or does the material input need a clearer visible design later?
