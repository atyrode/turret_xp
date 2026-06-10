# Project Brief

`turret_xp` is a Factorio 2.0 mod that adds progression to vanilla gun turrets.

The first playable releases should make progression visible and testable: selected gun turrets earn XP from combat through installed Veteran Cores, gain levels, display current progress and combat stats inside or alongside the vanilla turret GUI, and evolve through simple point and material choices.

## V0.4.0 Scope

- Track XP, level, kills, kill credit, lifetime damage, total XP, and evolution choices per vanilla `gun-turret`.
- Award XP from damage dealt by gun turrets and proportional kill credit.
- Provide runtime-global settings for XP per damage, XP per kill credit, base level XP, and level XP growth.
- Extend the vanilla gun turret GUI with a Turret XP panel.
- Show HP, shooting speed, range, loaded ammo, estimated ammo damage, estimated DPS, kills, damage, current level, and XP to next level.
- Use Factorio Library (`flib`) GUI styles and follow Factory Planner-style rich text info markers where appropriate.
- Replace the experimental skill tree with a five-section Evolution list.
- Let core upgrades be allocated infinitely for one point per rank.
- Unlock the first element at level 10 through a material project.
- Unlock a free specialization choice at level 20.
- Unlock powerful augments at level 30 with point costs that double each rank.
- Unlock a second element and automatic combo identity at level 40.
- Add dev buttons for quick level grants and material-project completion while playtesting.
- Package and publish as version `0.4.0` so the mod can be installed from the Factorio Mod Portal.

## Non-Goals For V0.4.0

- Do not support laser, flamethrower, artillery, or modded turret prototypes yet.
- Do not persist mined turret XP through item pickup yet.
- Do not add custom art or new item prototypes yet.
- Do not reintroduce the scrollable skill-tree canvas until a reliable interaction model is confirmed.

## V0.4.1 Scope

- Follow up the V0.4.0 playtest release with chip-based progression and GUI fit fixes.
- Add a craftable, non-stackable Veteran Core item that stores progression as item tags.
- Keep ordinary gun turrets stackable and progression-free until the player installs a core.
- Let the player extract a core and install it into another turret, moving XP, upgrades, element projects, custom name, and label preference.
- Return or spill the core when a turret is mined.
- Let a core profile display an optional floating `name (lvl N)` label above its current turret body.

## V0.4.2 Scope

- Make specialization choices change real turret stats through hidden gun-turret prototype variants.
- Add Sniper, Machine Gun, Bulwark, and Brawler turret bodies generated from multipliers on vanilla turret range, cooldown, damage modifier, health, and rotation speed.
- Revert specialized bodies back to the normal gun turret when the Veteran Core is extracted.
- Replace exponential level scaling with linear per-level scaling.
- Replace doubling augment costs with one augment point every ten levels.
- Remove material deposit buttons and consume the matching carried element resource automatically during open-panel playtesting.
- Add first-pass element fuel and visual feedback for bounce, double shot, fire, electric, explosive, and combo effects.

## V0.4.3 Scope

- Replace player-inventory material feeding with a real Veteran Core feeder inventory entity.
- Create the feeder next to the turret when a Veteran Core is installed, and show its status in the Evolution panel.
- Consume element unlock materials and element fuel from the feeder over time, even when the turret GUI is closed.
- Destroy the feeder and spill leftover feeder contents when the core is extracted or the turret is mined.

## V0.4.4 Scope

- Fix fresh Veteran Core installation after the feeder release.
- Remove level-scaled progression recalculation from normal combat damage.
- Add user respec and dev reset controls.
- Polish allocation button visuals and hover text.

## V0.4.5 Scope

- Make the Veteran Core control behave more like an inventory slot while preserving tagged profile data.
- Add floating label color, size, and level-suffix controls.
- Compact dev controls and remove redundant installed-core profile id text from the panel.

## V0.4.6 Scope

- Remove the visible adjacent feeder chest from play.
- Keep material progression inserter-fed by using an invisible hidden input colocated with the turret.
- Forward inserter-fed ammo from the hidden input into the turret ammo inventory so normal turret ammo logistics still work.
- Remove feeder status from the Evolution panel.
- Standardize floating labels to the larger readable size, keep color and level-suffix controls, and move labels higher above the turret.
- Polish core upgrade rows, allocation button styling, material requirement icons, and no-ammo damage text.
- Replace Longshot and Piercing augments with Double Shot and Veteran Training.

