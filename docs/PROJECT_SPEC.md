# Project Spec

## Version 0.10.4

V0.10.x keeps the vanilla turret GUI as the main interaction and presents Turret XP as two narrower attached columns: core identity, XP, dev controls, and scrollable stats on the left; a richer static Evolution summary header plus a bounded scrollable six-section Evolution workflow on the right. Turret identity is an explicit player choice through a movable Veteran Core item, while ordinary gun turrets stay stackable and inventory-friendly. Installed cores can optionally bind to their turret body for quick moves: mining a bound veteran turret returns one tagged placeable turret item instead of a separate turret plus core. Bound items place a hidden bound-only placeholder that is immediately converted into a real gun turret with the stored core profile, which keeps normal gun-turret replacement ghosts tied to the normal gun turret item. Installing a core creates an invisible inserter-fed input on the turret tile whenever selected elements need next-rank materials, avoiding a visible fake chest beside the turret while routing ammo back into the turret. Nearby inserters that are actually sourcing needed materials are pointed at the hidden input and can receive multiple active element filters at once. When input is not needed, inserters are restored to the turret target so ammo logistics keep behaving normally. Specialization and sub-specialization choices use hidden gun-turret variants with prototype stat changes generated in `data-final-fixes.lua`, so they inherit final base gun-turret edits from mods that run during `data-updates.lua`. Shield and Resistance are intentionally scripted instead of variant-backed: Shield absorbs non-lethal incoming damage before HP and recharges in small increments after a delay with no incoming damage, while Resistance refunds part of remaining non-lethal final incoming damage after Factorio's vanilla resistance calculation. Body swaps are queued until the turret GUI closes so Factorio does not reset the whole vanilla window position. Combat XP is weighted by surface and target type so asteroid defense, especially on space platforms, does not overlevel cores. The implementation is split into runtime modules under `scripts/control/` and data-stage modules under `prototypes/`.

## Runtime Behavior

