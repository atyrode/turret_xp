# Design

## Gameplay Direction

The mod should make defensive infrastructure feel more personal without making early defenses trivial or turning every cheap turret into inventory metadata. A turret becomes notable when the player installs a Veteran Core and that core survives, fights, and moves between turret bodies.

## Portal Identity Direction

Public copy should be short and player-facing: chosen turrets become veterans, Veteran Cores carry progression, combat earns upgrades, specializations create identity, and material-fed elements add build variety. Avoid implementation-first wording such as runtime, prototype-backed, hidden feeder, or first playable except in internal docs.

The portal image should be simple, sober, and specific to the mod. Prefer a composition built from Factorio-native visual language: a gun turret, a Veteran Core/chip motif, an XP or level accent, and maybe one restrained elemental indicator. Do not use a generic AI-generated action scene, cinematic turret battle, or illustration that looks detached from Factorio's UI and item art. If custom art is needed, it should feel like an icon or clean key art derived from in-game sprites, screenshots, or hand-composed Factorio-style assets.

## V0.4.0 UX

- Keep the vanilla turret GUI as the main interaction.
- Add a compact panel to the right of the vanilla GUI.
- Use direct labels, one XP bar, restrained info markers, and a separate Evolution panel; avoid an information-dump table.
- Show vanilla-aligned stats where possible: attack range, force-modified shooting speed, damage research bonuses, entity-with-quality tooltip on the turret icon, and quality summaries for HP/range.
- Replace the experimental skill tree with five simple level-gated sections.
- Core upgrades are visible from the start and can be ranked repeatedly.
- Element sections show always-visible material progress bars for the next passive rank.
- Specialization and augment sections should feel like meaningful milestones, not passive background stats.
- Dev buttons are hidden by default as of V0.5.0 and toggled with `/turret-xp-dev` so normal playthroughs are not dominated by test controls.
- V0.6.0 stat rows should reveal active custom bonuses only when present, with specialization multipliers colored next to affected base values.
- V0.6.1 should make space-platform core choice explicit from the turret panel: when several Veteran Cores are in the platform hub, the player picks the exact core by row instead of relying on inserter order.
- V0.6.2 should make Evolution choices easier to scan by separating adjacent options with vanilla-style horizontal delimiters.
- V0.7.0 should make scripted effects easier to read through optional Bullet Trails tracers and vanilla element feedback, while keeping the UI copy focused on player-facing behavior instead of implementation details.
- V0.7.1 should avoid actions that move the whole vanilla turret GUI while the player is interacting with it. If a progression choice requires a prototype body swap, queue it until the turret GUI closes.
- V0.7.2 should make hidden element feeding feel closer to a machine input by letting inserters feed only the relevant material while needed, without visible chests or ground overflow. Bind/Unbind should read as an optional quick-move convenience for a chosen turret/core pair, while the Veteran Core remains the main portable identity object.
- V0.8.0 should treat the attached panel as two main columns: core identity, XP, dev controls, and stats on the left; Evolution on the right. Evolution should use the extra width to avoid an internal scrollbar in ordinary play. Mixed-element fuel requests should feel machine-like: inserters refresh stale filters and prioritize the element resource that is most needed.
- V0.8.1 should keep label customization visually grounded in Factorio's display-panel style, even for RGB slider colors. Mixed-element fuel handling should be stricter: managed inserters should hold one current-priority material filter at a time so the player can trust one chest with both element resources.
- V0.9.1 should keep the attached panel in a narrower stable two-column footprint while keeping both stats and Evolution bounded and scrollable. Section headers, right-side point/status text, technical element previews, local deallocation controls, and explicit `Change` actions for selected elements/specialization replace the old global Respec interaction. Any future Veteran Core slot redesign or full custom GUI should be preceded by source study of large GUI-heavy mods and maintained GUI/inventory libraries so the result feels closer to vanilla inventory behavior instead of a local imitation.
- V0.9.2 should keep unselected element choices visually parseable as interface cards rather than text blocks, keep fuel-burning element panels inside the Evolution scrollbar, and keep bound veteran turret quick-move behavior from affecting normal turret ghost replacement.
- V0.9.3 should flatten the Evolution column into a static summary header and one scrollable section body. Widths should derive from one right-column viewport model so buttons, rank steppers, cards, and labels fit without trial-and-error constants.
- V0.9.4 should keep element choice actions in the card's first row with icon and name, bound to the real card inner width. Element card technical rows should be visually separated enough that description, effect, and cost do not read as one text block.
- V0.9.5 should color specialization and stat multipliers by meaning: green for beneficial multipliers and red for tradeoffs. Evolution section frames should have balanced margins on all sides and visible space between sections. Specialization cards should match element cards visually, and element Start actions should live on the cost row where the material decision is being made.
- V0.9.6 should keep Evolution reset as one obvious header action that resets every Evolution choice while preserving the Veteran Core's identity and combat history. Element and specialization cards should right-align their action buttons without making description text wrap early. Floating-label `Level` should live under the RGB picker, not beside the `Show` checkbox.
- V0.9.7 should make Max HP a real but capped body-stat augment through hidden variants. Ammo Recovery should be framed as slow ammo item recovery, not ammo durability repair, because Factorio ammo is consumed as discrete items.
- V0.9.8 should let fueled elements buffer enough material for a meaningful operating window. The Evolution header should read as compact status text: white labels, colored values, and no extra explanatory copy. Floating-label color controls should read top-down as RGB sliders, preset/custom color button, then `Level`. Numeric value coloring should stay precise: color the number or multiplier, keep units and prose neutral, and use element colors only for elemental damage numbers. Hidden element input should recover from occasional wrong-item drops rather than leaving the player with a stuck invisible buffer. Specialization cards should also expose their secondary identity clearly: Sniper with Crit Damage, Machine Gun with Ammo Recovery, Bulwark with Regeneration, and Brawler with Lifesteal.
- V0.10.0 should add Resistance as a readable defensive core upgrade while avoiding more hidden prototype variants. It should also move the current element loop away from ongoing fuel buffers: picking an element is free at its level gate, future ranks are material projects, and the UI should describe damage mitigation plainly without implying that Resistance can prevent lethal one-shots.
- V0.10.1 should make Regeneration scale from current max HP instead of a tiny flat value, so durability investment, Bulwark, Guardian, and Max HP ranks create a coherent sustain build.
- V0.10.2 should make selected elements feel continuously buildable: the next material rank is always visible and passively fed, changing an element resets its unique mastery, Toxic joins the element set with poison-capsule material and slowing/stacking poison identity, Fire gains tracked burn damage over time, crits get lightweight hit feedback, and delayed damage remains tied to XP and lifesteal.

