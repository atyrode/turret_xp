# Development Steps

## Completed For V0.1.0

- [x] Copy reusable scaffold from `player_quality`.
- [x] Rename metadata to `turret_xp`.
- [x] Add per-gun-turret XP, level, kill, and damage tracking.
- [x] Add GUI extension for vanilla gun turret.
- [x] Add command fallback with `/turret-xp`.
- [x] Update locale, README, docs, changelog, and release scripts.

## Validation

- [x] Run `scripts/check.sh`.
- [x] Run `scripts/package.sh`.
- [x] Inspect zip layout.
- [x] Initialize git repository and commit.
- [x] Create/push `atyrode/turret_xp`.
- [x] Create GitHub release `v0.1.0`.
- [x] Publish `0.1.0` to the Factorio Mod Portal.
- [ ] Run an in-game or headless Factorio smoke test once a Factorio binary is available locally.

## Completed For V0.1.1

- [x] Fix crash when opening a gun turret caused by reading max health from `LuaEntityPrototype`.
- [x] Move HP stat display to `LuaEntity::max_health` and harden optional prototype stat reads.
- [x] Document library/framework candidates to consider for future features.

## Completed For V0.1.2

- [x] Add runtime-global XP pacing settings.
- [x] Rebalance default XP with low damage XP, kill-credit XP, and configurable level growth.
- [x] Add contribution-based kill credit so final-hit stealing does not erase turret XP.
- [x] Align range and shooting-speed displays more closely with vanilla hover stats.
- [x] Add quality-aware turret icon and reorganize the panel for readability.

## Completed For V0.1.3

- [x] Rework the panel toward vanilla GUI styling with an inner shallow frame, slot-style ammo, compact section headers, and row info affordances.
- [x] Move the prototype note behind the top info button.
- [x] Show force research bonuses for shooting speed and ammo damage in base plus bonus format.
- [x] Re-check Mod Portal libraries for GUI and quality support; document `entity-gui-lib` and `quality-lib` as future candidates without adding them yet.

## Completed For V0.1.4

- [x] Fix research bonus lookup by deriving ammo category from loaded ammo or attack parameters.
- [x] Include gun-turret attack research when estimating damage per shot.
- [x] Remove the experimental custom quality stat marker because it did not reuse vanilla quality stat marker/popover behavior.
- [x] Replace gray framed info buttons with the exposed vanilla `utility/tip_icon` sprite, and stop rendering a custom fallback marker when that sprite is unavailable.
- [x] Document that exact vanilla quality stat pills are deferred until a supported API path or dependency is confirmed.

## Completed For V0.2.0

- [x] Add `flib >= 0.16.4` as the first production dependency.
- [x] Rebuild the right-side relative panel with vanilla-like shallow/deep frames, subheaders, flib slot styling, and flib status indicators.
- [x] Replace `utility/tip_icon` with Factory Planner-style `[img=info]` rich text markers.
- [x] Add `[img=quality_info]` markers with custom HP/range quality summary tooltips derived from runtime quality prototypes.
- [x] Add estimated DPS, damage XP, and kill-credit XP rows.
- [x] Update the panel in place every refresh tick instead of destroying and rebuilding the full GUI.

## Completed For V0.3.0

- [x] Simplify the main panel into one compact stat table.
- [x] Move ammo and turret icon into the title row.
- [x] Remove the quality text row, top info marker, no-bonuses note, progression section, and XP source rows.
- [x] Filter hidden `quality-unknown` out of quality summaries.
- [x] Add a first skill tree panel with four allocatable skill nodes.
- [x] Add active baseline skill effects for XP modifiers and passive repairs.

## Completed For V0.3.1

- [x] Rebuild the skill row into a scrollable technology-style skill tree surface.
- [x] Center the tree around a gun-turret root node with four branching baseline skills.
- [x] Reduce skill hover text to the next allocated effect only.
- [x] Add a root-node tooltip summarizing currently allocated bonuses.
- [x] Replace the XP progress bar with a custom solid bar style.
- [x] Inspect `entity-gui-lib` source and document it as the leading candidate for a future full custom turret GUI, not a requirement for the 0.3.x relative panel.

## Completed For V0.3.2

- [x] Inspect the local Factorio install for reusable research-tree Lua and confirm the pan behavior is not exposed as moddable source.
- [x] Add an embedded click-drag skill-tree pan spike using a hidden `open-gui` custom input and logical tree-cell scroll targets.
- [x] Keep the skill tree inside the existing Turret XP relative panel with no new window, screen overlay, full GUI replacement, or new library dependency.

