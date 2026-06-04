# Design

## Gameplay Direction

The mod should make defensive infrastructure feel more personal without making early defenses trivial. Individual turrets should gradually become notable because they survived and fought, not because the player opened a separate management screen.

## V0.3.1 UX

- Keep the vanilla turret GUI as the main interaction.
- Add a compact panel to the right of the vanilla GUI.
- Use direct labels, one XP bar, restrained info markers, and a separate skill panel; avoid an information-dump table.
- Show vanilla-aligned stats where possible: attack range, force-modified shooting speed, damage research bonuses, entity-with-quality tooltip on the turret icon, and quality summaries for HP/range.
- Keep the first skill tree small, but present it as a scrollable technology-style surface with a central turret root and branching perk nodes.
- Skill node labels live under their icons; hover text stays limited to the effect gained by allocating the next rank.
- The central turret root summarizes allocated skill bonuses on hover.

## Progression Direction

Candidate future bonuses:

- Damage per shot.
- Shooting speed.
- Range.
- Max HP or resistance.
- Ammo efficiency.
- Specialization paths for anti-swarm, anti-armor, or durable frontier turrets.

## Balance Direction

- Early levels should arrive fast enough for testing and feedback, but damage should contribute very little because damage totals grow quickly.
- Kill credit should be based on damage contribution so final-hit stealing does not erase most turret progress.
- Default 0.3.x pacing is conservative: `0.02` XP per damage, `20` XP per full kill credit, `100` base XP, and `1.65` exponential growth.
- Long-term curves should avoid turning a single turret into a complete wall replacement.
- Bonuses should probably be modest and visible, with caps or specialization tradeoffs.

## Compatibility Direction

- Start with vanilla `gun-turret`.
- Later support should be prototype-driven for modded ammo turrets.
- Laser, flamethrower, artillery, and electric turrets likely need separate stat and XP rules.
