# Development Steps

This file tracks current work, validation checkpoints, and near-term roadmap only. Version-by-version release history belongs in the Factorio-compatible root [changelog.txt](../changelog.txt), which is included in packaged mod zips and should be reused by release and website automation.

## Current Baseline

- Main development line: `0.10.3`.
- Stable branch policy: short-lived issue branches into protected `main`; releases are GitHub Releases/tags named `v<info.json version>`.
- Required local lightweight check: `scripts/check.sh`.
- Strict local Lua tooling without host installs: `docker compose run --rm lua-tools`.
- Package build: `scripts/package.sh`.
- Gameplay regression suite: `scripts/test-headless.sh` when a local Factorio binary is available.
- CI runs strict Lua tooling and packaging for package-impacting changes, and headless Factorio tests when Mod Portal download credentials are configured.

## Completed Foundations

- CI/release automation exists for package validation, cached Factorio headless tests, GitHub Release packaging, and gated Mod Portal publishing.
- `main` is protected through pull requests and selected required status checks.
- The private `turret_xp_test` remote interface is gated to the headless companion test mod and checked by a separate production-policy smoke test.
- Runtime code has been split into focused modules under `scripts/control/`, with explicit helper modules for bound turret item handling, damage accounting, GUI support, Factorio API compatibility, and label color matching.
- Data-stage prototype creation is split under `prototypes/`, with entrypoints kept small.
- `scripts/domain.lua` owns shared stable gameplay IDs, caps, specialization data, label presets, and generated variant-name helpers across data stage, runtime, and tests.
- Lua formatting and linting are enforced through StyLua, Luacheck, Lua 5.2 syntax checks, CI, and the local Docker Compose tooling path.
- The headless suite covers the current hidden prototype budget, bound turret movement and ammo conservation, modded base turret range inheritance, turret-source projectile ammo range compatibility, damage accounting, GUI helper samples, compatibility helper samples, feeder routing, passive element progress, Resistance, Max HP, Ammo Recovery, status damage, and gated remote policy.
- The invisible feeder remains the accepted material-input model and is documented as a narrow contract with headless coverage for lifecycle, ownership cleanup, source-aware filter priority, no-source non-management, restoration, ammo forwarding, wrong-item cleanup, mixed-element requests, and passive material progress.
- Public homepage, GitHub release notes, and Mod Portal copy are generated from `info.json`, `changelog.txt`, and `docs/public-copy.json`, with `scripts/check.sh` detecting stale committed homepage output.

## Current Roadmap

- Isolate legacy migrations and retire stale element-project paths once save-compatibility policy is explicit.
- Refactor combat effects into descriptors with explicit scan, visual, status, and damage-accounting budgets.
- Componentize GUI panels and localize hardcoded player-facing strings.

## Validation Checklist

Use the narrowest meaningful checks for each change:

- Documentation-only changes: `scripts/check.sh`, `git diff --check`.
- Public copy, version, changelog, or homepage changes: `scripts/generate-public-assets.py`, `scripts/generate-public-assets.py --check`, `git diff --check`.
- Lua/runtime/tooling changes: `scripts/check.sh`, `docker compose run --rm lua-tools`, `scripts/package.sh`.
- Gameplay, migration, feeder, combat, profile, or test-surface changes: all Lua/runtime checks plus `scripts/test-headless.sh`.
- Release changes: local script smoke checks where practical, CI on the release branch, and the GitHub Release workflow before Mod Portal publication.
- Website changes: inspect generated `docs/index.html` locally or in the built GitHub Pages output, and confirm public links point to current docs.

## Playtest Focus

- Bound turret ammo conservation, including full inventories and placement-helper mods.
- Hidden material input readability with normal, fast, stack, and bulk inserter layouts.
- Passive element rank progress visibility and wrong-item recovery.
- Fire burn and Toxic poison readability in real combat.
- Resistance feel against common enemy attacks and lethal-hit edge cases.
- Max HP, Regeneration, Ammo Recovery, and Lifesteal balance in long fights.
- Level gates at 10, 20, 30, 40, and 50.
- Sniper, Machine Gun, Bulwark, Brawler, and sub-specialization identity clarity.
- Space-platform core selection and asteroid XP pacing.
- Optional Bullet Trails density and readability.
- K2/K2SO-style projectile ammo range compatibility.

## Open Decisions

- Save compatibility policy for old published and development versions.
- Long-term hidden feeder direction: invisible input, visible proxy, manual/project slot, or hybrid.
- Combat visual density budget for busy defenses.
- Whether combat-effect refactors should be behavior-preserving only or include approved balance changes.
- Destroyed turret policy for installed Veteran Cores.