## Completed For V0.4.0

- [x] Remove the failed embedded skill-tree drag implementation and data-stage custom input.
- [x] Replace the skill tree with a five-section Evolution list.
- [x] Add infinite core upgrades, first/second element projects, specialization choice, and powerful augments.
- [x] Add material-project progress, carried-item deposits, and dev completion buttons.
- [x] Add dev level buttons for fast level-gate testing.
- [x] Add first-draft runtime combat effects for core upgrades, augments, elements, combos, passive repair, and vampiric healing.
- [x] Migrate old 0.3.x skill ranks into 0.4.0 core ranks where possible.

## Completed For V0.4.1

- [x] Publish V0.4.0 to the Factorio Mod Portal before continuing V0.4.1 work.
- [x] Add a non-stackable Veteran Core `item-with-tags` prototype and recipe.
- [x] Make ordinary gun turrets stay stackable and progression-free until a Veteran Core is installed.
- [x] Move XP, kills, damage, evolution choices, material projects, and dev XP onto the installed core profile.
- [x] Add install and extract controls to the Turret XP panel.
- [x] Return/spill the installed Veteran Core when a turret is mined.
- [x] Add core-carried custom names and optional floating labels in `name (lvl N)` format.
- [x] Add a dev core button for local testing.
- [x] Make the Evolution area vertically scrollable so it does not expand beyond the turret GUI.
- [x] Move playtest dev controls above the Evolution scroll area.
- [x] Simplify locked sections, core upgrade rows, and remove the Elements/Specialization summary line.

## Completed For V0.4.2

- [x] Add hidden gun-turret prototype variants for Sniper, Machine Gun, Bulwark, and Brawler.
- [x] Swap specialized turret bodies when a Veteran Core specialization is chosen.
- [x] Revert the turret body to vanilla `gun-turret` when the Veteran Core is extracted.
- [x] Replace exponential level scaling with linear per-level scaling.
- [x] Give powerful augments one augment point every ten levels instead of doubling rank costs.
- [x] Remove material deposit buttons and auto-consume the matching carried element material while the turret is open.
- [x] Add element mastery milestones and short visual feedback for bounce, pierce, fire, electric, and explosive upgrade effects.

## Completed For V0.4.3

- [x] Add a real Veteran Core feeder inventory entity.
- [x] Create the feeder near the turret when a Veteran Core is installed.
- [x] Consume element unlock and mastery materials from the feeder instead of the player inventory.
- [x] Show feeder status in the Evolution panel.
- [x] Destroy the feeder and spill leftover feeder contents when the core is extracted or the turret is mined.

## Completed For V0.4.4

- [x] Fix fresh Veteran Core install crash in legacy skill migration.
- [x] Cache derived level progress so high-level combat damage does not rescan every prior level.
- [x] Add user Respec and dev Reset controls.
- [x] Replace cropped text allocation buttons with vanilla-style icon buttons and useful hover text.

## Completed For V0.4.5

- [x] Inspect `entity-gui-lib` inventory display and document why its current transfer helper is not safe for tagged Veteran Cores.
- [x] Add tag-preserving slot-style cursor install, extract, and swap behavior for Veteran Cores.
- [x] Add floating label color, size, and level-suffix controls.
- [x] Compact dev controls so they fit within the Turret XP panel.
- [x] Remove redundant installed-core profile id text from the visible panel.

## Completed For V0.4.6

- [x] Replace the visible adjacent feeder chest with an invisible hidden input colocated with the turret.
- [x] Forward ammo from the hidden input into the turret ammo inventory; later V0.7.2 feeder handling stops normal unsupported-item spills.
- [x] Remove feeder status from the Evolution panel.
- [x] Fix the label color button rebuild and standardize floating labels on the larger readable size.
- [x] Polish core upgrade rows with separate rank/effect text and compact vanilla-gray allocation buttons.
- [x] Show element material requirements with rich-text item icons.
- [x] Show `No ammo` instead of `Unknown` when damage cannot be estimated because no ammo is loaded.
- [x] Replace Longshot and Piercing augments with Double Shot and Veteran Training.

## Completed For V0.4.7

