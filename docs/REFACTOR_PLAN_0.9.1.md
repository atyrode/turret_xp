# V0.9.1 Refactor Plan

V0.9.1 is a refactor-first patch. Its purpose is to make Turret XP easier to maintain before the Veteran Core slot is made more inventory-like.

## Goals

- Keep gameplay behavior stable except for targeted UI polish and clearer element respec wording.
- Keep `control.lua`, `data.lua`, and `data-final-fixes.lua` as entrypoints instead of implementation monoliths.
- Preserve the existing `storage.turret_xp` save schema and Veteran Core `item-with-tags` profile format.
- Keep the attached vanilla turret GUI extension rather than switching to a full custom GUI in this patch.
- Make the current two-column UI narrower and prevent Evolution content from rendering under its scrollbar.

## Runtime Modules

- `scripts/control/config.lua`: constants, upgrade definitions, gates, colors, combat constants, and layout constants.
- `scripts/control/storage.lua`: storage setup, player state, settings lookup, turret keys, and force modifier sync.
- `scripts/control/progression.lua`: XP counters, level math, evolution normalization, points, and element fuel state.
- `scripts/control/profiles.lua`: Veteran Core profiles, item tags, bound turret items, platform core lookup, and floating labels.
- `scripts/control/turret_bodies.lua`: hidden turret body swaps and deferred body sync.
- `scripts/control/feeder.lua`: hidden feeder lifecycle, allowed material routing, inserter targeting, filters, and ammo forwarding.
- `scripts/control/stats.lua`: ammo/stat derivation, quality summaries, damage contribution, kill credit, and stat formatting.
- `scripts/control/gui_base.lua` and `scripts/control/gui_panels.lua`: GUI lookup, stable updates, stats panel, core panel, and Evolution rendering.
- `scripts/control/core_slot.lua`: Veteran Core install, extract, swap, cursor, platform core, and bind/unbind actions.
- `scripts/control/actions.lua`: Evolution allocation, section reset/change actions, dev actions, and passive effects.
- `scripts/control/combat_effects.lua`: runtime damage effects, healing, proc logic, sounds, and visual feedback.
- `scripts/control/events.lua`, `scripts/control/commands.lua`, and `scripts/control/remote_test.lua`: Factorio event wiring, commands, and headless-test interface.

## Data Modules

- `prototypes/names.lua`: shared prototype names and label color presets.
- `prototypes/feeder.lua`: hidden inserter-fed input entity.
- `prototypes/label_panels.lua`: hidden display-panel label variants.
- `prototypes/effects.lua`: vanilla-derived element effect and sound prototypes.
- `prototypes/items.lua`: Veteran Core, bound veteran turret item, recipe, and unlock.
- `prototypes/styles.lua`: custom GUI styles.
- `prototypes/turret_variants.lua`: hidden specialization and Range turret variants generated in final fixes.

## Veteran Core Slot Boundary

Factorio custom GUI exposes slot-like controls through widgets such as `sprite-button`, but it does not expose an arbitrary native inventory slot that can be inserted into the vanilla turret inventory GUI. V0.9.1 keeps the current tag-preserving scripted slot behavior and moves it behind `scripts/control/core_slot.lua`.

Future slot work should build on that boundary: exact-core inventory lists, platform selection, cursor swap, and shift-transfer behavior should preserve `item-with-tags` profile data. Do not add `entity-gui-lib` or replace the whole turret GUI unless a separate spike proves that it materially improves tagged-core transfer and player-inventory ownership.

## Validation

Before publishing any refactor patch, run:

```sh
scripts/check.sh
scripts/package.sh
scripts/test-headless.sh
```

The headless suite must continue to cover profile tag preservation, core install/extract, bound turret round trips, mixed-element feeder routing, fuel caps, modded base turret range inheritance, XP weighting, kill credit, and Evolution section resets.
