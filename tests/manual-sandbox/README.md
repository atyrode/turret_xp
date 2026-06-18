# Turret XP Manual Sandbox

This folder contains the local graphical/manual testing companion for Turret XP. It is intentionally not part of the packaged Mod Portal release.

## Workflow

1. Install the local package and sandbox companion:

   ```sh
   scripts/sandbox.sh install
   ```

2. Start Factorio with `turret_xp`, `flib`, and `turret_xp_sandbox` enabled.

3. Load a disposable development save and run:

   ```text
   /turret-xp-sandbox build
   ```

The command creates a separate `turret_xp_sandbox` surface, teleports the player there, inserts a few sample Veteran Core items, and lays out labeled scenarios for manual inspection.

## Commands

```text
/turret-xp-sandbox build
/turret-xp-sandbox list
/turret-xp-sandbox goto <scenario-id>
/turret-xp-sandbox items
/turret-xp-sandbox destroy
```

`build` is idempotent for the surface layout. It does not remove sample Veteran Core items from player inventories; run `items` only when you want another sample set.

## Initial Scenarios

- `core`: empty picker, installed core, and bound quick-move fixtures.
- `evolution`: level-gated GUI states and a fully evolved sample build.
- `feeder`: ammo forwarding, material routing, mixed elements, and wrong-item cleanup cases.
- `combat`: Shield, Resistance, Ammo Productivity, elemental effects, and XP-readable combat fixtures.
- `automation`: preset application, conflict preservation, empty core requests, and delivered-core setup policy.

The sandbox reuses Turret XP's private `turret_xp_test` remote API. The main mod only registers that API while a test companion such as this sandbox is active.
