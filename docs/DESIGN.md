# Design

## Gameplay Direction

The mod should make defensive infrastructure feel more personal without making early defenses trivial or turning every cheap turret into inventory metadata. A turret becomes notable when the player installs a Veteran Core and that core survives, fights, and moves between turret bodies.

## V0.4.0 UX

- Keep the vanilla turret GUI as the main interaction.
- Add a compact panel to the right of the vanilla GUI.
- Use direct labels, one XP bar, restrained info markers, and a separate Evolution panel; avoid an information-dump table.
- Show vanilla-aligned stats where possible: attack range, force-modified shooting speed, damage research bonuses, entity-with-quality tooltip on the turret icon, and quality summaries for HP/range.
- Replace the experimental skill tree with five simple level-gated sections.
- Core upgrades are visible from the start and can be ranked repeatedly.
- Element sections show explicit material projects and progress bars.
- Specialization and augment sections should feel like meaningful milestones, not passive background stats.
- Dev buttons are visible in this draft so playtest feedback can focus on section flow and effects instead of real-time grinding.

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
- Default 0.4.x pacing is conservative: `0.02` XP per damage, `20` XP per full kill credit, `100` base XP, and `1.65` exponential growth.
- Long-term curves should avoid turning a single turret into a complete wall replacement.
- Bonuses should probably be modest and visible, with caps or specialization tradeoffs.

## Compatibility Direction

- Start with vanilla `gun-turret`.
- Later support should be prototype-driven for modded ammo turrets.
- Laser, flamethrower, artillery, and electric turrets likely need separate stat and XP rules.
