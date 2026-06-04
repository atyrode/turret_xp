# Project Spec

## Version 0.4.1

V0.4.1 keeps the vanilla turret GUI as the main interaction and keeps the five-section Evolution list from V0.4.0. The new goal is to make turret identity an explicit player choice through a movable Veteran Core item, while leaving ordinary gun turrets stackable and inventory-friendly.

V0.4.0 was published to the Factorio Mod Portal for playtesting before this follow-up release.

## Runtime Behavior

- State lives under `storage.turret_xp`.
- Turret host records are keyed by turret entity `unit_number`.
- Durable progression profiles are keyed by Veteran Core ID under `storage.turret_xp.chips`.
- A turret without an installed Veteran Core has no XP/evolution profile and does not gain progression.
- New core profiles start at level 1 with zero XP, kills, kill credit, damage, total XP, custom name, display-label flag, and empty evolution choices.
- Veteran Cores are non-stackable `item-with-tags` items. Extracted cores serialize their profile into item tags.
- XP is derived from lifetime damage, kill credit, runtime-global XP settings, core XP upgrade ranks, and optional dev XP.
- Default damage XP is `0.02` XP per final damage point.
- Default kill-credit XP is `20` XP per full kill credit.
- Default level XP starts at `100` and grows by a `1.65` exponential multiplier each level.
- Kill credit is split proportionally by damage contribution so turrets are not fully denied XP when another source lands the final hit.
- Evolution points equal `level - 1 - spent_points`.
- Core upgrade ranks cost one point each and can be purchased repeatedly.
- Powerful augment ranks unlock at level 30 and cost `1`, `2`, `4`, `8`, and so on per rank.
- Element choices do not cost points. They start a material project that permanently assigns the element when complete.
- Specialization unlocks at level 20 and is a free one-time choice.
- Mined turrets return the installed Veteran Core as a separate item or spill it if there is no inventory room.
- Destroyed turrets currently destroy the installed core/profile.

## Veteran Core Behavior

- Recipe name: `turret-xp-veteran-core`.
- Prototype type: `item-with-tags`.
- Stack size: `1`.
- Unlock: added to the vanilla `military` technology when present.
- First draft recipe: `20` electronic circuits, `10` steel plates, `40` copper cable, and `2` repair packs.
- Installing a carried core removes the item and binds its profile to the opened gun turret.
- Extracting a core returns the profile item to the player inventory.
- If the turret is mined, the normal gun turret item returns through vanilla behavior and the mod separately returns/spills the Veteran Core.
- The profile can be named. If the player enables the label, the world label renders as `name (lvl N)` above the current turret body.

## Evolution Sections

- `Core upgrades`: unlocked from level 1. Includes Damage, Regeneration, Lifesteal, Crit Chance, and Crit Damage.
- `First element`: unlocks at level 10. Starts a material project for Explosive, Fire, or Electric.
- `Specialization`: unlocks at level 20. Picks Sniper, Machine Gun, or Bulwark for free.
- `Powerful augments`: unlocks at level 30. Includes Bullet Bounce, Piercing Follow-through, and Longshot Optics.
- `Second element and combo`: unlocks at level 40. Starts a second material project and derives a combo from the two selected elements.

## Combat Effects

- Damage adds flat scripted physical bonus damage per shot.
- Regeneration adds passive turret repair.
- Lifesteal heals the turret from damage dealt.
- Crit Chance improves critical hit chance.
- Crit Damage improves critical hit damage.
- Sniper adds scripted damage and crit chance.
- Machine Gun adds bonus-hit chance and improves bounce scaling.
- Bulwark adds passive repair and vampiric healing.
- Bullet Bounce can damage a nearby enemy.
- Piercing Follow-through can damage an enemy behind the target.
- Longshot Optics adds damage when the target is near the turret's current range limit. It does not extend vanilla acquisition range.
- Fire can add fire damage.
- Electric can arc damage to a nearby enemy.
- Explosive can splash damage around the target.
- Mixed or duplicate element pairs derive simple combo behavior.

## GUI Behavior

- `on_gui_opened` detects vanilla `gun-turret`.
- The mod creates a frame in `player.gui.relative` anchored to `defines.relative_gui_type.turret_gui` on the right side.
- If relative anchoring fails, the panel falls back to `player.gui.left`.
- `on_gui_closed` destroys the panel and clears the remembered player/turret link.
- The panel includes a Veteran Core section for install, extract, dev core creation, naming, and floating-label toggle.
- The panel updates named stat elements and rebuilds the Evolution list every 60 ticks while the turret GUI remains open.
- The GUI depends on `flib >= 0.16.4` for shared Factorio-style slot, pusher, and panel styles.
- The XP bar uses a custom solid progressbar style defined in `data.lua`.
- Dev buttons can create a test core, grant quick levels, and complete the active material project.

## Release Target

- Mod name: `turret_xp`
- Current version: `0.4.1`
- GitHub repository: `atyrode/turret_xp`
- Factorio Mod Portal title: `Turret XP`