- State lives under `storage.turret_xp`.
- Turret host records are keyed by turret entity `unit_number`.
- Durable progression profiles are keyed by Veteran Core ID under `storage.turret_xp.chips`.
- Save/profile compatibility is maintained for Mod Portal-published versions where practical. Runtime normalization upgrades older live profiles and tagged Veteran Core/bound turret item profiles into the current profile schema; unpublished local development-only shapes may be broken or discarded before a 1.0-style compatibility commitment.
- A turret without an installed Veteran Core has no XP/evolution profile and does not gain progression.
- New core profiles start at level 0 with zero XP, kills, kill credit, damage, total XP, custom name, display-label flag, and empty evolution choices.
- Veteran Cores are non-stackable `item-with-tags` items. Extracted cores serialize their profile into item tags.
- Bound veteran turrets are non-stackable placeable `item-with-tags` items that serialize the core profile and a small turret snapshot. They place a hidden bound-only placeholder entity first; build handling converts it into a real `gun-turret` before installing the profile.
- Newly created bound veteran turret stacks use hidden preview item/placeholder variants selected from the stored specialization and sub-specialization. This lets Factorio's native placement range preview match the specialization body that will be restored, while older generic or retired range-preview stacks remain a compatibility fallback until placed and mined again.
- Bound turret items carry their saved ammo snapshot. If another mod preloads ammo during placement, Turret XP reconciles that ammo against the saved snapshot: matching ammo satisfies the snapshot, while only excess or incompatible placement-time ammo is returned.
- Bound core detachment happens when mining-buffer conversion creates or spills the tagged bound turret item, not during the pre-mining snapshot. If the inventory cannot accept the bound item, the tagged bound turret is spilled rather than falling back to a separate Veteran Core path.
- On space platforms, Veteran Cores stay in the platform hub inventory until the player chooses a specific core from the opened turret panel. This avoids inserter ambiguity when multiple cores exist and keeps normal inserters focused on ammo/material feeding.
- XP is derived from XP-weighted lifetime damage, XP-weighted kill credit, runtime-global XP settings, core XP upgrade ranks, and optional dev XP.
- Displayed damage and kill credit remain raw combat totals. Separate `xp_damage` and `xp_kill_credit` counters preserve XP balance, with surface and target multipliers applied only to those XP counters.
- Derived level progress is cached after sync so normal combat only applies new XP deltas instead of recalculating every previous level. When an existing installed core gains enough XP to increase level, connected players on the turret's force see a short `Level up!` local flying-text popup above the entity.
- Default damage XP is `0.02` XP per final damage point.
- Default kill-credit XP is `25` XP per full kill credit.
- Combat by turrets on a space-platform surface applies a `0.1x` multiplier before damage or kill credit reaches the XP counters.
- Combat against asteroids or asteroid chunks applies an additional `0.2x` target multiplier before damage or kill credit reaches the XP counters.
- Unit kill-credit XP is weighted by target max health. Small enemies pay less than a full credit; large enemies pay more. Spawners and worms are treated as higher-value targets.
- Default level XP starts at `100` for level 0 to level 1 and grows linearly. The default `1.65` growth setting means each level adds `65%` of base XP to the next requirement.
- Kill credit is split proportionally by damage contribution so turrets are not fully denied XP when another source lands the final hit.
- Core points equal `level - spent_core_points`, so a level 10 core has 10 core points before spending.
- Core upgrade ranks cost one point each and can be purchased repeatedly unless the specific upgrade has a cap.
- Core upgrades and augments use embedded `- value +` controls. Element ranks are advanced through passive material progress instead of point spending or a separate upgrade-start click. The static Evolution header exposes one always-visible `Reset` action that clears all Evolution choices and refunds spent core/augment ranks while preserving XP, level, combat history, name, and binding. Element, specialization, and sub-specialization sections expose `Change` actions for focused local edits.
- Evolution rank controls use normal click for one rank, Shift-click for up to ten ranks, and Ctrl-click for all available points or all allocated ranks.
- Powerful augment ranks unlock at level 30, cost one augment point each, and earn one augment point every ten levels.
- Element choices do not cost points. When the matching level gate is unlocked, choosing an element permanently assigns rank 1 for free.
- Further element ranks always expose a single-resource material requirement for the chosen element. Those passive ranks consume from the installed core's hidden turret-tile input, not from the player inventory.
- Inserter-fed ammo that lands in the hidden input is moved into the turret ammo inventory. If an unrelated non-ammo item slips into the hidden input through a stale inserter hand or edge case, routing ejects that invalid stack instead of leaving element progress blocked.
- Mixed-element turrets request every selected element's currently needed material, so one turret can progress both elements without manually starting projects. Duplicate pure-element builds share one mastery rank and material progress track.
- Legacy active element projects, element fuel buffers, retired augment IDs, and old skill-tree ranks are compatibility inputs only; read-time normalization maps old Ballistics ranks to Damage, old Field Repairs ranks to Regeneration, and old XP-gain skills to Veteran Training. Current serialized profiles store selected elements plus `element_mastery[element_id].rank` and `delivered`, not legacy `skills`, `element_project`, or base `xp` artifacts.
- Unlocked elements start at rank 1. Higher ranks increase proc chance, damage efficiency, electric arc count, and Toxic poison scaling where applicable.
- Specialization unlocks at level 10 and is a free one-time choice.
- First element unlocks at level 20 and is a free one-time choice.
- Sub-specialization unlocks at level 40 and branches the chosen primary specialization into one of two stronger identities.
- Second element unlocks at level 50 and creates a combo identity with the first element.
- Specialization swaps the turret body between vanilla `gun-turret` and hidden `turret-xp-gun-turret-*` variants. Removing the Veteran Core returns the turret body to vanilla `gun-turret`.
- Hidden turret variants are required for real specialization and sub-specialization changes to per-turret range, cooldown, damage modifier, max HP, and rotation speed. They are generated in `data-final-fixes.lua` after all mods' `data-updates.lua` stages, so role multipliers apply to the final modded base turret instead of an early vanilla copy. Their force gun-turret damage research modifier is synced at runtime from vanilla `gun-turret` instead of being injected into technology effect lists. When the turret GUI is open, body swaps are deferred until close to avoid moving the vanilla entity GUI back to its default location.
- If a compatible mod gives gun-turret ammo a projectile `max_range` lower than Turret XP's generated turret range, `data-final-fixes.lua` adds or patches a turret-source ammo type with enough projectile range for veteran turrets. Non-turret ammo behavior stays on the original default/source-specific ammo type. This is mainly for K2/K2SO realistic rifle ammo, where the turret can otherwise target farther than the physical bullet can fly.
- Ammo Productivity stores the last loaded magazine item, quality, and current ammo count on the Veteran Core. Each rank adds 1% raw magazine productivity, then runtime converts raw productivity into effective refill progress with `raw / (raw + 1)` so investment can scale indefinitely without reaching free ammo. Spent ammo fills a purple horizontal progress bar in its own stat row after Ammo, and every full bar restores +1 ammo inside the current loaded magazine when there is room. The refill is capped by the ammo prototype's normal magazine size, does not overfill `11/10`, and does not create full ammo items. Because Factorio does not expose a direct turret-fired event, runtime logic observes loaded-magazine ammo deltas when the turret deals damage.
- Mined unbound turrets return the installed Veteran Core as a separate item or spill it if there is no inventory room.
- Mined bound turrets remove the vanilla gun-turret mining output and return a single bound veteran gun turret item when possible. The bound item restores the core profile, bound state, turret quality, health ratio, and loaded ammo when placed again through the hidden placeholder conversion path.
- Destroyed turrets currently destroy the installed core/profile.

