# Project Spec

## Version 0.6.2

V0.6.2 is the current first playable patch for a full Veteran Core turret loop after initial playtest feedback. It keeps the vanilla turret GUI as the main interaction and keeps the five-section Evolution list from V0.4.0. Turret identity is an explicit player choice through a movable Veteran Core item, while ordinary gun turrets stay stackable and inventory-friendly. Installing a core creates an invisible inserter-fed input on the turret tile only while element materials or fuel are needed, avoiding a visible fake chest beside the turret while routing ammo back into the turret. Specialization and Range augment choices swap the current turret into hidden gun-turret variants with prototype stat changes. Space-platform combat XP is weighted down to 10% of normal combat XP.

Earlier 0.4.x releases were published to the Factorio Mod Portal to validate the UI and Veteran Core foundations before this first playable line.

## Runtime Behavior

- State lives under `storage.turret_xp`.
- Turret host records are keyed by turret entity `unit_number`.
- Durable progression profiles are keyed by Veteran Core ID under `storage.turret_xp.chips`.
- A turret without an installed Veteran Core has no XP/evolution profile and does not gain progression.
- New core profiles start at level 1 with zero XP, kills, kill credit, damage, total XP, custom name, display-label flag, and empty evolution choices.
- Veteran Cores are non-stackable `item-with-tags` items. Extracted cores serialize their profile into item tags.
- On space platforms, Veteran Cores stay in the platform hub inventory until the player chooses a specific core from the opened turret panel. This avoids inserter ambiguity when multiple cores exist and keeps normal inserters focused on ammo/material feeding.
- XP is derived from XP-weighted lifetime damage, XP-weighted kill credit, runtime-global XP settings, core XP upgrade ranks, and optional dev XP.
- Displayed damage and kill credit remain raw combat totals. Separate `xp_damage` and `xp_kill_credit` counters preserve XP balance, with space-platform combat adding only 10% of its raw damage or kill credit into those XP counters.
- Derived level progress is cached after sync so normal combat only applies new XP deltas instead of recalculating every previous level.
- Default damage XP is `0.02` XP per final damage point.
- Default kill-credit XP is `25` XP per full kill credit.
- Combat by turrets on a space-platform surface applies a `0.1x` multiplier before damage or kill credit reaches the XP counters.
- Default level XP starts at `100` and grows linearly. The default `1.65` growth setting means each level adds `65%` of base XP to the next requirement.
- Kill credit is split proportionally by damage contribution so turrets are not fully denied XP when another source lands the final hit.
- Core points equal `level - 1 - spent_core_points`.
- Core upgrade ranks cost one point each and can be purchased repeatedly.
- The Respec button refunds core upgrades, element mastery, augment point allocations, element choices, element fuel, material projects, specialization, and hidden feeder contents.
- Powerful augment ranks unlock at level 30, cost one augment point each, and earn one augment point every ten levels.
- Element choices do not cost points. They start a single-resource material project that permanently assigns the element when complete.
- Material projects and element fuel consume from the installed core's hidden turret-tile input, not from the player inventory.
- Inserter-fed ammo that lands in the hidden input is moved into the turret ammo inventory; unrelated non-ammo items are spilled back out.
- Unlocked elements use their matching resource as burner fuel. Inserters can fill stored fuel up to the burner capacity, the hidden input closes instead of storing excess valid fuel, and one stored fuel item burns for 30 seconds to power that element.
- A second-element material project and already-unlocked element fuel can both be valid hidden-input targets when both are needed.
- Unlocked elements start at mastery rank 1. Further element mastery ranks cost 5 regular core points each and improve proc chance, damage efficiency, and electric arc count.
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
- The core slot supports tag-preserving cursor transfer and swap behavior for installed/carried Veteran Cores.
- If the turret is mined, the normal gun turret item returns through vanilla behavior and the mod separately returns/spills the Veteran Core.
- If a turret is mined through a space-platform mining event, the mod attempts to return the Veteran Core to the event mining buffer before spilling it.
- The profile can be named. If the player enables the label, the world label renders above the current turret body, with configurable color and optional level suffix.
- Installing a core creates a hidden `turret-xp-veteran-feeder` inventory entity colocated with the turret.
- The hidden feeder is not a player-facing container. It accepts inserter drops, forwards ammo into the turret, and exists only while resources are needed for the current element project or unlocked element fuel.
- Extracting or mining a core destroys the hidden feeder and spills any leftover feeder contents.

