# Requirements

## Functional

- The mod must load in Factorio 2.0 with `base >= 2.0.0`.
- Opening a vanilla gun turret must show a Turret XP panel attached to the vanilla turret GUI when possible.
- Each gun turret must have independent tracked progression state.
- Gun turret damage against non-friendly entities must add lifetime damage and damage-derived XP.
- Enemy deaths must add proportional kill-credit XP to contributing gun turrets, even when another source lands the final hit.
- Gun turret final hits must add a killing-blow count.
- Runtime-global mod settings must allow tuning damage XP, kill-credit XP, base level XP, and level XP growth.
- XP overflow must advance levels and carry remaining XP into the next level.
- The GUI must refresh while the turret GUI remains open.
- Selecting a gun turret and running `/turret-xp` must open the same panel as a fallback.
- The packaged zip must include `info.json`, Lua files, locale, docs, README, and changelog.

## Display

- Show current level and XP progress to the next level.
- Show current HP and prototype max HP.
- Show shooting speed in shots per second, including force gun-speed bonuses.
- Show base turret range in tiles to match the vanilla hover stat.
- Show loaded ammo and count.
- Show estimated loaded-ammo damage per shot when it can be derived from prototype data.
- Show killing blows, kill credit, lifetime damage, and total XP.
- Clearly state that V0.1.x levels do not apply combat bonuses yet.

## Operational

- `.env` must remain ignored and must not be committed.
- `scripts/check.sh` must validate JSON and Lua syntax when `luac` is available.
- `scripts/package.sh` must create `dist/turret_xp_<info.json version>.zip`.
- `scripts/release.sh` must publish/update the matching GitHub release.
- `scripts/publish-portal.sh` must publish/update the matching Factorio Mod Portal release.
