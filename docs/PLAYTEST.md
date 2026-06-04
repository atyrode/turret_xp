# Playtest

## Install

Preferred once published:

1. Open Factorio.
2. Go to Mods.
3. Search for `Turret XP`.
4. Install version `0.3.2` or newer.
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
6. Confirm the XP bar is one solid bar, not split into a second productivity-looking segment.
7. Confirm the panel uses vanilla-like shallow/deep frames, flib slot styling, and small blue `[img=info]` markers rather than gray custom buttons.
8. Confirm shooting speed and damage show research bonuses as base plus bonus when relevant.
9. If the turret has quality, confirm the turret icon still uses the entity-with-quality tooltip and HP/range rows show `[img=quality_info]` with a quality summary on hover.
10. Scroll the skill tree horizontally and vertically, then confirm the central gun-turret root and four branch nodes are reachable.
11. Click-drag inside empty skill-tree space and confirm the embedded tree scrolls in the same direction as the mouse movement without opening a separate window.
12. Hover each skill node and confirm it only shows the effect gained by allocating the next point.
13. Let the turret shoot enemies.
14. Keep the GUI open or reopen it and confirm XP and lifetime damage increase.
15. Confirm kills increase when the turret lands final hits.
16. After the turret levels up, allocate a skill node and confirm the rank/points refresh immediately.
17. Hover the central root and confirm it summarizes allocated bonuses.
18. Damage a skilled turret and confirm Field Repairs slowly restores HP if that skill is allocated.
19. Change the Turret XP runtime-global settings and confirm the open panel refreshes with the new XP pacing.
20. Select the turret and run `/turret-xp` as a fallback path.

## Report Back

Useful feedback:

- Did the panel appear in the right place?
- Did any stat look wrong or confusing?
- Did XP, kills, skill points, and skill ranks update at the pace you expected?
- Did the mod fail to load, desync, or throw a runtime error?
- Which stat bonuses should the next version try first?
