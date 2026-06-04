# Playtest

## Install

Preferred once published:

1. Open Factorio.
2. Go to Mods.
3. Search for `Turret XP`.
4. Install version `0.3.0` or newer.
5. Restart when Factorio asks.

Manual local fallback:

```sh
scripts/install-local.sh
```

## Test Path

1. Start or load a Factorio 2.0 save with `turret_xp` enabled.
2. Place a vanilla gun turret.
3. Add firearm, piercing, or uranium ammo.
4. Open the turret and confirm the `Turret XP` panel appears to the right of the vanilla GUI.
5. Check that the panel shows level 1, XP progress, HP, shooting speed, range, loaded ammo, damage, estimated DPS, kills, lifetime damage, and the skill tree.
6. Confirm the panel uses vanilla-like shallow/deep frames, flib slot styling, and small blue `[img=info]` markers rather than gray custom buttons.
7. Confirm shooting speed and damage show research bonuses as base plus bonus when relevant.
8. If the turret has quality, confirm the turret icon still uses the entity-with-quality tooltip and HP/range rows show `[img=quality_info]` with a quality summary on hover.
9. Let the turret shoot enemies.
10. Keep the GUI open or reopen it and confirm XP and lifetime damage increase.
11. Confirm kills increase when the turret lands final hits.
12. After the turret levels up, allocate a skill bubble and confirm the rank/points refresh immediately.
13. Damage a skilled turret and confirm Field Repairs slowly restores HP if that skill is allocated.
14. Change the Turret XP runtime-global settings and confirm the open panel refreshes with the new XP pacing.
15. Select the turret and run `/turret-xp` as a fallback path.

## Report Back

Useful feedback:

- Did the panel appear in the right place?
- Did any stat look wrong or confusing?
- Did XP, kills, skill points, and skill ranks update at the pace you expected?
- Did the mod fail to load, desync, or throw a runtime error?
- Which stat bonuses should the next version try first?
