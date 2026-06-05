# Design

## Gameplay Direction

The mod should make defensive infrastructure feel more personal without making early defenses trivial or turning every cheap turret into inventory metadata. A turret becomes notable when the player installs a Veteran Core and that core survives, fights, and moves between turret bodies.

## Portal Identity Direction

The current public name, short description, category, and portal presentation are serviceable for playtesting, but they should get a deliberate identity pass once the core loop is clearer. The Mod Portal listing should immediately tell players that the mod adds chosen, movable gun-turret progression through Veteran Cores, element feeding, specialization, XP, and upgrades. Avoid vague XP-only wording if the mod identity has shifted toward turret evolution and core-based customization.

The portal image should be simple, sober, and specific to the mod. Prefer a composition built from Factorio-native visual language: a gun turret, a Veteran Core/chip motif, an XP or level accent, and maybe one restrained elemental indicator. Do not use a generic AI-generated action scene, cinematic turret battle, or illustration that looks detached from Factorio's UI and item art. If custom art is needed, it should feel like an icon or clean key art derived from in-game sprites, screenshots, or hand-composed Factorio-style assets.

## V0.4.0 UX

- Keep the vanilla turret GUI as the main interaction.
- Add a compact panel to the right of the vanilla GUI.
- Use direct labels, one XP bar, restrained info markers, and a separate Evolution panel; avoid an information-dump table.
- Show vanilla-aligned stats where possible: attack range, force-modified shooting speed, damage research bonuses, entity-with-quality tooltip on the turret icon, and quality summaries for HP/range.
- Replace the experimental skill tree with five simple level-gated sections.
- Core upgrades are visible from the start and can be ranked repeatedly.
- Element sections show explicit material projects and progress bars.
- Specialization and augment sections should feel like meaningful milestones, not passive background stats.
- Dev buttons are hidden by default as of V0.5.0 and toggled with `/turret-xp-dev` so normal playthroughs are not dominated by test controls.
- V0.6.0 stat rows should reveal active custom bonuses only when present, with specialization multipliers colored next to affected base values.
- V0.6.1 should make space-platform core choice explicit from the turret panel: when several Veteran Cores are in the platform hub, the player picks the exact core by row instead of relying on inserter order.

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
- Long-term curves should avoid turning a single turret into a complete wall replacement.
- Bonuses should probably be modest and visible, with caps or specialization tradeoffs.

## Compatibility Direction

- Start with vanilla `gun-turret`.
- Later support should be prototype-driven for modded ammo turrets.
- Laser, flamethrower, artillery, and electric turrets likely need separate stat and XP rules.