## V0.4.7 Scope

- Fix hidden-input ammo detection by using `prototypes.item` instead of `game.item_prototypes`.
- Add a prototype-backed Range augment with up to 20 ranks.
- Generate specialization bodies from multipliers on vanilla turret stats instead of fixed flat stat assignments.
- Increase first element unlock material costs by 10x.
- Replace post-unlock element mastery ranks with an element fuel buffer consumed by element combat effects.
- Put the name field and label controls on one row and lower the floating world label from the 0.4.6 offset.

## V0.6.0 Scope

- Treat the release as the first playable Veteran Core turret playthrough.
- Hide dev controls by default and add `/turret-xp-dev` to toggle them for testing.
- Rework unlocked element fuel into a coherent furnace-like burner: inserters fill to capacity, the hidden input closes at the cap instead of holding ghost excess, one item burns for 30 seconds, and element effects run while burning.
- Add element mastery ranks that spend regular core points after unlock.
- Show active custom stats only when present, with specialization multipliers next to affected values.
- Preserve Evolution list context after allocating points by scrolling back to the clicked row.
- Split naming and floating-label controls into compact rows that fit the attached turret panel.
- Show explicit technical effect text for augments and specialization choices.
- Fix killed-target runtime crashes in upgrade visual feedback.
- Enlarge allocation controls so the `+` button is not cropped.

## V0.6.1 Scope

- Patch the first playable line after fuel/proc/platform feedback.
- Add formula-style stats for additive bonuses and specialization multipliers.
- Add Luck as a proc-odds augment.
- Make Double Shot and elemental impacts clearer through lightweight visual feedback.
- Make bounced hits able to proc element effects, including Electric arcs from the bounced impact.
- Keep hidden element fuel capped without buffering excess valid fuel.
- Support explicit Veteran Core selection from a space-platform hub inventory and sending installed cores back to that hub.

## V0.6.2 Scope

- Patch first-playable balance and readability.
- Reduce combat XP gained by turrets fighting on space-platform surfaces to 10% of normal without changing displayed raw damage or kill-credit stats.
- Add clear delimiters between choices inside the Evolution sections.

## V0.7.0 Scope

- Start the next playtest line with target-aware combat XP instead of only surface-aware XP.
- Make asteroids and asteroid chunks low-XP targets so stationary space-platform asteroid defense does not level Veteran Cores too quickly.
- Keep raw lifetime damage, kill credit, and kills unchanged while applying target and platform multipliers only to XP counters.
- Weight kill-credit XP by target type and health so small enemies are not overvalued and larger enemies, worms, and spawners are more meaningful.
- Add optional `bullet-trails` support for scripted bounce, double-shot, and element tracers when the dependency is installed.
- Reuse vanilla electric, fire, explosion, and weapon sound prototypes for element feedback.
- Keep hidden turret body variants for real specialization and Range stats, but sync their gun-turret damage research modifier at runtime instead of copying every technology effect onto every variant.

## V0.7.1 Scope

- Patch early 0.7 playtest UX issues without changing the progression model.
- Prevent open-turret specialization, Range, install, extract, respec, and reset actions from moving the vanilla turret GUI back to its default location.
- Keep element feeder targets present but closed at fuel cap so inserters can resume feeding when element fuel burns below capacity.
- Make base upgrade rows faster to use with `- value +` controls and Shift-click batches.
- Add RGB floating-label color controls because Factorio runtime GUI exposes sliders but not the native train color picker widget.
- Make Double Shot visually and mechanically prefer a simultaneous second target.

## V0.7.2 Scope

- Patch hidden element feeding after playtesting showed overlapping turret/feed inputs were unreliable.
- Manage nearby inserter drop targets and temporary filters so element material inserters feed the hidden input only while needed.
- Restore inserters to the turret target when the element input is full or not needed, preserving ammo logistics.
- Stop normal routing from spilling unexpected items around the turret.
- Right-align the `- value +` core upgrade controls.
- Hide floating-label color controls until the label is enabled, and keep preset color cycling distinct from custom RGB edits.
- Add an opt-in bound veteran turret item so a player can mine and place a chosen turret/core pair as one quick-move item, while keeping the default separate core/turret behavior available through Unbind.