## Evolution Sections

- `Core upgrades`: unlocked from level 1. Includes Damage, Regeneration, Lifesteal, Crit Chance, and Crit Damage.
- `First element`: unlocks at level 10. Starts a material project for Explosive, Fire, or Electric.
- `Specialization`: unlocks at level 20. Picks Sniper, Machine Gun, Bulwark, or Brawler for free.
- `Powerful augments`: unlocks at level 30. Includes Bullet Bounce, Double Shot, Luck, Veteran Training, and Range. Augment points are earned every ten levels.
- `Second element and combo`: unlocks at level 40. Starts a second material project and derives a combo from the two selected elements.

## Combat Effects

- Damage adds flat physical bonus damage per shot.
- Regeneration adds passive turret repair.
- Lifesteal heals the turret from damage dealt.
- Crit Chance improves critical hit chance.
- Crit Damage improves critical hit damage.
- Sniper, Machine Gun, Bulwark, and Brawler are real turret body variants generated from multipliers on vanilla gun turret range, cooldown, damage modifier, max HP, and rotation speed.
- Bullet Bounce can damage a nearby enemy.
- Double Shot can apply a second physical hit to the same target.
- Luck increases crit, bounce, double-shot, and element proc odds by a small relative amount per rank.
- Veteran Training increases combat XP gained from damage and kill credit.
- Range adds +1 attack range per rank, up to rank 20, through hidden prototype-backed turret variants. Specialization range multipliers apply after Range augment ranks.
- Fire can add fire damage.
- Electric can arc damage to a nearby enemy.
- Explosive can splash damage around the target.
- Mixed or duplicate element pairs derive simple combo behavior. Element effects only run while that element has fuel burning.
- Bounced hits run the same element proc path as the original hit, so Electric arcs can originate from the bounced impact.

## GUI Behavior

- `on_gui_opened` detects vanilla `gun-turret`.
- The mod creates a frame in `player.gui.relative` anchored to `defines.relative_gui_type.turret_gui` on the right side.
- If relative anchoring fails, the panel falls back to `player.gui.left`.
- `on_gui_closed` destroys the panel and clears the remembered player/turret link.
- The panel includes a Veteran Core slot-style control for install/extract, naming, floating-label toggle, label color, and optional level suffix.
- When the opened turret is on a space platform, the Veteran Core panel also lists tagged cores found in that platform's hub inventory. Each row represents the exact hub inventory slot, with level/kills/damage summary and an install button. Installed platform cores can be sent back to the same hub if it has room.
- The Evolution panel does not show feeder status; material project panels show the current requirement and progress. Unlocked element panels show a resource slot, burn progress, stored fuel count, and burner state.
- Stats show formula-style rows only when an additive value, multiplier, or expected proc output affects the displayed number.
- Evolution choices inside the unlocked list sections use horizontal delimiters to improve readability without adding extra explanatory text.
- The panel updates named stat elements and rebuilds the Evolution list every 60 ticks while the turret GUI remains open.
- Point allocation refreshes scroll the rebuilt Evolution list back to the clicked row so spending points does not jump back to the top.
- The GUI depends on `flib >= 0.16.4` for shared Factorio-style slot, pusher, and panel styles.
- The XP bar uses a custom solid progressbar style defined in `data.lua`.
- Dev buttons are hidden by default. `/turret-xp-dev` toggles controls that can create a test core, grant quick levels, complete the active material project, fill one selected element fuel buffer, or reset the installed core to a fresh zero-XP state.

## Release Target

- Mod name: `turret_xp`
- Current version: `0.6.2`
- GitHub repository: `atyrode/turret_xp`
- Factorio Mod Portal title: `Turret XP`
