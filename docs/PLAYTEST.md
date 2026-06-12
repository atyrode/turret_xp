# Playtest

## Install

Current development playtest:

0.10.3 is the current package target for the next Mod Portal playtest release.

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

## Test Path

1. Start or load a Factorio 2.0 save with `turret_xp` enabled.
2. Place a vanilla gun turret.
3. Add firearm, piercing, or uranium ammo.
4. Open the turret and confirm the `Turret XP` panel appears to the right of the vanilla GUI.
5. Confirm the panel says no Veteran Core is installed and XP/evolution are inactive.
6. Craft or dev-create a Veteran Core and install it.
7. Check that the panel shows level, XP progress, HP, shooting speed, range, loaded ammo, damage, estimated DPS, kills, lifetime damage, and a second main Evolution column with a fixed summary header plus bounded scrolling sections.
8. Name the core and confirm the `Show` checkbox sits beside the name field, with label color controls hidden while `Show` is off.
9. Enable `Show label` and confirm the floating text appears as `name (lvl N)` above the turret.
10. Change label color with RGB sliders and the preset/custom color button below them, then confirm presets keep their preset names, RGB slider edits show `Custom`, `Level` appears below the color button, and the floating label keeps its display-panel-style backing.
11. Click the Veteran Core slot to move the installed tagged core to the cursor, put it in inventory, reinstall it, and confirm XP, upgrades, name, and label settings move with the core.
12. Swap two Veteran Cores through the slot and confirm the outgoing core keeps its stored profile.
13. Shift/Ctrl-click the installed core slot and confirm it returns to inventory when there is room.
14. Pick an element, then use the section `Change` action and confirm a different element can be selected.
15. Move/resize the vanilla turret GUI if needed, click Evolution actions, and confirm the Turret XP panel stays narrow and Evolution content does not render under the scrollbar.
16. Mine a turret with an unbound core installed and confirm the gun turret item and Veteran Core are returned separately.
17. Bind the installed core from the Veteran Core slot row, mine the turret, and confirm inventory receives one bound veteran turret item rather than separate turret/core items.
18. Place the bound veteran turret item and confirm the turret, installed core profile, name/label settings, quality, health ratio, and loaded ammo restore. Unbind it and confirm mining returns to the separate item behavior.
18a. Bind a turret with Sniper or Range ranks, hold the bound turret item in hand, and confirm Factorio's native placement range preview matches the restored turret range. Old generic bound stacks may need to be placed and mined once before they become a range-specific preview item.
18b. Mine a bound turret with ammo loaded, place the bound item again, and confirm the ammo is restored only in the turret: the player inventory must not also receive a duplicate copy.
18c. With Fill4Me or another placement helper enabled, place a bound turret that already stores ammo and confirm all placement-time ammo is refunded before the saved bound ammo snapshot is restored.
18d. Mine a bound turret with no free inventory slot and confirm a tagged bound turret item spills on the ground instead of returning only a Veteran Core or losing the profile.
19. Destroy a regular gun turret with no Veteran Core and confirm the replacement ghost displays and requests the normal gun turret item, not the bound veteran turret item.
20. Confirm the Evolution header shows `Core:`, `Aug:`, and `Spec:` summary text once, with white labels and colored values, and that the scrollable body has six sections: core upgrades, specialization, first element, powerful augments, sub-specialization, and second element/combo.
21. Confirm level-gated sections show their unlock levels before using dev tools.
22. Run `/turret-xp-dev` and use `+1` and `+5` dev buttons to reach levels 10, 20, 30, 40, and 50 quickly.
23. Run `/turret-xp-dev` again and confirm dev controls hide/show without breaking the panel layout.
24. Spend core upgrade points and confirm ranks and remaining points refresh immediately without moving the whole vanilla turret GUI.
24a. Spend Max HP augment ranks, close/reopen if needed for the deferred body swap, and confirm the real HP maximum increases by 50 per rank up to rank 20.
24b. Spend Ammo Recovery ranks, let the turret remember loaded ammo, empty the turret, and confirm recovered ammo is slowly inserted back into the turret ammo inventory.
24c. Spend Resistance ranks, damage the turret with enemies, and confirm the stats panel shows reduced damage taken while the turret still dies normally to overwhelming lethal hits.
25. Confirm unlocked Evolution choices have category headers, right-side status text, horizontal delimiters, and are easier to scan.
25a. Confirm Evolution section frames have balanced left/right padding, visible right margin, and spacing between adjacent sections.
26. Hover allocation buttons and confirm the tooltip describes the specific upgrade and next rank.
27. Use the always-visible Evolution-header Reset. Confirm it clears core upgrades, augments, specialization, sub-specialization, elements, and mastery ranks while keeping XP, level, kills, damage, name, and binding.
28. Use dev `Reset` and confirm the installed core returns to a fresh zero-XP state.
29. At level 10, pick Sniper, Machine Gun, Bulwark, or Brawler and confirm the choice is locked in without moving the whole vanilla turret GUI back to its default position. Close the turret GUI, reopen it, and confirm real turret stats changed.
30. Pick an element and confirm its current rank, technical effect, next material requirement, and progress bar are always visible without clicking an Upgrade button.
31. Confirm no visible feeder chest appears near the turret and the Evolution column does not show feeder status text.
32. Feed ammo into the turret with inserters and confirm the turret still receives ammo with a Veteran Core installed.
33. Feed the required material into the turret area with an inserter and confirm passive element progress advances without a deposit or upgrade-start button.
34. Repeat material feeding with normal and bulk inserters; confirm only resources for selected elements are accepted and no item pile forms around the turret. If a stale inserter hand drops the wrong material once, confirm the hidden input clears it and the correct material can still advance the progress bar.
35. Confirm ammo inserters keep feeding ammo while element material feeding is available.
36. Use `Materials` and confirm it completes the next passive material rank for an unlocked element.
37. Confirm specialization choices use the same card rhythm as element choices: icon/title row, full-width description, separator, colored multiplier row, and right-aligned Pick button.
37a. Confirm the role-specific secondary multiplier is visible and functional: Sniper boosts Crit Damage, Machine Gun boosts Ammo Recovery, Bulwark boosts Regeneration, and Brawler boosts Lifesteal.
37b. Confirm Brawler feels like a slower close-range heavy role rather than a pure burst upgrade: x3 damage, x0.5 fire rate, short range, and lifesteal.
38. At level 30, buy a powerful augment and confirm augment points are earned every ten levels.
39. Buy Range ranks and confirm the displayed range changes and the turret can actually fire farther.
39a. Level a turret through combat and confirm a short `Level up!` popup appears above the turret when the core gains a level.
40. With a mod that changes vanilla gun turret range during data updates, such as K2 Spaced Out, confirm buying Range rank 1 adds to the modded base range instead of reducing it.
40a. With K2/K2SO realistic weapons enabled, test a long-range Turret XP build with rifle ammo and confirm the turret no longer shoots endlessly at targets beyond the physical bullet delivery range.
41. At level 40, pick one of the two sub-specializations for the active role and confirm the stats summary shows the branch identity and combined multipliers.
42. Confirm an unlocked element card stays inside the Evolution column, keeps its `Change` action visible, and keeps next-rank material progress visible.
43. At level 50, pick a second element for free and confirm the combo text appears.
44. Test a mixed pair such as Fire + Explosive from one chest containing sulfur and grenades. Confirm managed inserters can expose and feed both needed resources for passive rank progress.
45. Test a duplicate pair such as Explosive + Explosive and confirm the stats summary shows one Explosive line plus the combo identity, not two Explosive stat rows.
46. Extract or mine the core and confirm leftover feeder contents spill instead of disappearing.
47. Let the turret shoot enemies and confirm XP, damage dealt, kills, active custom stat rows, and upgrade/element visual feedback feel visible enough to judge. Electric arc visuals should disappear quickly instead of staying on the map. Crits, double shots, bounce, Fire burn, and Toxic poison should be readable enough to notice when they happen.
47a. Confirm the stats panel reserves space for its scrollbar when it becomes scrollable, and that Crit Chance and Crit Damage appear under Damage Dealt as regular baseline stats.
47b. Confirm stat, upgrade, augment, and element value text colors only the numeric parts, with units and descriptive words staying neutral; elemental damage numbers should use their element color.
48. Damage turrets with regeneration ranks and confirm passive repair scales with current max HP, especially after Max HP ranks or Bulwark/Guardian choices.
49. Try Lifesteal in combat and check whether vampiric healing is understandable.
50. Change the Turret XP runtime-global settings and confirm the open panel refreshes with the new XP pacing.
51. Spend points, toggle label settings, unlock elements, use Change actions, and reset Evolution while the vanilla turret GUI is moved. Confirm the whole vanilla turret GUI does not jump back to its default position.
52. Select the turret and run `/turret-xp` as a fallback path.
53. On a space platform, place one or more Veteran Cores in the platform hub inventory, open a platform turret, and confirm the panel lists the exact available cores.
54. Install a specific listed platform core, then send it back to the hub and confirm the same profile returns when hub inventory space is available.
55. Let a platform turret fight and confirm XP rises much more slowly than comparable surface combat while damage/kills still show raw totals.
56. Park a space platform above an asteroid-heavy route or planet orbit and confirm asteroid kills no longer level a Veteran Core too quickly.
57. If Bullet Trails is installed, confirm bounce, double-shot, and element tracers are more readable without becoming visually noisy. Double Shot should fire at a second nearby enemy when one exists, otherwise into the original target. If Bullet Trails is not installed, confirm the mod still loads and fallback visuals still appear.

