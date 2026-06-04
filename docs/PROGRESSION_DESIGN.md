# Progression Design

This document captures the intended long-term gameplay direction for turret XP, evolution, perks, material investment, elemental specialization, and infinite scaling. It is design direction only; it should not be read as a committed implementation spec.

V0.4.0 intentionally uses a simple five-section Evolution list instead of a navigable skill tree. The list is the first playable way to test the gameplay loop before deciding whether a future tree, map, or another layout is worth the UI complexity.

## Core Fantasy

A turret should be able to become a veteran with an identity.

The player should look at two gun turrets that started from the same vanilla prototype and understand that one has become a long-range precision defender, another has become a high-volume swarm shredder, and another has become a short-range armored anchor. The mod should preserve Factorio's industrial logic: combat experience matters, but major upgrades should also require deliberate material investment.

## Design Pillars

- **Specialization over universal upgrades.** A high-level turret should not simply be better at everything. Strong choices should usually close or weaken other paths.
- **Combat earns direction.** XP and levels should grant skill points, and skill points should express what the turret learned by fighting.
- **Materials express commitment.** One-time or milestone material costs should unlock major hardware changes, branch caps, elemental slots, sustain systems, risky overdrives, and infinite sinks.
- **No constant upkeep tax.** Material delivery should feel like a construction project or research-style goal, not like another fuel type the player must babysit.
- **Visible identity.** The GUI should show the turret's archetype, elements, spent points, material gates, and next meaningful goal without burying the player in raw numbers.
- **Infinite scaling stays narrow.** Repeatable investment should exist, but it should be slow, focused, and subject to diminishing returns.

## Progression Layers

Turret progression should combine four layers that serve different purposes.

### 1. XP And Skill Points

XP is the combat-earned layer.

- Turrets earn XP from damage contribution and kill credit.
- Levels grant skill points.
- Evolution points buy perks in the current list UI. A future version may return to a navigable tree if the interaction model is worth it.
- Perks shape behavior: range, fire rate, damage profile, crits, piercing, bouncing, healing, luck, XP gain, status chance, and archetype-specific mechanics.

Skill points should mostly answer: **what has this turret learned to do?**

Early levels should arrive quickly enough to let the player make a first identity choice. Later levels should become increasingly meaningful goals. A good target is that a turret reaches its first real specialization after a modest number of defended attacks, then takes sustained frontier combat to reach deeper branches.

### 2. Material Investment

Materials are the industrial commitment layer.

Some upgrades should require both a skill point and a material unlock. Other upgrades should be pure material milestones that open new branch depth, new hardware, or new element slots.

Examples:

- A sniper branch node might require a skill point plus steel, advanced circuits, and radar.
- A machine-gun branch node might require gears, engines, copper, and circuits.
- A heavy short-range branch node might require steel, concrete, explosives, and repair packs.
- An elemental branch gate might require sulfur, batteries, flamethrower ammo ingredients, uranium, or processing units depending on the element.
- A sustain or overdrive branch might require repair packs, walls, steel, engines, batteries, or modules depending on whether it focuses on armor, regeneration, vampirism, or self-damaging burst power.

Material investment should answer: **what did the factory build into this turret?**

The intended feel is closer to localized research or a construction contract than fuel. A turret might need `1k` iron plate to unlock a branch, then much later `1m` iron plate as part of an infinite mastery sink. The exact numbers should scale with game stage and must be playtested.

### 3. Element Slots

Elements are the identity and interaction layer.

Each turret can eventually gain two element slots. The first element gives a broad identity. The second element creates a combo archetype. Picking the same element twice should be valid and should create a focused pure-element build.

The element system should answer: **what kind of damage logic does this turret bend toward?**

Potential initial element set:

- **Kinetic:** physical damage, piercing, ricochet, armor breaking, crit reliability.
- **Fire:** burning damage, area denial, lingering effects, panic against swarms.
- **Electric:** arcing shots, stun or slow windows, chain targeting, shield disruption if relevant.
- **Acid:** resistance shred, armor corrosion, damage-over-time, debuff setup.
- **Explosive:** splash, shrapnel, knockback, clustered-target punishment.
- **Poison:** clouds, lingering area control, biological-target pressure.

Laser-like or radiation-like elements can be considered later, but they may fit better once non-ammo turrets or advanced ammo are supported.

### 4. Infinite Mastery

Infinite mastery is the late-game sink.