- [x] Fix hidden-input ammo detection against Factorio 2.0 runtime prototypes.
- [x] Add a real prototype-backed Range augment up to +20 range.
- [x] Generate specialization bodies from vanilla-stat multipliers.
- [x] Increase initial element unlock material costs by 10x.
- [x] Replace post-unlock element mastery ranks with bounded element fuel.
- [x] Put the name field and label controls on one row.
- [x] Move floating labels lower than 0.4.6 while keeping them above the turret.

## Completed For V0.6.0

- [x] Preserve Evolution list context after point allocation.
- [x] Split core name and label controls into two rows so they fit the attached panel.
- [x] Show technical effect text for augments and specialization choices.
- [x] Rework element fuel into a furnace-like burner buffer that fills to capacity and does not spill valid excess fuel around the turret.
- [x] Add scrollable dynamic stats that reveal only active custom bonuses.
- [x] Add element mastery ranks that spend regular core points after unlock.
- [x] Show specialization multipliers next to affected stat values and multiply Range augments before specialization range scaling.
- [x] Rework floating labels to use hidden display-panel labels when available.
- [x] Improve kill accounting for scripted element damage.
- [x] Hide dev controls by default and add `/turret-xp-dev` to toggle them.
- [x] Fix invalid killed-target reads in runtime upgrade visual feedback.
- [x] Enlarge allocation buttons to avoid cropped `+` labels.

## Completed For V0.6.1

- [x] Add formula-style stat rows for additive bonuses and specialization multipliers.
- [x] Add Luck as a proc-odds augment and apply it to crits, bounce, double shot, and elements.
- [x] Make bounced hits run element proc logic and show electric feedback from bullet impact points.
- [x] Make Double Shot read visually as a delayed second shot.
- [x] Close the hidden feeder input at the visible element fuel cap instead of accepting extra ghost fuel.
- [x] Keep existing element fuel accepted while a second-element project is active.
- [x] Add explicit platform hub Veteran Core selection and return controls for space-platform turrets.

## Completed For V0.6.2

- [x] Reduce space-platform combat XP to 10% while preserving raw displayed damage and kill-credit totals.
- [x] Add delimiters between choices in Evolution sections for readability.

## Completed For V0.7.0

- [x] Add target-aware combat XP weighting for asteroids, units, worms, spawners, and miscellaneous enemy targets.
- [x] Keep raw damage and kill-credit display totals unchanged while applying target/surface weights only to XP counters.
- [x] Add optional Bullet Trails support for scripted bounce, double-shot, and element tracers.
- [x] Reuse vanilla electric, fire, explosion, and weapon sound prototypes for element feedback where practical.
- [x] Stop copying gun-turret attack research effects onto hidden turret variants.
- [x] Sync hidden variant turret attack modifiers from the vanilla gun turret at runtime on init, configuration change, force creation, and research completion.
- [x] Recheck Veteran Core recipe unlocks after research completion.

## Completed For V0.7.1

- [x] Defer turret body swaps until the turret GUI closes so specialization, Range, install, extract, respec, and reset actions do not reset the whole vanilla GUI position.
- [x] Replace base upgrade `+` rows with compact `- value +` controls.
- [x] Add Shift-click support to add or remove up to 10 base upgrade ranks at once.
- [x] Add RGB sliders for floating label color selection.
- [x] Reduce the stats panel to one visible container.
- [x] Make Sniper shoot much more slowly.
- [x] Make Double Shot prefer a simultaneous second target and fall back to the original target when alone.
- [x] Keep hidden element feeders present but closed at fuel cap so inserters can resume fuel input when the buffer drops.

## Completed For V0.7.2

- [x] Rework hidden element feeding to manage nearby inserter `drop_target` values and temporary filters while element input is needed.
- [x] Restore regular turret drop targeting when element input is full or not needed.
- [x] Stop normal feeder routing from spilling unexpected non-ammo items around the turret.
- [x] Right-align the base upgrade `- value +` control group.
- [x] Hide floating-label color controls until `Show name` is enabled, and keep preset color captions stable unless RGB sliders create a custom color.
- [x] Add opt-in bound veteran turret quick moves through a tagged placeable turret item.
- [x] Add a Factorio headless regression suite that runs before Mod Portal publishing and covers core gameplay invariants.

## Completed For V0.8.0

- [x] Move Evolution into a second main panel column beside the core, XP, dev, and stats column.
- [x] Fix mixed-element feeding so the second element's resource can be requested and inserted when the first element is different.
- [x] Refresh stale allowed inserter filters instead of leaving a feeder stuck on the first element's item.
- [x] Collapse duplicate pure-element stat summary rows into one active element row.
- [x] Include `thumbnail.png` from the repository root in packaged mod zips.
- [x] Extend the headless regression suite for mixed elements, stale filter refresh, duplicate element summary state, feeder caps, bound turret movement, and combat progression.

