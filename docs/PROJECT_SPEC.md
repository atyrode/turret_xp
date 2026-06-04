# Project Spec

## Version 0.4.2

V0.4.2 keeps the vanilla turret GUI as the main interaction and keeps the five-section Evolution list from V0.4.0. Turret identity is an explicit player choice through a movable Veteran Core item, while ordinary gun turrets stay stackable and inventory-friendly. Specialization choices now swap the current turret into hidden gun-turret variants with real prototype stat changes.

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
- Default level XP starts at `100` and grows linearly. The default `1.65` growth setting means each level adds `65%` of base XP to the next requirement.
- Kill credit is split proportionally by damage contribution so turrets are not fully denied XP when another source lands the final hit.
- Core points equal `level - 1 - spent_core_points`.
- Core upgrade ranks cost one point each and can be purchased repeatedly.
- Powerful augment ranks unlock at level 30, cost one augment point each, and earn one augment point every ten levels.
- Element choices do not cost points. They start a single-resource material project that permanently assigns the element when complete.
- Unlocked elements can continue consuming their matching resource to advance element mastery milestones.
- Specialization unlocks at level 20 and is a free one-time choice.
- Specialization swaps the turret body between vanilla `gun-turret` and hidden `turret-xp-gun-turret-*` variants. Removing the Veteran Core returns the turret body to vanilla `gun-turret`.
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
- `Specialization`: unlocks at level 20. Picks Sniper, Machine Gun, Bulwark, or Brawler for free.
- `Powerful augments`: unlocks at level 30. Includes Bullet Bounce, Piercing Follow-through, and Longshot Optics. Augment points are earned every ten levels.
- `Second element and combo`: unlocks at level 40. Starts a second material project and derives a combo from the two selected elements.

## Combat Effects

- Damage adds flat physical bonus damage per shot.
- Regeneration adds passive turret repair.
- Lifesteal heals the turret from damage dealt.
- Crit Chance improves critical hit chance.
- Crit Damage improves critical hit damage.
- Sniper is a real turret body variant: range `34`, cooldown `15`, damage modifier `2.8`, max HP `350`.
- Machine Gun is a real turret body variant: range `16`, cooldown `3`, damage modifier `0.58`, max HP `360`.
- Bulwark is a real turret body variant: range `17`, cooldown `8`, damage modifier `0.65`, max HP `1200`.
- Brawler is a real turret body variant: range `7`, cooldown `8`, damage modifier `4.0`, max HP `650`.
- Bullet Bounce can damage a nearby enemy.
- Piercing Follow-through can damage an enemy behind the target.
- Longshot Optics adds damage when the target is near the turret's current range limit. It benefits from the current turret body's real range.
- Fire can add fire damage.
- Electric can arc damage to a nearby enemy.
- Explosive can splash damage around the target.
- Mixed or duplicate element pairs derive simple combo behavior. Element mastery ranks increase proc chance and effect strength.

## GUI Behavior

- `on_gui_opened` detects vanilla `gun-turret`.
- The mod creates a frame in `player.gui.relative` anchored to `defines.relative_gui_type.turret_gui` on the right side.
- If relative anchoring fails, the panel falls back to `player.gui.left`.
- `on_gui_closed` destroys the panel and clears the remembered player/turret link.
- The panel includes a Veteran Core slot-style control for install/extract, dev core creation, naming, and floating-label toggle.
- The panel updates named stat elements and rebuilds the Evolution list every 60 ticks while the turret GUI remains open.
- The GUI depends on `flib >= 0.16.4` for shared Factorio-style slot, pusher, and panel styles.
- The XP bar uses a custom solid progressbar style defined in `data.lua`.
- Dev buttons can create a test core, grant quick levels, complete the active material project, or advance one selected element mastery milestone.

## Release Target

- Mod name: `turret_xp`
- Current version: `0.4.2`
- GitHub repository: `atyrode/turret_xp`
- Factorio Mod Portal title: `Turret XP`