## V0.8.0 Scope

- Keep the turret panel attached to the vanilla turret GUI, but split it into two main columns.
- Keep core identity, XP, dev controls, and stats in the left column.
- Move all Evolution choices to the right column so progression has more room without relying on its own scroll pane in normal play.
- Fix mixed-element fuel feeding so first and second element resources are both requested and stale inserter filters refresh to the currently needed item.
- Aggregate duplicate pure-element stat summary rows while keeping the pure-element combo identity.
- Package the root `thumbnail.png` so the Mod Portal release has a thumbnail.
- Expand the headless regression suite before publishing 0.8.0.

## V0.8.1 Scope

- Patch core-panel overflow by moving installed-core action buttons to their own row.
- Hide `Show level` until `Show name` is enabled.
- Preserve display-panel-style floating labels for custom RGB colors through generated hidden label-panel variants.
- Make Fire + Explosive and other mixed-element fuel feeding use one current-priority inserter filter at a time.
- Avoid redundant feeder inventory bar writes while keeping the input open whenever any progression material is still needed.

## V0.9.0 Scope

- Generate prototype-backed specialization and Range variants in `data-final-fixes.lua` so Turret XP inherits final modded vanilla gun-turret stats before applying its own modifiers.
- Keep the attached two-column turret panel wide but stable, with bounded scrollable stats and Evolution areas instead of content-driven top-level resizing.
- Replace the global Respec flow with per-section reset/deallocation controls and embedded `- value +` rank controls where practical.
- Show clearer Evolution section headers, right-side status text, delimiters, and technical element previews before a player chooses an element.
- Extend the headless suite for modded base range, individual section resets, and deterministic combat kill tracking.
- Before redesigning the Veteran Core slot into a more vanilla-like inventory slot or switching to a full custom GUI, inspect large GUI-heavy mod sources and maintained GUI/inventory libraries for proven patterns worth reusing.

## V0.9.1 Scope

- Refactor the runtime and data-stage implementation into focused modules while preserving the existing save schema and gameplay behavior.
- Keep `control.lua`, `data.lua`, and `data-final-fixes.lua` as small entrypoints.
- Narrow the attached two-column panel and keep Evolution content inside its scroll-pane width.
- Make selected element choices clearly changeable through section-level actions, matching specialization.
- Treat a fuller Veteran Core slot as a future scripted, tag-preserving UI feature rather than claiming native vanilla inventory-slot support.

## V0.9.2 Scope

- Fix bound veteran turret placement so bound quick-move items cannot be selected by ordinary gun-turret replacement ghosts.
- Keep Bind/Unbind visually attached to the Veteran Core slot row.
- Keep selected, fueled element panels inside the Evolution scroll-pane width and keep their `Change` action visible.
- Reformat element choices as compact readable cards with distinct effect, cost, and combo information.

## V0.9.3 Scope

- Replace the nested right-column layout with a static Evolution summary header and one scrollable section body.
- Derive Evolution section, row, and label widths from one right-column viewport model instead of independently tuned constants.
- Keep element choice Start buttons and fueled element mastery controls inside their cards.
- Remove duplicate Core/Augment point summaries from section bodies.

## V0.9.4 Scope

- Keep element choice Start buttons on the first card row with the element icon and name.
- Bound element-card child rows to the card's actual padded content width.
- Separate element effect and cost rows visually.
- Remove redundant element-section status text when the cards already explain the material unlock.

## V0.9.5 Scope

- Color specialization multipliers and stat-summary multipliers green for benefits and red for tradeoffs.
- Add breathing room between Evolution section headers and option rows.
- Add balanced margins around Evolution section frames and between adjacent sections.
- Compact the Veteran Core name controls so `Show` sits beside the name field, and reveal color/level controls only when the floating label is enabled.
- Match specialization option cards to element option cards, with icon/title rows, separated descriptions, and technical multiplier rows.
- Keep element choice `Start` actions on the cost row where the material requirement is shown.