After a turret has an archetype and major branch unlocks, it should have repeatable goals that absorb excess XP and large material quantities. These should be small and focused, not broad multipliers that make one turret solve every defense problem.

Examples:

- `Precision Mastery`: repeatable small crit damage increase for sniper builds.
- `Servo Mastery`: repeatable small fire-rate increase for machine-gun builds, with ammo usage tradeoffs.
- `Hardened Core`: repeatable small max HP or resistance increase for bulwark builds.
- `Regenerative Plating`: repeatable small life regeneration or repair efficiency increase.
- `Bloodless Engine`: repeatable small lifesteal-style healing from damage dealt, capped by combat context.
- `Elemental Mastery`: repeatable small status chance or elemental damage increase for a chosen element pair.
- `Logistics Mastery`: repeatable small ammo efficiency or reload benefit.

Infinite upgrades should use diminishing returns, soft caps, or escalating material costs. They should be exciting as long-term goals without becoming mandatory busywork for every turret.

## Future Tree Shape

If the mod returns to a tree later, it should be a navigable map, not a flat list. This is deferred while V0.4.x tests whether the underlying upgrade categories are fun.

Recommended structure:

- The center node is the turret itself.
- Early branches radiate into archetypes.
- Deeper paths require prior branch commitment.
- Major gates can require materials.
- Element slots live as major nodes or socket-like unlocks.
- Combo nodes appear after the second element is chosen.
- Infinite nodes sit at the outer edge of committed paths.

Node types:

- **Perk:** costs skill points and grants a rankable effect.
- **Gate:** costs materials and unlocks nearby nodes or branch depth.
- **Choice:** mutually exclusive or branch-defining node.
- **Socket:** assigns or changes an element.
- **Combo:** requires two elements and grants a unique mechanic.
- **Mastery:** repeatable late-game sink with escalating costs.

The UI should make requirements obvious: point cost, material cost, prerequisites, current rank, and resulting effect. Material progress should be visible as progress toward a goal, not hidden in a tooltip.

## Archetypes

These archetypes are not fixed classes. They are design anchors that help keep branches distinct.

### Sniper

Long range, slow fire, high damage per shot, high crit value, strong piercing.

Possible strengths:

- Range.
- First-shot damage.
- Crit damage.
- Crit chance against high-health targets.
- Piercing shots.
- Overkill conversion into secondary damage.

Possible tradeoffs:

- Lower fire rate.
- Less effective against dense swarms unless built into piercing or ricochet.
- Expensive material gates using steel, circuits, radar, processing units.

### Machine Gun

Very high fire rate, lower damage per bullet, swarm control, ammo-flow mastery.

Possible strengths:

- Shooting speed.
- Ammo efficiency.
- Ricochet or bounce chance.
- Suppression effects.
- Proc frequency for low-damage elemental effects.

Possible tradeoffs:

- Lower damage per shot.
- Higher ammo demand unless invested into logistics perks.
- Worse armor penetration without kinetic or acid investment.

### Short-Range Heavy

Reduced range, heavy damage, splash or cone-like behavior, durable front-line identity.

Possible strengths:

- Close-range damage multiplier.
- Explosion or shrapnel effects.
- Knockback, slow, or stun.
- Bonus armor and HP.
- Strong self-repair while fighting.

Possible tradeoffs:

- Lower range.
- High material cost.
- Positioning matters more.

### Bulwark

Survivability, self-healing, resistance, and reliable holding power.

Possible strengths:

- Max HP.
- Resistance against acid, fire, or physical damage.
- Life regeneration.
- Self-healing after kills or while loaded.
- Vampirism-style healing from damage dealt.
- Emergency shield-like thresholds.
- Nearby wall repair support as a later feature.

Possible tradeoffs:

- Lower peak damage.
- Fewer offensive combo nodes.
- Risky sustain nodes may require the turret to keep fighting to remain healthy.

### Overdrive

Risk-reward upgrades that spend turret HP for temporary combat bonuses.

Possible strengths:

- Fire-rate bursts that drain HP while active.
- Extra damage or crit chance while below a health threshold.
- Self-damage to trigger shockwaves, shrapnel, or emergency burn effects.
- Converting regeneration into temporary offensive power.
- Vampirism loops where damage output can recover overdrive costs if enemies keep coming.

Possible tradeoffs:

- Can leave the turret vulnerable after a wave.
- Needs clear safeguards so the turret does not casually destroy itself.
- Should pair naturally with max HP, regeneration, vampirism, repair packs, and defensive material gates.