## Completed For V0.8.1

- [x] Move Respec and Bind/Unbind to a separate installed-core action row so the core panel does not overflow.
- [x] Hide `Show level` unless the floating name label is enabled.
- [x] Keep custom RGB floating labels on display-panel label entities through a generated color palette.
- [x] Force managed mixed-element inserters to the single current-priority resource and test Fire-first/Explosive-second feeding.
- [x] Avoid redundant feeder input-bar writes while leaving the input open whenever fuel or project material is still needed.

## Completed For V0.9.0

- [x] Move hidden specialization and Range variant generation to `data-final-fixes.lua` so modded base gun-turret stats are inherited before Turret XP applies rank/specialization modifiers.
- [x] Add a headless regression for a data-updates range patch, covering the K2 Spaced Out-style range decrease report.
- [x] Make the attached two-column panel fixed-width with scrollable stats and bounded scrollable Evolution content.
- [x] Add Evolution section headers, right-side point/status text, technical element previews, and per-section reset/deallocation controls.
- [x] Extend the headless suite for individual Evolution section resets and deterministic combat kill tracking.

## Completed For V0.9.1

- [x] Split the runtime implementation into focused modules under `scripts/control/` while keeping `control.lua` as an entrypoint.
- [x] Split data-stage prototype creation into `prototypes/` modules while keeping `data.lua` and `data-final-fixes.lua` as entrypoints.
- [x] Preserve the existing `storage.turret_xp` save schema and Veteran Core `item-with-tags` profile format.
- [x] Add a documented `core_slot` module boundary for future tag-preserving inventory-list slot work.
- [x] Narrow the attached two-column panel through shared layout constants and keep Evolution content out from under the scrollbar.
- [x] Rename selected element reset actions to `Change` so element choices are clearly respecable like specialization.
- [x] Document the V0.9.1 refactor plan and update architecture, technical direction, requirements, spec, website, and README references.

## Completed For V0.9.2

- [x] Fix bound veteran turret placement so normal destroyed gun-turret replacement ghosts keep requesting/displaying the normal gun turret item.
- [x] Add a headless place-result regression for normal gun turrets, bound turret items, and the bound-only placeholder.
- [x] Move Bind/Unbind onto the installed Veteran Core slot row.
- [x] Narrow fuel-burning element panels and keep selected element `Change` actions visible inside the Evolution scrollbar.
- [x] Reformat unselected element choices into readable cards with separate description, effect, cost, and combo lines.

## Completed For V0.9.3

- [x] Flatten the Evolution column into a static summary header plus one scrollable section body.
- [x] Move Core, Augment, and Specialization summary text into the fixed Evolution header.
- [x] Replace scattered Evolution width constants with derived viewport, content, and inner-row widths.
- [x] Move element choice `Start` actions into their own right-aligned row so they cannot overflow under the scrollbar.
- [x] Fix duplicate Augment point summaries after spending augment points.

## Completed For V0.9.4

- [x] Put element choice `Start` buttons on the icon/name row and bound that row to the card's real inner width.
- [x] Add a separator between element effect and cost rows.
- [x] Remove redundant `Material unlock` text from element section headers.
- [x] Move core-upgrade Reset to the static Evolution header, simplify Augment summary text, and remove the selected specialization `Active` label.

## Completed For V0.9.5

- [x] Color specialization choice multipliers and stat-summary multipliers green for benefits and red for tradeoffs.
- [x] Add vertical breathing room after Evolution section headers.
- [x] Add balanced margins around Evolution section frames and between adjacent sections.
- [x] Compact Veteran Core name controls, align specialization cards with element cards, and move element Start actions to cost rows.

## Completed For V0.9.6

- [x] Replace section-specific reset buttons with one always-visible Evolution header Reset that clears all Evolution choices while preserving XP, level, history, name, and binding.
- [x] Move floating-label `Level` below the RGB color picker.
- [x] Right-align element `Start` and specialization `Pick` buttons without shrinking card descriptions unnecessarily.
- [x] Reserve explicit Evolution section width for both left and right section margins.
- [x] Show baseline Crit Chance and Crit Damage in the stats summary.
- [x] Add headless coverage for the full Evolution reset and the margin-aware layout constants.

## Completed For V0.9.7