## Veteran Core Behavior

- Recipe name: `turret-xp-veteran-core`.
- Prototype type: `item-with-tags`.
- Stack size: `1`.
- Unlock: added to the vanilla `military` technology when present.
- First draft recipe: `20` electronic circuits, `10` steel plates, `40` copper cable, and `2` repair packs.
- Installing a carried core removes the item and binds its profile to the opened gun turret.
- Extracting a core returns the profile item to the player inventory.
- The core slot supports tag-preserving cursor transfer and swap behavior for installed/carried Veteran Cores. It is a scripted slot-like GUI control, not a native extra Factorio inventory slot.
- If an unbound turret is mined, the normal gun turret item returns through vanilla behavior and the mod separately returns/spills the Veteran Core.
- If an unbound turret is mined through a space-platform mining event, the mod attempts to return the Veteran Core to the event mining buffer before spilling it.
- `Bind` marks the installed core and turret body as one quick-move item for mining and placement. `Unbind` returns to the default separate turret/core mining behavior.
- The profile can be named. If the player enables the label, the world label renders above the current turret body, with configurable color and optional level suffix.
- Label color can be chosen through presets or RGB sliders stored on the Veteran Core profile. Color controls are hidden until the compact `Show` label checkbox beside the name field is enabled, and the `Level` checkbox sits below the RGB picker. Preset cycling records a preset name, while RGB slider edits mark the color as custom. Floating labels render with `rendering.draw_text` so custom RGB colors apply directly without generated label-color prototypes.
- Installing a core creates a hidden `turret-xp-veteran-feeder` inventory entity colocated with the turret.
- The hidden feeder is not a player-facing container. It accepts inserter drops only while selected element ranks need material, forwards ammo into the turret if ammo lands there, and coordinates nearby inserter drop targets/filters so material feeders behave like recipe feeders without breaking normal ammo inserters. Passive element progress exposes a bounded input buffer so inserters can feed smoothly between routing ticks.
- Extracting or mining a core destroys the hidden feeder and spills any leftover feeder contents.

## Evolution Sections

- `Core upgrades`: available from level 0 once a Veteran Core is installed. Includes Damage, Shield, Resistance, Ammo Productivity, Crit Chance, and Crit Damage.
- `Specialization`: unlocks at level 10. Picks Sniper, Machine Gun, Bulwark, or Brawler for free.
- `First element`: unlocks at level 20. Picks Explosive, Fire, Electric, or Toxic for free at rank 1; later ranks use passive material feeding.
- `Powerful augments`: unlocks at level 30. Includes Regeneration, Bullet Bounce, Double Shot, Shield on Hit, Luck, and Veteran Training. Augment points are earned every ten levels.
- `Sub-specialization`: unlocks at level 40. Picks one of two branch identities for the current specialization.
- `Second element and combo`: unlocks at level 50. Picks a second element for free at rank 1 and derives a combo from the two selected elements.

## Combat Effects