Design guardrails:

- Self-damage effects should have a minimum HP threshold or automatic shutoff.
- The GUI should clearly show active risk, current drain, and whether the turret can survive the next activation.
- Overdrive should feel like an aggressive build choice, not a hidden tax on normal damage perks.

### Elementalist

Status effects, duo-element combos, luck scaling, and tactical damage conversion.

Possible strengths:

- Elemental status chance.
- Combo mechanics.
- Damage-over-time.
- Chain effects.
- Debuffs that help nearby turrets.

Possible tradeoffs:

- Needs material gates and element slots before it comes online.
- Should not out-DPS every physical build by default.
- Performance must be watched carefully if effects spawn many projectiles, render objects, or area checks.

### Veteran Support

XP gain, luck, ammo economy, and reliability.

Possible strengths:

- XP boost.
- Luck scaling.
- Ammo conservation.
- Better kill-credit conversion.
- Small aura-like support later, if performance and readability allow it.

Possible tradeoffs:

- Lower immediate combat power.
- Should be a valid support identity, not the mandatory optimal route for every turret.

## Duo-Element Combos

The second element should transform the turret's identity. Pure pairs should specialize. Mixed pairs should create a mechanic that neither element has alone.

Example combo directions:

- **Fire + Fire:** stronger burns, longer burn duration, fire-focused area denial.
- **Fire + Electric:** arcing shots can ignite secondary targets.
- **Fire + Acid:** burning corrosion that weakens resistance while damage-over-time runs.
- **Fire + Explosive:** incendiary shrapnel or small burning bursts.
- **Electric + Electric:** stronger chain arcs, brief stuns, better target jumping.
- **Electric + Kinetic:** railgun-style piercing shots with crit synergy.
- **Electric + Acid:** conductive corrosion that increases chain chance on debuffed targets.
- **Acid + Acid:** deep armor shred and stacking vulnerability.
- **Acid + Kinetic:** armor-piercing corrosion rounds.
- **Explosive + Kinetic:** shrapnel bursts, ricochet fragments, overkill splash.
- **Poison + Fire:** toxic combustion clouds or burn-triggered poison bursts.
- **Poison + Acid:** long-duration biological denial and resistance pressure.

The exact list can start small. It is better to ship a few readable, well-balanced combos than a large matrix of shallow effects.

## Luck

Luck should be a real stat, but it needs guardrails.

Luck can affect:

- Crit chance.
- Ricochet chance.
- Pierce continuation chance.
- Elemental proc chance.
- Chance to refund ammo.
- Chance to gain bonus XP or kill credit.
- Chance for vampiric heals, emergency repairs, or overdrive refunds when those perks are present.

Luck should not simply multiply every random effect without limit. A good model is:

- Base chance comes from the perk or element.
- Luck adds a smaller secondary modifier.
- Effective chance has a cap or diminishing returns.
- Some builds convert excess luck into reliability or small secondary benefits.

This lets "lucky" turrets feel different without making randomness explode into balance problems.

## Materials And Delivery Model

The preferred design is a **turret investment ledger**.

The player opens the turret and sees material goals attached to locked nodes or branch gates. Supplying materials fills those goals. Once a goal is complete, the unlock stays permanently on that turret.

Possible delivery approaches:

- Direct deposit through the Turret XP GUI.
- Later: logistic request integration or nearby chest consumption.
- Later: construction-bot delivery for large upgrade projects.
- Later: blueprint or copy-paste support for desired upgrade plans.

The first implementation can be manual and explicit. Automation can come later after the material economy feels right.

Material gates should be used for:

- Unlocking archetype depth.
- Unlocking the first and second element slots.
- Unlocking rank caps for major perks.
- Unlocking infinite mastery nodes.
- Paying for major hardware transformations.
- Unlocking sustain and overdrive systems such as reinforced chassis, repair cores, vampiric siphons, or unstable high-output firing modes.

Skill points and materials should both matter. A turret with XP but no materials has learned but not been rebuilt. A turret with materials but no XP has hardware potential but no combat identity.

## Portable Veteran Core

Turret progression should be movable, but not for free. V0.4.1 implements the first draft of this model, and V0.4.2 makes specialization stats travel with the core by swapping the current turret body.

The chosen design is a craftable non-stackable **Veteran Core**. Installing it in a turret marks that turret as a committed progression turret. When the turret is picked up, its XP and evolution state are stored on the core item, making it a distinct inventory item that can later be installed into another turret.

