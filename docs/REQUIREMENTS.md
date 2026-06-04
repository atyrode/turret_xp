# Requirements

## Functional

- The mod must load in Factorio 2.0 with `base >= 2.0.0` and `flib >= 0.16.4`.
- Opening a vanilla gun turret must show a Turret XP panel attached to the vanilla turret GUI when possible.
- Each gun turret must have independent tracked progression state.
- Gun turret damage against non-friendly entities must add lifetime damage and damage-derived XP.
- Enemy deaths must add proportional kill-credit XP to contributing gun turrets, even when another source lands the final hit.
- Gun turret final hits must add a killing-blow count.
- Runtime-global mod settings must allow tuning damage XP, kill-credit XP, base level XP, and level XP growth.
- XP overflow must advance levels and carry remaining XP into the next level.
- Skill points must be derived from turret level and spent allocations.
- Clicking an available skill bubble must allocate one rank to the opened turret and refresh the panel.
- The GUI must refresh while the turret GUI remains open.
- Selecting a gun turret and running `/turret-xp` must open the same panel as a fallback.
- The packaged zip must include `info.json`, Lua files, locale, docs, README, and changelog.

## Display

- Show current level and XP progress to the next level.
- Show current HP and prototype max HP.
- Show shooting speed in shots per second, including force gun-speed bonuses.
- Show turret attack range in tiles, including quality range multiplier when relevant.
- Show loaded ammo and count.
- Show estimated loaded-ammo damage per shot and estimated DPS when they can be derived from prototype data.
- Show kills, lifetime damage, and skill points.
- Show a first skill tree with 3-5 allocatable skills.
- Clearly state that V0.3.0 skill effects are early baseline effects, not the final combat-bonus design.

## Operational

- `.env` must remain ignored and must not be committed.
- `scripts/check.sh` must validate JSON and Lua syntax when `luac` is available.
- `scripts/package.sh` must create `dist/turret_xp_<info.json version>.zip`.
- `scripts/release.sh` must publish/update the matching GitHub release.
- `scripts/publish-portal.sh` must publish/update the matching Factorio Mod Portal release.