## V0.4.1 UX

- Add a Veteran Core section above XP.
- Show ordinary turrets as inactive until a core is installed.
- Keep install/extract as explicit button actions in the Turret XP panel rather than pretending to add a real vanilla inventory slot.
- Let the core carry optional identity text. If enabled, render `name (lvl N)` above the current turret body.
- Keep the first core icon vanilla-composed; replace with custom art later if the mechanic survives playtesting.

## Progression Direction

The long-term progression design is captured in [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md). The intended direction is that each turret can become a distinct veteran build through four connected layers:

- A Veteran Core stores XP and levels, then grants evolution points.
- Evolution points buy core upgrades and powerful augments in a level-gated list for the current draft.
- One-time material goals unlock major branch depth, hardware changes, element slots, and infinite mastery.
- Two element slots create pure-element or mixed-element combo identities.
- Late-game repeatable mastery absorbs excess XP and very large material investments with diminishing returns.

The main design goal is specialization over universal upgrades. A sniper turret, machine-gun turret, short-range heavy turret, bulwark turret, and duo-element turret should feel meaningfully different instead of being the same stat line at different power levels.

## Balance Direction

- Early levels should arrive fast enough for testing and feedback, but damage should contribute very little because damage totals grow quickly.
- Kill credit should be based on damage contribution so final-hit stealing does not erase most turret progress.
- Default 0.4.x pacing is conservative: `0.02` XP per damage, `20` XP per full kill credit, `100` base XP, and linear level growth using the `1.65` growth step.
- Space-platform combat is worth 10% of normal combat XP in V0.6.2 because space combat density can otherwise overlevel turrets too quickly.
- V0.7.0 adds target-aware XP weighting on top of surface weighting. Asteroids and asteroid chunks should be low-value XP targets so parked platforms do not passively farm levels, while larger enemies, worms, and spawners can be worth more than small biters.
- Long-term curves should avoid turning a single turret into a complete wall replacement.
- Bonuses should probably be modest and visible, with caps or specialization tradeoffs.

## Compatibility Direction

- Start with vanilla `gun-turret`.
- Later support should be prototype-driven for modded ammo turrets.
- Laser, flamethrower, artillery, and electric turrets likely need separate stat and XP rules.