- [x] Start fresh Veteran Cores at level 0 so level 10 grants 10 core points before spending.
- [x] Add Max HP as a capped prototype-backed augment at +50 HP per rank, up to rank 20.
- [x] Add Ammo Recovery as a core upgrade that regenerates the current or remembered ammo item at one ammo per minute per rank.
- [x] Persist last loaded ammo on Veteran Core profiles so ammo recovery survives moving cores.
- [x] Generate hidden turret variants for Max HP ranks combined with Range ranks and specializations.
- [x] Add headless coverage for Max HP variants and remembered-ammo recovery.
- [x] Replace the hidden feeder's one-item material latch with a bounded one-item-slot project buffer so inserters do not hit `Target full` after every project item.

## Completed For V0.9.8

- [x] Increase element fuel capacity from 10 to 100 stored items per active element.
- [x] Reformat the Evolution header summary as rich text with white labels and colored values.
- [x] Move the floating-label preset/custom color button below the RGB picker and above the `Level` checkbox.
- [x] Move unlocked element mastery controls into the element card header row so they stay inside the Evolution column.
- [x] Reserve stats-scrollbar space and move baseline Crit Chance/Crit Damage under Damage Dealt.
- [x] Standardize value formatting so only numeric fragments are colored, with element colors on elemental damage numbers.
- [x] Add explicit expiry tracking for electric arc visual entities.
- [x] Clear unexpected non-ammo stacks from the hidden input so wrong items cannot block element project progress.
- [x] Add headless regression coverage for wrong hidden-input materials during an active element project.
- [x] Add hidden bound turret preview variants so newly mined bound stacks show a native placement range preview matching specialization and Range ranks.
- [x] Prevent placement helper ammo from merging with bound turret ammo snapshots.
- [x] Keep bound turret mining as one tagged bound item, spilling it when inventory space is unavailable instead of degrading into a separate core path.
- [x] Add role-specific secondary specialization multipliers for Crit Damage, Ammo Recovery, Regeneration, and Lifesteal.

## Completed For V0.10.0

- [x] Add Resistance as a capped core upgrade that reduces non-lethal incoming damage.
- [x] Implement Resistance with scripted post-hit mitigation instead of hidden prototype variants.
- [x] Rebalance Brawler to x3 damage and x0.5 fire rate while preserving its lifesteal identity.
- [x] Move elements from ongoing fuel buffers to free picks plus material-fed rank projects.
- [x] Add level-40 sub-specializations and move the second element/combo unlock to level 50.
- [x] Harden bound turret mining and placement so full inventories and placement-helper ammo cannot reset cores, duplicate ammo, or silently consume ammo.
- [x] Add headless coverage for Resistance derived stats, rank cap, and live damage mitigation.
- [x] Add headless coverage for material-fed element projects, bound turret full-inventory spills, tagged ground items, and placement-helper ammo refunds.

## Completed For V0.10.1

- [x] Rebalance Regeneration to scale from current max HP instead of a small flat HP/s value.
- [x] Keep Bulwark and Guardian regeneration multipliers applied on top of max-health-based repair.
- [x] Fix the unlocked element `Upgrade` action width so the caption is not truncated.
- [x] Add headless coverage for Max HP based regeneration and specialization regeneration multipliers.

## Completed For V0.10.2

- [x] Replace element `Upgrade` buttons and manually started projects with passive always-visible next-rank material progress.
- [x] Add Toxic as a poison-capsule-fed element with stacking poison damage and slowdown feedback.
- [x] Add tracked Fire burn damage, critical-hit visual feedback, and two-trail Double Shot feedback.
- [x] Keep delayed Fire/Toxic damage tied to XP, kill contribution, and lifesteal.
- [x] Let managed inserters expose all currently needed mixed-element resources in their filter slots.
- [x] Add headless coverage for passive element progress, Toxic material routing, mixed-element filters, and delayed status-damage lifesteal.

## Completed For V0.10.3

- [x] Fix bound veteran turret ammo conservation so mining and placing a bound turret does not duplicate the saved ammo snapshot.
- [x] Add a turret-source projectile range compatibility patch for K2/K2SO-style realistic rifle ammo.
- [x] Add headless coverage for modded projectile ammo whose physical delivery range is lower than generated Turret XP turret range.
- [x] Add an in-world level-up flying-text popup for installed cores that gain levels through XP progression.

## Completed For CI/Release Workflow

