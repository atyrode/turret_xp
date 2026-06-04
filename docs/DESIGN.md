# Design

## Gameplay Direction

The mod should make defensive infrastructure feel more personal without making early defenses trivial. Individual turrets should gradually become notable because they survived and fought, not because the player opened a separate management screen.

## V0.2.0 UX

- Keep the vanilla turret GUI as the main interaction.
- Add a compact panel to the right of the vanilla GUI.
- Use direct labels, vanilla-like subheaders, an XP bar, and restrained info markers; avoid controls that imply unimplemented upgrades.
- Keep the prototype note behind a small info marker so testers know levels are tracked but not applied yet.
- Show vanilla-aligned stats where possible: attack range, force-modified shooting speed, damage research bonuses, entity-with-quality tooltip on the turret icon, and quality summaries for HP/range.

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
- Default V0.2.0 pacing is conservative: `0.02` XP per damage, `20` XP per full kill credit, `100` base XP, and `1.65` exponential growth.
- Long-term curves should avoid turning a single turret into a complete wall replacement.
- Bonuses should probably be modest and visible, with caps or specialization tradeoffs.

## Compatibility Direction

- Start with vanilla `gun-turret`.
- Later support should be prototype-driven for modded ammo turrets.
- Laser, flamethrower, artillery, and electric turrets likely need separate stat and XP rules.
