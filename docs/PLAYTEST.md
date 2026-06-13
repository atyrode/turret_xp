# Playtest

This guide is split by depth. Run the smoke path for ordinary feedback, the regression path before handing off gameplay changes, and the deep path when validating a release candidate or a high-risk subsystem change.

## Install

Current development package target: `0.10.4`.

Preferred once published:

1. Open Factorio.
2. Go to Mods.
3. Search for `Turret XP`.
4. Install the latest available version.
5. Restart when Factorio asks.

Manual local fallback:

```sh
scripts/install-local.sh
```

## Smoke Path

Use this when you only need to confirm the mod loads and the main loop works.

1. Start or load a Factorio 2.0 save with `turret_xp` enabled.
2. Place a vanilla gun turret and add ammo.
3. Open the turret and confirm the `Turret XP` panel appears beside the vanilla GUI.
4. Install or dev-create a Veteran Core.
5. Confirm level, XP, HP, shooting speed, range, Magazine, Ammo, damage, estimated DPS, kills, and Evolution sections appear.
6. Let the turret shoot enemies and confirm XP, damage, kill credit, and level progress update.
7. Spend one core upgrade and confirm ranks, points, and stats refresh without moving the vanilla turret GUI.
8. Name the core, toggle `Show`, and confirm the floating label appears above the turret.
9. Extract and reinstall the core, then confirm XP, upgrades, name, and label settings move with it.
10. Select the turret and run `/turret-xp` to confirm the fallback open command.

## Regression Path

Use this path before merging gameplay, GUI, persistence, feeder, combat, or release-sensitive changes.

### Core And Movement

1. Move an installed core to the cursor, put it in inventory, reinstall it, and confirm profile state is preserved.
2. Swap two Veteran Cores through the scripted slot and confirm the outgoing core keeps its stored profile.
3. Mine an unbound veteran turret and confirm the normal turret item and Veteran Core return separately.
4. Bind the installed core, mine the turret, and confirm one tagged bound veteran turret item returns instead of separate turret/core items.
5. Place the bound item and confirm the turret, installed profile, name/label settings, quality, health ratio, and loaded ammo restore.
6. Unbind it and confirm mining returns to the separate item behavior again.
7. Mine a bound turret with no free inventory slot and confirm a tagged bound item spills instead of losing the core profile.

### GUI And Evolution

1. Move or resize the vanilla turret GUI, then spend points, change sections, and reset Evolution. The whole vanilla GUI should not jump back to its default position.
2. Confirm the Evolution header shows `Core:`, `Aug:`, and `Spec:` once, with six bounded sections below it.
3. Use `/turret-xp-dev` to reach levels 10, 20, 30, 40, and 50.
4. Pick specialization, first element, augment, sub-specialization, and second element/combo at their gates.
5. Use section `Change` actions and the full Evolution `Reset`; XP, level, kills, damage, name, and binding should remain.
6. Hover stat-name info markers and confirm formulas live there. HP and Range quality breakdowns should live on the quality diamond.
7. Confirm stats reserve scrollbar space and values do not render under the scrollbar.
8. Confirm numeric rich text colors only numbers; units and prose stay neutral.

### Combat And Stats

1. Spend Shield ranks, damage the turret, and confirm Shield absorbs damage before HP, uses the nine-pip in-world bar, does not recharge while taking damage, and does not refill for free when capacity changes.
2. Spend Resistance ranks and confirm non-lethal damage is mitigated while overwhelming lethal hits can still kill the turret.
3. Spend Ammo Productivity ranks and confirm the purple bar appears after Ammo, advances as ammo is spent, restores +1 ammo inside the current magazine, does not overfill, and does not create full ammo items.
4. Test Regeneration, Shield on Hit, and Brawler Lifesteal in combat and check whether HP healing versus shield generation is understandable.
5. Confirm Crit Chance and Crit Damage appear under Damage Dealt as regular baseline stats.
6. Confirm Fire and Toxic damage-over-time ticks count for XP, kill credit, and lifesteal.
7. Confirm Electric arc visuals expire quickly and do not leave map entities behind.
8. If Bullet Trails is installed, confirm bounce, double-shot, and element tracers are more readable without becoming noisy. If it is absent, confirm fallback visuals still appear and the mod still loads.

