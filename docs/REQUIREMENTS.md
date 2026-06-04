# Requirements

## Functional

- The mod must load in Factorio 2.0 with `base >= 2.0.0`.
- Opening a vanilla gun turret must show a Turret XP panel attached to the vanilla turret GUI when possible.
- Each gun turret must have independent tracked progression state.
- Gun turret damage against non-friendly entities must add XP and lifetime damage.
- Gun turret kills must add a kill count and bonus XP.
- XP overflow must advance levels and carry remaining XP into the next level.
- The GUI must refresh while the turret GUI remains open.
- Selecting a gun turret and running `/turret-xp` must open the same panel as a fallback.
- The packaged zip must include `info.json`, Lua files, locale, docs, README, and changelog.

## Display

- Show current level and XP progress to the next level.
- Show current HP and prototype max HP.
- Show attack speed in shots per second.
- Show range in tiles.
- Show loaded ammo and count.
- Show estimated loaded-ammo damage per shot when it can be derived from prototype data.
- Show kills, lifetime damage, and total XP.
- Clearly state that V0.1.0 levels do not apply combat bonuses yet.

## Operational

- `.env` must remain ignored and must not be committed.
- `scripts/check.sh` must validate JSON and Lua syntax when `luac` is available.
- `scripts/package.sh` must create `dist/turret_xp_0.1.0.zip`.
- `scripts/release.sh` must publish/update the matching GitHub release.
- `scripts/publish-portal.sh` must publish/update the matching Factorio Mod Portal release.