Design goals:

- Make mobility a conscious player choice, not the default for every cheap turret.
- Preserve the fantasy that the turret's combat memory lives in a physical component.
- Keep ordinary early-game turrets stackable and disposable.
- Let important veteran turrets be moved to new front lines without losing identity.
- Create a natural place for item metadata, custom labels, quality, and tooltip summaries.

Suggested availability:

- Mid-early game, after the player has automated green circuits and steel.
- Expensive enough that the player does not install one in every turret immediately.
- Cheap enough that moving a beloved early frontier turret feels achievable before late game.

First implemented recipe:

- Electronic circuit x20.
- Steel plate x10.
- Copper cable x40.
- Repair pack x2.

Possible upgraded recipe later:

- Advanced circuit.
- Processing unit.
- Battery.
- Low density structure or electric engine for late-game stronger cores.

The first implemented icon is a vanilla layered placeholder using the electronic circuit and gun turret icons. A generated Factorio-style 64x64 icon is still desirable later: a compact brass/steel circuit core, with a small turret silhouette or targeting reticle and a glowing memory crystal. It should read as industrial and functional rather than magical.

Implemented first pass:

- Adds an `item-with-tags` prototype for the portable core.
- Sets stack size to 1 so each veteran core is unique.
- Stores serialized turret XP/evolution state in item tags.
- Adds install/extract controls in the Turret XP panel.
- On turret pickup, if a core is installed, returns the normal turret item through vanilla mining and separately returns or spills the tagged core.
- On installation, reads the core tags and restores the profile to the new turret host.
- Does not allow two active turrets to share the same core ID.
- Lets the player name the core profile and optionally draw a floating `name (lvl N)` label above the current turret body.

Open design questions:

- Should the core recipe include a gun turret, or should it stay as a pure electronics/repair component?
- Should installing a core be reversible before the turret earns XP?
- Should a core bind to one force or remain tradable between players/forces?
- Should the core carry ammo/project/material-project progress, or only XP and evolution?
- Should quality on the core affect XP gain, memory capacity, element slots, or respec cost?
- Should destroyed turrets always destroy the installed core, drop a damaged core, or have a recovery chance?
- Should floating labels be always visible, alt-mode only, or configurable?

## Example Player Loop

1. The player builds a defensive line.
2. Turrets that survive real attacks earn XP and levels.
3. A turret levels up and gains a skill point.
4. The player opens the turret, reviews the Evolution list, and chooses an early direction.
5. A deeper branch shows a material gate, such as steel and circuits for sniper optics.
6. The player delivers materials to that turret as a localized factory goal.
7. The gate unlocks, enabling stronger perks or an element slot.
8. The player chooses a first element, then later a second element.
9. The second element unlocks combo nodes, making the turret's identity more distinct.
10. Late-game repeatable mastery nodes absorb excess XP and very large material investments.

## Balance Guardrails

- Do not let every branch stack cleanly into one universal best turret.
- Prefer tradeoffs: range for fire rate, fire rate for damage per shot, survivability for peak damage, XP gain for immediate power.
- Treat HP as an active design axis, not only a bigger buffer: max HP, regeneration, vampirism, and self-damaging overdrive should each carry different risks and costs.
- Keep effects readable in combat. If a turret causes bouncing, piercing, burning, acid, electric, and explosions all at once, the identity becomes noise.
- Keep script-heavy effects limited. Chain arcs, bounces, area damage, and status tracking need performance budgets.
- Use material gates to make deep specialization deliberate.
- Use infinite scaling for prestige and long-term ownership, not for replacing base defense design.
- Make respec a deliberate question. Free respec makes choices feel cheap; no respec can punish experimentation during playtesting.

## Open Questions

- Should turret XP and upgrades survive mining, and if so, should they transfer through item tags or a separate recovery mechanic?
- Should element choices be permanent, expensive to reset, or freely swappable during early playtests?
- Should material investment be per turret only, or should some gates be force-wide once discovered?
- Should material delivery be manual-only at first, or should the first version include logistic integration?
- Which damage types should ship first for vanilla gun turrets: kinetic, fire, electric, acid, explosive, poison, or a smaller subset?
- How much should modded ammo influence available elemental paths?
- Should infinite mastery consume only materials, only XP, or both?
- How much should nearby support or aura behavior exist, given performance and readability constraints?
- Should self-damage overdrive be manually toggled, automatically triggered by conditions, or represented as passive always-on risk?