## Report Back

Useful feedback:

- Did the panel appear in the right place?
- Did the Veteran Core install/extract flow feel like a natural way to choose which turret becomes unique?
- Did moving a core between turrets preserve the right information?
- Did Bind/Unbind make quick turret moves clearer, or does it need a different label or placement in the panel?
- Did the core slot feel close enough to an inventory slot, especially cursor transfer and swap?
- Did label color and level visibility cover the customization you need now that label size is fixed?
- Did the RGB sliders feel good enough compared with the vanilla train color picker, given that mods do not get that exact picker widget?
- Did the hidden turret-tile input accept element materials from normal and bulk inserters while still forwarding ammo reliably enough, or did it feel too invisible/unclear?
- Did passive element rank progress feel like a clear material goal, including no wrong-item stalls or ground overflow?
- Did the optional floating label feel useful, and should it be visible only in alt mode or always visible?
- Did the wider two-column layout give Evolution and stats enough room without making the whole attached panel too wide?
- Did the static Evolution header plus scrollable section body feel cleaner than the previous all-in-one scrolling column?
- Did the six-section Evolution column feel clearer than the skill tree?
- Did the delimiters make the Evolution choices easier to parse?
- Did the full Evolution Reset and focused `Change`/deallocation controls behave as expected?
- Did level gates 10, 20, 30, 40, and 50 feel like the right first draft?
- Were passive material rank requirements understandable?
- Which element, specialization, or augment felt confusing or too weak?
- Did Range ranks and specialization multipliers feel meaningful without breaking the turret role?
- Did specialization, Range, Change actions, and full Evolution Reset avoid moving the whole vanilla turret GUI?
- If using K2 Spaced Out or another turret-range mod, did Range ranks preserve the modded base range?
- Did XP, kills, evolution points, and ranks update at the pace you expected?
- Did the platform hub core selector make it clear which Veteran Core was being installed?
- Did target-aware XP pacing feel closer to the intended progression speed, especially for passive asteroid defense?
- Did optional Bullet Trails feedback make scripted bullets and elements easier to understand?
- Did the mod fail to load, desync, or throw a runtime error?
