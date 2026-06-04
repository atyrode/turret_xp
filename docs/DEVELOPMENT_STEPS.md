# Development Steps

## Completed For V0.1.0

- [x] Copy reusable scaffold from `player_quality`.
- [x] Rename metadata to `turret_xp`.
- [x] Add per-gun-turret XP, level, kill, and damage tracking.
- [x] Add GUI extension for vanilla gun turret.
- [x] Add command fallback with `/turret-xp`.
- [x] Update locale, README, docs, changelog, and release scripts.

## Validation

- [ ] Run `scripts/check.sh`.
- [ ] Run `scripts/package.sh`.
- [ ] Inspect zip layout.
- [ ] Initialize git repository and commit.
- [ ] Create/push `atyrode/turret_xp`.
- [ ] Create GitHub release `v0.1.0`.
- [ ] Publish `0.1.0` to the Factorio Mod Portal.

## Likely Next Work

- Decide first real level bonuses.
- Decide whether mined turrets retain XP.
- Update GUI in place instead of rebuilding every 60 ticks.
- Add headless Factorio smoke-test automation if a stable local binary is available.