### Feeder And Materials

1. Pick an element and confirm its current rank, technical effect, next material requirement, and progress bar are always visible.
2. Feed ammo with inserters and confirm normal turret ammo logistics still work.
3. Feed the selected element material with normal, fast, stack, and bulk inserters; passive progress should advance without a deposit button or visible feeder chest.
4. Confirm only selected element resources are accepted and no item pile forms around the turret.
5. Drop or stale-hand insert one wrong item, then confirm hidden input cleanup clears it and correct material progress can continue.
6. Test a mixed pair such as Fire + Explosive from one chest containing sulfur and grenades. Managed inserters should expose and feed both needed resources.
7. Test a duplicate pair such as Explosive + Explosive and confirm the stats summary shows one Explosive row plus the combo identity.
8. Extract or mine the core and confirm leftover feeder contents spill instead of disappearing.

## Deep Manual Path

Run this when validating release candidates, compatibility claims, or high-risk persistence changes.

### Bound Item Edge Cases

- Bind a Sniper or range-changing sub-specialization, hold the bound item, and confirm Factorio's native placement range preview matches the restored turret range. Old generic or retired preview stacks may need to be placed and mined once.
- Mine a bound turret with ammo loaded, place it again, and confirm ammo is restored only in the turret, not duplicated in player inventory.
- With Fill4Me or another placement helper enabled, place a bound turret that stores ammo and confirm placement-time ammo is refunded before the saved snapshot is restored.
- Destroy a regular gun turret with no Veteran Core and confirm the replacement ghost requests the normal gun turret item, not a bound veteran item.

### Specialization And Compatibility

- Test Sniper, Machine Gun, Bulwark, Brawler, and every sub-specialization. Confirm the stats summary shows branch identity and combined multipliers.
- Confirm Brawler feels like a slower close-range heavy role: high damage, lower attack speed, short range, and innate Lifesteal.
- Pick Sniper or a range-changing sub-specialization and confirm displayed range changes and the turret can actually fire farther.
- With a mod that changes vanilla gun turret range during data updates, confirm specialization range multipliers apply to the modded base range.
- With K2/K2SO-style realistic rifle ammo, confirm long-range Turret XP builds do not shoot endlessly at targets beyond physical bullet delivery range.

### Platform Behavior

- On a space platform, place one or more Veteran Cores in the hub inventory, open a platform turret, and confirm the panel lists exact available cores.
- Install a specific listed core, then send it back to the hub and confirm the same profile returns when hub inventory has room.
- Let a platform turret fight and confirm XP rises much more slowly than comparable surface combat while raw damage and kills still display.
- Park a space platform above asteroid-heavy traffic and confirm asteroid kills do not overlevel a core.

### Long-Fight Balance

- Let several turret builds survive real waves and compare XP pace, level gates, material rank progress, and ammo demand.
- Check whether Shield, Regeneration, Ammo Productivity, Shield on Hit, Lifesteal, Luck, Double Shot, Bounce, and element procs are readable without dominating the screen.
- Confirm specialization tradeoffs are understandable: range for fire rate, fire rate for damage per shot, survivability for peak damage, and XP gain for immediate power.
- Change runtime-global XP settings and confirm open panels refresh with the new pacing.

## Report Back

Most useful feedback:

- Did the panel appear in the right place and stay stable while actions refreshed?
- Did the Veteran Core install/extract/swap flow feel natural?
- Did Bind/Unbind make quick turret moves clearer, or does it need different wording or placement?
- Did the core slot feel close enough to an inventory slot, especially cursor transfer and swap?
- Did label color and level visibility cover the customization needed for now?
- Did the hidden turret-tile input feel reliable and readable enough?
- Did passive material progress feel like a clear material goal?
- Which specialization, element, combo, augment, or stat felt confusing, too weak, or too strong?
- Did Shield feel like a satisfying survivability replacement for Max HP?
- Did target-aware XP pacing feel closer to intended progression speed, especially for passive asteroid defense?
- Did optional Bullet Trails improve scripted feedback without adding noise?
- Did the mod fail to load, desync, or throw a runtime error?
