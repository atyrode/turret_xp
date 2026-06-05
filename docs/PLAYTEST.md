# Playtest

## Install

Current portal playtest:

0.4.5 is published on the Factorio Mod Portal.

Preferred once published:

1. Open Factorio.
2. Go to Mods.
3. Search for `Turret XP`.
4. Install version `0.4.0` or newer.
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
5. Confirm the panel says no Veteran Core is installed and XP/evolution are inactive.
6. Craft or dev-create a Veteran Core and install it.
7. Check that the panel shows level, XP progress, HP, shooting speed, range, loaded ammo, damage, estimated DPS, kills, lifetime damage, and the Evolution list.
8. Name the core, enable `Show label`, and confirm the floating text appears as `name (lvl N)` above the turret.
9. Change label color, size, and level visibility, then confirm those choices update the floating label.
10. Click the Veteran Core slot to move the installed tagged core to the cursor, put it in inventory, reinstall it, and confirm XP, upgrades, name, and label settings move with the core.
11. Swap two Veteran Cores through the slot and confirm the outgoing core keeps its stored profile.
12. Shift/Ctrl-click the installed core slot and confirm it returns to inventory when there is room.
13. Mine a turret with a core installed and confirm the gun turret item and Veteran Core are returned separately.
14. Confirm the Evolution list has five sections: core upgrades, first element, specialization, powerful augments, and second element/combo.
15. Confirm level-gated sections show their unlock levels before using dev tools.
16. Use `+1` and `+5` dev buttons to reach levels 10, 20, 30, and 40 quickly.
17. Confirm dev controls fit within the Turret XP panel width.
18. Spend core upgrade points and confirm ranks and remaining points refresh immediately.
19. Hover allocation buttons and confirm the tooltip describes the specific upgrade and next rank.
20. Use `Respec` and confirm core upgrade and augment point ranks reset while element/specialization choices stay.
21. Use dev `Reset` and confirm the installed core returns to a fresh zero-XP state.
22. At level 10, start an Explosive, Fire, or Electric element project.
23. Confirm the active project shows item requirements and a progress bar.
24. Confirm a Veteran Core feeder appears near the turret and the Evolution panel shows its feeder status.
25. Insert the required material into the feeder manually or with an inserter and confirm the project progress advances without a deposit button.
26. Use `Materials` and confirm the element becomes active, or advances the selected element's next mastery milestone if no unlock project is active.
27. At level 20, pick Sniper, Machine Gun, Bulwark, or Brawler and confirm the choice is locked in and the turret stats change.
28. At level 30, buy a powerful augment and confirm augment points are earned every ten levels.
29. At level 40, start and complete a second element project and confirm the combo text appears.
30. Extract or mine the core and confirm leftover feeder contents spill instead of disappearing.
31. Let the turret shoot enemies and confirm XP, damage dealt, kills, and upgrade effect feedback feel visible enough to judge.
32. Damage a turret with regeneration ranks and confirm passive repair works.
33. Try Lifesteal in combat and check whether vampiric healing is understandable.
34. Change the Turret XP runtime-global settings and confirm the open panel refreshes with the new XP pacing.
35. Select the turret and run `/turret-xp` as a fallback path.

## Report Back

Useful feedback:

- Did the panel appear in the right place?
- Did the Veteran Core install/extract flow feel like a natural way to choose which turret becomes unique?
- Did moving a core between turrets preserve the right information?
- Did the core slot feel close enough to an inventory slot, especially cursor transfer and swap?
- Did label color, size, and level visibility cover the customization you need?
- Did the feeder feel like a natural machine input, and was its adjacent placement readable?
- Did the optional floating label feel useful, and should it be visible only in alt mode or always visible?
- Did the five-section list feel clearer than the skill tree?
- Did the Respec and dev Reset controls behave as expected?
- Did level gates 10, 20, 30, and 40 feel like the right first draft?
- Were material project requirements understandable?
- Which element, specialization, or augment felt confusing or too weak?
- Did XP, kills, evolution points, and ranks update at the pace you expected?
- Did the mod fail to load, desync, or throw a runtime error?