- [x] Establish short-lived issue branches and pull requests into protected `main` as the preferred development flow.
- [x] Add GitHub Actions package validation for pull requests, pushes to `main`, and manual CI runs.
- [x] Add CI support for authenticated Mod Portal dependency downloads and Factorio headless regression tests.
- [x] Add GitHub Release-triggered packaging, headless validation, GitHub release asset upload, and gated Factorio Mod Portal publishing.
- [x] Document required GitHub repository secrets, the `factorio-mod-portal` environment gate, and branch protection follow-up.

## Shared Domain Definitions

- [x] Move stable IDs, progression caps, specialization/sub-specialization definitions, label presets, and variant-name helpers into `scripts/domain.lua`.
- [x] Reuse the shared domain definitions from runtime config, data-stage prototype generation, bound turret preview variants, and headless regression checks.
- [x] Package the shared domain module in release zips so CI and Mod Portal artifacts use the same module as local source runs.

## Prototype Variant Budget

- [x] Add headless runtime measurement for hidden turret body, bound preview item, bound placeholder, and label display-panel prototype counts.
- [x] Print the tracked hidden prototype budget from `scripts/test-headless.sh` on passing runs.
- [x] Document the current 6,498-prototype tracked budget and require explicit issue/PR approval before adding new prototype-backed axes or increasing prototype-generating caps.

## Explicit Module Migration

- [x] Keep `scripts/domain.lua` independent from the shared runtime `_ENV` table.
- [x] Move label color preset lookup/matching into explicit returned-table module `scripts/control/label_colors.lua`.
- [x] Document the incremental rule: new pure helper groups should prefer direct `require` dependencies and returned tables instead of widening shared globals.

## Runtime Ownership Split

- [x] Move bound turret tagged-item creation, decoding, build-event stack lookup, mining-result cleanup, and insert/spill delivery into `scripts/control/bound_turret_items.lua`.
- [x] Add headless coverage for legacy/generic bound turret stacks that carry a profile tag but no turret snapshot tag.

## Likely Next Work

- Playtest V0.10.3 from a local package or Mod Portal release after feedback integration, especially around bound turret ammo conservation, K2/K2SO realistic ammo range compatibility, level-up flying text, Resistance feel, max-HP-based Regeneration, passive element material progress, Toxic and Fire damage-over-time readability, crit/double-shot visuals, richer Evolution summary header, right-column scrollbar containment, specialization multiplier colors, section margins, full Evolution reset, baseline crit stats, Max HP rank body swaps, Ammo Recovery pacing, level-40 sub-specializations, normal/bulk inserter feeding, hidden input ammo forwarding, deferred turret body swaps, bound turret mining/placement, normal turret replacement ghosts, placement-helper ammo refunds, range stacking, specialization multipliers, Luck/proc effects, platform hub core selection, asteroid XP pacing, optional Bullet Trails visuals, label controls, modded base turret range compatibility, and high-level turret combat performance.
- Keep GUI polish, visual readability, and real click/hover feel in the manual playtest loop; headless tests cover deterministic state and event behavior, not pixels or mouse feel.
- Build the next Veteran Core slot iteration on `scripts/control/core_slot.lua`: exact-core inventory lists, tag-preserving scripted transfers, and clearer player-inventory/platform selection without claiming native vanilla slot behavior.
- Consider a scripted slot-like manual project input in unlocked element cards. It can support normal cursor transfer and display active project counts, but it is not a true arbitrary native inventory slot inside the vanilla turret GUI.
- Continue the Mod Portal identity pass: final name/category decisions and any future thumbnail refinements should stay simple, sober, and Factorio-native.
- Playtest and tune level gates, material costs, point costs, core recipe cost, specialization stats, and upgrade effect strength.
- Investigate whether HP and Range can eventually move away from hidden prototype variants without losing real attack reach, max-health behavior, placement preview fidelity, blueprint behavior, or modded-base compatibility.
- Decide whether destroyed turrets should always lose cores, drop damaged cores, or have a recovery chance.
- Prototype an `entity-gui-lib` branch before any full replacement of the turret GUI.
- Evaluate `quality-lib` and/or prototype `custom_tooltip_fields` before adding quality-scaled custom stats.
- Add a lightweight website generator so `docs/index.html` is derived from `info.json`, `changelog.txt`, README content, and docs where practical.
- Fold website freshness into release validation so public docs and Mod Portal homepage do not drift from the mod.
- Add headless Factorio smoke-test automation if a stable local binary is available.