- Damage adds flat physical bonus damage per shot.
- Shield adds 10 shield per rank, absorbs incoming damage before turret HP, starts recharging in small increments after a short delay without incoming damage, and shows a nine-pip blue shield bar below Factorio's native HP bar while relevant. Changing Shield ranks changes capacity without refilling current shield; current shield is only clamped down when the new capacity is lower. Because Factorio applies damage before scripts run, a single hit that exceeds the turret's native HP may still be lethal before Shield can respond.
- Regeneration is an augment that adds passive turret repair equal to 1% of current max HP per second per rank, before specialization regeneration multipliers.
- Resistance mitigates 0.25% final incoming damage per rank, capped at 60%, by refunding health after non-lethal hits.
- Ammo Productivity adds 1% raw magazine productivity per core rank. Effective refill progress uses `raw / (raw + 1)`, then spent ammo fills the custom ammo productivity bar; a full bar restores +1 ammo inside the current loaded magazine up to that magazine's normal capacity.
- Shield on Hit is an augment that grants shield equal to 4% of gun-turret damage dealt per rank, capped by the current Shield capacity.
- Lifesteal is currently only granted by the Brawler specialization. It heals Brawler HP for 10% of gun-turret damage dealt.
- Crit Chance improves critical hit chance.
- Crit Damage improves critical hit damage.
- Sniper, Machine Gun, Bulwark, and Brawler are real turret body variants generated from multipliers on vanilla gun turret range, cooldown, damage modifier, max HP, and rotation speed.
- Level-40 sub-specializations add a second identity layer. Sniper can choose Deadeye or Overwatch; Machine Gun can choose Shredder or Sustained Fire; Bulwark can choose Bastion or Guardian; Brawler can choose Executioner or Vampire.
- Bullet Bounce can damage a nearby enemy.
- Double Shot can apply a second physical hit to a nearby second target when available, or to the original target when it is alone.
- Luck increases crit, bounce, double-shot, and element proc odds by a small relative amount per rank.
- Veteran Training increases combat XP gained from damage and kill credit.
- Fire can add fire damage and tracked burn damage over time.
- Electric can arc damage to a nearby enemy.
- Explosive can splash damage around the target.
- Toxic can stack tracked poison damage over time and apply vanilla slowdown-sticker feedback where the runtime accepts it.
- Mixed or duplicate element pairs derive simple combo behavior. Active elements run when their element rank is above zero.
- Bounced hits run the same element proc path as the original hit, so Electric arcs can originate from the bounced impact.
- If Bullet Trails is installed, scripted bounce, double-shot, and element feedback can use its beam-like trail entities. Without it, the mod falls back to lightweight local render lines.
- Electric, fire, explosive, toxic, crit, bounce, and double-shot feedback reuse vanilla prototype effects, optional Bullet Trails trail entities, and safe render fallbacks where practical.

## GUI Behavior

