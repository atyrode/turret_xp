# Progression Design

Status: future-only design direction. This document is not a committed implementation spec. Current implemented behavior belongs in [PROJECT_SPEC.md](PROJECT_SPEC.md), and user-visible obligations belong in [REQUIREMENTS.md](REQUIREMENTS.md).

## Current Playable Baseline

The V0.10.x line uses a level-gated Evolution list:

- Core upgrades are available once a Veteran Core is installed.
- Specialization unlocks at level 10.
- First element unlocks at level 20.
- Augments unlock at level 30.
- Sub-specialization unlocks at level 40.
- Second element and combo identity unlock at level 50.

The previous embedded skill-tree spike was removed. A future tree can return only if it proves better than the current list for readability, validation, and player control.

## Core Fantasy

A turret should become a veteran with a readable identity. Two gun turrets that started from the same vanilla prototype should be able to diverge into clear roles such as long-range precision defender, high-volume swarm shredder, durable anchor, or elemental specialist.

The mod should preserve Factorio's industrial logic: combat experience matters, but major growth should also require deliberate material investment.

## Design Pillars

- Specialization over universal upgrades: high-level turrets should not simply become better at everything.
- Combat earns direction: XP and levels grant choices that express what the turret learned by fighting.
- Materials express commitment: the factory should build deeper capabilities into the turret.
- Element growth should be intentional: selecting an element creates identity immediately, while later ranks need visible material progress.
- Visible identity: the GUI should show archetype, elements, spent points, material goals, and next useful action.
- Infinite scaling stays narrow: repeatable investment should be slow, focused, and subject to caps, diminishing returns, or escalating costs.

## Future Layers

These are future design lanes, not all current features.

### XP And Points

XP is the combat-earned layer. It should come from damage contribution and kill credit, with target-aware and surface-aware pacing so passive asteroid defense or trivial targets do not overlevel a core.

Points should answer: what has this turret learned to do?

### Materials

Materials are the industrial commitment layer. They should answer: what did the factory build into this turret?

Current V0.10.x element ranks already use passive material progress. Future material gates can be considered for deeper branch caps, hardware transformations, advanced element slots, sustain systems, or mastery sinks, but only when the player-facing goal remains visible and the feeder/input model stays understandable.

The current material-input model is the invisible turret-tile feeder. Future work should harden that model and improve diagnostics before replacing it with a visible, hybrid, or manual delivery model.

### Elements

Elements are the identity and interaction layer. The implemented set is Fire, Electric, Explosive, and Toxic. Future elements such as Kinetic, Acid, Poison, radiation-like behavior, or laser-like behavior should wait until the current element set is readable and balanced.

Duplicate pure-element builds should specialize. Mixed pairs should create a mechanic that neither element has alone. Combo growth should stay curated and limited until the current four elements are playtested. It is better to ship a few readable, well-balanced combos than a large matrix of shallow effects.

### Infinite Mastery

Infinite mastery is the late-game sink. It should absorb excess XP and large material quantities without letting one turret replace base defense planning.

Possible mastery lanes include precision, fire rate, durability, regeneration, ammo economy, element chance, and support reliability. Any repeatable lane should include diminishing returns, soft caps, escalating costs, or narrow tradeoffs.

## Archetype Anchors

These anchors keep future branches distinct:

- Sniper: long range, slow fire, high damage per shot, crit value, and piercing or overkill conversion.
- Machine Gun: high fire rate, lower damage per bullet, swarm control, ammo-flow mastery, and proc frequency.
- Brawler or Short-Range Heavy: reduced range, heavy damage, splash or close-range punishment, and durable front-line identity.
- Bulwark: survivability, self-healing, resistance, shield/recovery behavior, and holding power.
- Elementalist: status effects, duo-element combos, luck scaling, and tactical damage conversion.
- Veteran Support: XP gain, luck, ammo economy, reliability, and possible low-intensity support effects.

Do not let these anchors collapse into one universal best turret. Strong roles should carry tradeoffs.

## Future Tree Shape

If a tree returns later, it should be a real navigable map with obvious prerequisites and costs, not a flat list with hidden structure.

Possible node types:

- Perk: costs points and grants a rankable effect.
- Gate: costs materials and unlocks branch depth.
- Choice: defines or changes a role.
- Socket: assigns or changes an element.
- Combo: requires two elements and grants a unique mechanic.
- Mastery: repeatable late-game sink with escalating cost.

The UI must make point cost, material cost, prerequisites, current rank, and resulting effect obvious. Material progress should be visible as progress toward a goal, not hidden in a tooltip.

## Guardrails

- Do not add another prototype-backed stat axis during the current hardening direction. Native prototype-bound stat identity belongs to specialization and sub-specialization bodies only.
- Keep HP, regeneration, mitigation, shield, and lifesteal as distinct survivability models rather than one larger number.
- Keep script-heavy effects budgeted and readable.
- Avoid stacking every proc type on one turret.
- Use material gates to make deep specialization deliberate, not as hidden chores.
- Defer new branches, elements, broad combo matrices, and infinite mastery until current effects are readable and balanced.
- Keep respec policy explicit. Free respec is useful for playtesting; final balance may need cost, cooldown, or partial permanence.

## Open Questions

- Should destroyed turrets always lose the installed core, drop a damaged core, or have a recovery chance?
- Should material investment stay per turret, or should some late gates become force-wide once discovered?
- Which diagnostics or UI hints would make the current invisible material input clear enough during play?
- After the current four elements are balanced, should future elements expand beyond Fire, Electric, Explosive, and Toxic?
- Should infinite mastery consume only materials, only XP, or both?
- How much support or aura behavior can exist without hurting performance and readability?
- Should self-damage overdrive ever exist, and if so should it be manual, conditional, or passive?
