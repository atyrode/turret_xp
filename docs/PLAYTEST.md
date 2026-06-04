# Playtest

## Install

Preferred once published:

1. Open Factorio.
2. Go to Mods.
3. Search for `Turret XP`.
4. Install version `0.1.1` or newer.
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
5. Check that the panel shows level 1, XP progress, HP, attack speed, range, loaded ammo, damage, kills, lifetime damage, and total XP.
6. Let the turret shoot enemies.
7. Keep the GUI open or reopen it and confirm XP and lifetime damage increase.
8. Confirm kills increase when the turret lands killing blows.
9. Select the turret and run `/turret-xp` as a fallback path.

## Report Back

Useful feedback:

- Did the panel appear in the right place?
- Did any stat look wrong or confusing?
- Did XP and kills update at the pace you expected?
- Did the mod fail to load, desync, or throw a runtime error?
- Which stat bonuses should the next version try first?