- `on_gui_opened` detects vanilla `gun-turret`.
- The mod creates a `flib.gui`-built frame in `player.gui.relative` anchored to `defines.relative_gui_type.turret_gui` on the right side.
- If relative anchoring fails, the panel falls back to `player.gui.left`.
- `on_gui_closed` destroys the panel and clears the remembered player/turret link.
- The attached frame uses two bounded main columns sized to avoid covering more screen than needed. The left column contains core identity, XP, dev controls, and a scrollable stats area. The right column is a shallow content pane with a static Evolution summary header above one scroll pane. Its section and row widths derive from the right-column viewport so content reserves scrollbar space without layering independent margins, and section frames use balanced margins inside the scroll body.
- The panel includes a Veteran Core slot-style control for install/extract, naming, optional quick-move binding, floating-label toggle, label color swatch/picker trigger, and optional level suffix. Bind/Unbind sits on the same row as the installed core slot so the quick-move state reads as part of that core-slot interaction. Installed-core naming and floating-label controls render as a compact shallow form: the name row keeps `Show` beside the text field, and color controls appear below only while the floating label is enabled as one row with a small square swatch, picker trigger, and `Level` suffix toggle.
- When the opened turret is on a space platform, the Veteran Core panel also lists tagged cores found in that platform's hub inventory. Each row represents the exact hub inventory slot, with level, specialization, neutral preview stats, and an install button. Installed platform cores can be sent back to the same hub if it has room.
- The Evolution column does not show feeder status; unlocked element panels always show the current rank, technical effect, next material requirement, and passive progress bar. Element choices use compact card-style rows with icon/title, full-width descriptions, separator, and technical value rows. Specialization and sub-specialization choices use card rows with icon/title first, full-width flavor text with the `Pick` action justified right, then a full-width vertical technical stat table. Unlocked element panels must not expand under the scrollbar.
- Stats rows are grouped under distinct native subheader strips for identity, defense, offense, ammo, history, and active effects while keeping final values visible in the panel. Additive/multiplier formulas live in the stat-name info hover, while quality-specific HP and range variants live on the quality diamond beside the value.
- The stats scroll pane uses Factorio's `auto-and-reserve-space` scroll policy so the scrollbar lane is reserved before the stat list becomes tall enough to scroll; value text should not shift or render underneath the scrollbar when extra rows appear.
- Empty-turret Veteran Core selection uses the whole anchored panel width. The picker has an `All` checkbox plus base/specialization checkboxes above a Factorio-style sortable table; selecting any specific filter unticks `All`, and clearing the last specific filter snaps back to `All`. Name, Level, HP, Attack, and Range table headers cycle ascending, descending, and no explicit sort while showing a compact core table-header arrow sprite for the active direction. Core rows use native table row styling, a colored specialization line, right-aligned preview stats, and an exact-slot `+` install action. Lifetime kills/damage remain history/detail data rather than picker columns.
- Stats always show baseline Crit Chance and Crit Damage in the Offense group for context, then use base-plus-bonus formatting when those core upgrades are ranked.
- Stat, upgrade, augment, specialization, sub-specialization, element, and material-count values color numeric fragments only. Unchanged values remain neutral, beneficial deltas use a muted green, harmful deltas use a muted red, and units/descriptive words remain neutral; elemental damage amounts use fire, electric, explosive, or toxic colors for the numeric amount.
- Duplicate pure-element builds show one active element stat row plus the combo identity instead of duplicate stat rows.
- Evolution choices inside the unlocked list sections use horizontal delimiters and section headers with right-side point/status text to improve readability without adding extra explanatory text. Locked Evolution sections keep the same section title/header rhythm and show their level gate as right-side status.
- Embedded Evolution rank steppers use one consistent `- value +` control shape and tooltips that describe normal, Shift-click, and Ctrl-click rank amounts without adding extra panel text.
- The panel updates named stat elements and rebuilds the Evolution list every 60 ticks while the turret GUI remains open.
- Point allocation refreshes rebuild the Evolution column in place; prototype body swaps remain deferred while the turret GUI is open so the whole vanilla window does not jump back to its default position.
- The GUI depends on `flib >= 0.16.4` for shared Factorio-style slot, pusher, drag-handle, panel styles, and the top-level shell builder.
- Future GUI replacement work should keep `flib` as an accepted foundation and move toward custom Turret XP panel/dialog/section modules rather than growing one generic panel file. The target is an anchored polished Factorio-native interface with domain widgets for Veteran Cores, stats, Evolution choices, element progress, and action toolbars.
- The XP bar uses a custom solid progressbar style defined by the data-stage style prototype module.
- Magazine and Ammo are separate stat rows: Magazine shows the loaded magazine stack, Ammo shows current rounds in the active magazine, and the Ammo Productivity bar uses a purple custom style on Factorio's native horizontal progressbar widget in a separate stat row immediately after Ammo.
- While a turret GUI is open, the XP/stat area refreshes on the shield recharge cadence so Shield and Ammo Productivity progress can visibly move more smoothly than the slower full Evolution-column refresh.
- Dev buttons are hidden by default. `/turret-xp-dev` toggles controls that can create a test core, grant quick levels, complete the next passive element material rank, or reset the installed core to a fresh zero-XP state.

## Release Target

- Mod name: `turret_xp`
- Current version: `0.10.4`
- GitHub repository: `atyrode/turret_xp`
- Factorio Mod Portal title: `Turret XP`
- Pre-publish validation: pull requests and `main` run GitHub Actions package validation for package-payload changes, including a stale generated-public-assets check. Headless tests run in CI when Mod Portal download credentials are configured and runtime/test paths change. A published GitHub Release/tag named `v<info.json version>` triggers the release workflow, which validates the tag, verifies generated public assets, runs the headless suite, attaches the package, and publishes to the Mod Portal behind the `factorio-mod-portal` environment gate. Local release and publishing scripts generate release notes and Mod Portal copy from `info.json`, `changelog.txt`, and `docs/public-copy.json`. Local GitHub Release and Mod Portal publishing both block unless release preflight confirms a clean local `main` exactly matches `origin/main` after fetching. Local publishing through `scripts/publish-portal.sh` still runs the headless suite by default before upload and is the stable Mod Portal path for the current `info.json` version. The packaged zip includes root `README.md`, `changelog.txt`, locale, Lua/prototype source, and root `thumbnail.png` when present; internal `docs/` files and generated public-site assets remain outside the mod package.