## V0.9.6 Scope

- Use one always-visible Evolution header Reset for all Evolution choices while keeping per-section `Change` actions for focused element and specialization edits.
- Keep element and specialization action buttons right-aligned without forcing unrelated description text to reserve button space.
- Preserve visible right-side margins inside the Evolution column.
- Show baseline crit chance and crit damage in the stats summary.
- Move the floating-label `Level` option under the RGB color picker.

## V0.9.7 Scope

- Add a capped real Max HP augment through hidden turret variants.
- Add slow Ammo Recovery that restores the current or last remembered ammo item over time.
- Keep the implementation honest about Factorio constraints: Max HP is capped to avoid unbounded variants, and ammo recovery creates ammo items rather than repairing ammo durability.

## V0.9.8 Scope

- Increase element fuel capacity to 100 stored items per active element so powered turrets can buffer a meaningful operating window.
- Reformat the Evolution header summary with white labels and colored values for faster scanning.
- Keep stat and Evolution value coloring focused on numeric fragments only, with elemental damage amounts using element colors.
- Add secondary specialization identity so Sniper boosts Crit Damage, Machine Gun boosts Ammo Recovery, Bulwark boosts Regeneration, and Brawler boosts Lifesteal.
- Prevent wrong hidden-input items from leaving element projects stuck, and ensure electric arc visuals expire cleanly.

## V0.10.0 Scope

- Add Resistance as a core upgrade for survivability without adding another hidden prototype variant axis.
- Treat Resistance as scripted mitigation on non-lethal incoming damage after Factorio's normal resistance calculation.
- Tune Brawler down to a slower, less explosive close-range role: x3 damage and x0.5 fire rate, with lifesteal as the identity hook.
- Move specialization to level 10, first element to level 20, sub-specialization to level 40, and second element/combo to level 50.
- Replace ongoing element fuel buffers with free element picks at unlock and material-fed rank projects for future element growth.
- Add two sub-specialization branches per primary role so level-40 builds can push further into range, crits, sustained fire, durability, or lifesteal.
- Keep bound veteran turret moves lossless under full inventories and placement-helper mods: tagged bound items preserve the core profile and saved ammo, while placement-time ammo is refunded before the saved snapshot is restored.
- Keep the long-term direction open to reducing hidden prototype usage for HP and Range if an equally real and Factorio-compatible approach is found.

## V0.10.1 Scope

- Rebalance Regeneration from a flat HP/s trickle into 0.1% current max HP per second per rank.
- Keep Bulwark and Guardian regeneration multipliers meaningful by applying them on top of max-health-based regeneration.
- Fix small UI fit issues from V0.10.0, including the truncated unlocked-element `Upgrade` button.

## V0.10.2 Scope

- Replace manually started element rank projects with always-visible passive next-rank material progress on selected elements.
- Add Toxic as a poison-capsule-fed element with stacking poison damage and slowdown feedback.
- Add tracked burn damage to Fire, critical-hit visual feedback, and stronger double-shot trail feedback.
- Keep delayed Fire/Toxic damage tied to turret XP, kill contribution, and lifesteal.
- Let mixed-element feeder inserters expose all currently needed element materials instead of only one project resource.

## V0.10.3 Scope

- Patch bound turret ammo movement so mining and replacing a bound veteran turret cannot duplicate or lose its stored ammo snapshot.
- Add turret-source projectile range compatibility for K2/K2SO-style realistic rifle ammo, without changing player-fired ammo behavior.
- Show a lightweight in-world level-up popup above a turret when XP progression raises its installed core level.

## Open Product Questions

- What final mod name, short description, portal category, and sober Factorio-native portal image best communicate Veteran Core turret progression once the core loop stabilizes?
- Which parts of the long-term progression direction in [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) should ship first: archetype branches, material gates, element slots, combo nodes, element ranks, or infinite mastery?
- Should destroyed turrets destroy their installed core, drop a damaged core, or have a recovery chance?
- Should XP eventually include waves survived, ammo consumed, or other behavior beyond damage and kill credit?
- Does the hidden turret-tile input plus managed inserter targeting/filtering feel reliable with practical inserter layouts, or does the material input need a clearer visible design later?
