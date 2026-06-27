# Agent Instructions

These instructions apply to the whole repository.

## Project Context

- `turret_xp` is a Factorio 2.0 mod, currently version `0.11.3`, published from `atyrode/turret_xp`.
- The mod lets selected vanilla gun turrets become persistent veteran defenders. Veteran Cores carry XP, levels, upgrades, elements, specializations, labels, combat history, and optional bound turret movement.
- Current progression is scoped to vanilla `gun-turret`.
- Required dependencies are `base >= 2.0.0` and `flib >= 0.16.4`; optional compatibility includes `Krastorio2-spaced-out` and `bullet-trails >= 0.7.1`.
- Durable runtime state lives under `storage.turret_xp`. Tagged `item-with-tags` stacks are part of the persistence surface, not transient UI state.

## Repository Layout

- `info.json`: Factorio mod metadata and release version source.
- `changelog.txt`: Factorio-compatible release history.
- `control.lua`: runtime composition root for modules under `scripts/control/`.
- `data.lua` and `data-final-fixes.lua`: data-stage entrypoints for prototype modules under `prototypes/`.
- `scripts/domain.lua`: shared stable gameplay IDs, caps, specialization data, label presets, and generated variant-name helpers used by data stage, runtime, and tests.
- `scripts/control/`: runtime modules for storage, profiles, progression, feeder logistics, stats, GUI, core-slot actions, combat effects, migrations, commands, and compatibility facades.
- `prototypes/`: data-stage modules for names, items, feeder, styles, effects, turret variants, bound turret placeholders, bound preview variants, and ammo range compatibility.
- `migrations/`: one-time Factorio prototype/storage migrations only; profile and tagged-item shape compatibility normally belongs in runtime normalization.
- `locale/en/turret-xp.cfg`: English strings.
- `tests/headless/`: temporary Factorio companion mods for deterministic regression and remote-policy checks.
- `tests/gui-snapshots/`: graphical-client snapshot harness and generated local review output.
- `docs/`: product, requirements, architecture, technical direction, design, playtest, public copy, and generated website source.

## Local Architecture Rules

- Keep `control.lua`, `data.lua`, and `data-final-fixes.lua` thin. Put runtime behavior in `scripts/control/`, data-stage behavior in `prototypes/`, and shared domain facts in `scripts/domain.lua`.
- Prefer explicit returned-table modules and dependency wiring over expanding legacy `_ENV` shared-runtime patterns. Compatibility facades are acceptable while callers migrate.
- Namespace custom prototype, style, sprite, setting, command, and GUI names with `turret-xp` or `turret_xp` according to the existing file's convention.
- Preserve published save/profile compatibility where practical. Use `scripts/control/profile_schema.lua`, `profile_tags.lua`, `profile_inventory.lua`, and `migrations.lua` for current schema normalization and tagged-item compatibility.
- Protect `item-with-tags` data for Veteran Cores and bound veteran turrets. Inventory, mining, placement, platform hub, and GUI transfer paths must preserve tags exactly.
- Hidden prototype growth is a design decision, not routine implementation. Specialization/sub-specialization turret bodies and bound preview item/placeholders are the accepted prototype-backed axes; Shield, Resistance, Regeneration, Ammo Productivity, Shield on Hit, and Lifesteal stay script/profile-owned unless explicitly redesigned.
- The private `turret_xp_test` remote interface must remain gated to `turret_xp_headless_tests` and `turret_xp_gui_snapshots`. Normal gameplay and packaged releases must not expose it.

## Gameplay Contracts

- Ordinary gun turrets stay stackable until a Veteran Core is installed.
- New core profiles start at level 0 with zero XP, combat history, custom name, label flag, and evolution choices.
- XP counters are separate from raw display totals. `xp_damage` and `xp_kill_credit` receive surface, target, platform travel, and Veteran Training weights at award time; raw damage and kill credit remain display/history totals.
- The invisible hidden feeder on the turret tile is the accepted material-input model for passive element ranks. It should forward ammo to the turret, accept only selected element materials, clean up wrong items, and manage nearby inserter targets only when those inserters are actually sourcing needed materials.
- Bound veteran turrets are non-stackable tagged items that place a hidden bound-only placeholder before runtime converts it into a real gun turret with the stored profile, quality, health ratio, and ammo snapshot. Normal gun-turret ghosts should keep requesting normal gun turrets, not bound veteran items.
- Platform turrets use explicit Turret XP panel actions to install exact Veteran Cores from the platform hub inventory and send installed cores back to that hub.
- Combat visual/sound budgets may skip cosmetics only. Damage, XP, lifesteal, status ticks, and other gameplay mechanics must not depend on visual budget availability.

## GUI Rules

- `flib` is the accepted runtime GUI foundation.
- Keep the Turret XP panel Factorio-native and anchored to the vanilla turret GUI where practical.
- Avoid top-level GUI size churn while the vanilla turret GUI is open. Prototype body swaps should remain deferred until close when needed to avoid moving the vanilla window back to its default position.
- Preserve reserved scrollbar space and bounded pane sizing in Stats, Evolution, and the empty-core picker; values and controls must not render under scrollbars.
- Future major GUI replacement work is spec-first. Use `docs/GUI_SPEC_FACTORY.md` and `docs/TURRET_XP_GUI_SPEC.md` rather than reviving old layout branches as the source of truth.

## Documentation Ownership

- Root `README.md`: repository entry point, player overview, install path, common commands, release workflow pointers, and documentation index.
- `docs/PROJECT_BRIEF.md`: product intent, current scope, non-goals, and open product boundaries.
- `docs/REQUIREMENTS.md`: user-visible obligations and expected outputs.
- `docs/PROJECT_SPEC.md`: current implemented behavior for the active development line.
- `docs/ARCHITECTURE.md`: runtime/data/test ownership, storage shape, module boundaries, and invariants.
- `docs/TECHNICAL_DIRECTION.md`: technical choices, research memory, dependencies, API notes, risks, and validation paths.
- `docs/DESIGN.md`: gameplay direction, UX direction, balance intent, compatibility posture, public identity, and feedback goals.
- `docs/DEVELOPMENT_STEPS.md`: current baseline, completed foundations, near-term roadmap, and validation checklist.
- `docs/PLAYTEST.md`: smoke, regression, deep manual, compatibility, platform, and report-back paths.
- `docs/public-copy.json`: shared public copy source for homepage, GitHub Release notes, and Mod Portal details.
- `docs/index.html`: generated GitHub Pages homepage. Do not hand-edit duplicated homepage copy; update the source files and regenerate it.

## Validation

- For AGENTS or internal docs-only changes, run `scripts/check.sh` and `git diff --check`.
- For `README.md`, `changelog.txt`, or `thumbnail.png` changes, run `scripts/check.sh`, `scripts/package.sh`, and `git diff --check`.
- For public copy, version, changelog, or homepage changes, run `scripts/generate-public-assets.py`, `scripts/generate-public-assets.py --check`, and `git diff --check`.
- For Lua/runtime/tooling changes, run `scripts/check.sh`, `docker compose run --rm lua-format`, `docker compose run --rm lua-tools`, and `scripts/package.sh`.
- For gameplay, migration, feeder, combat, profile, or test-surface changes, include `scripts/test-headless.sh` when a local Factorio binary is available or state why it could not be run.
- For GUI layout changes, include manual in-game visual review or the GUI snapshot workflow from `docs/PLAYTEST.md`; state remaining visual-review risk when local playtesting is not performed.
- `scripts/check.sh` is host-friendly and skips optional Lua tools that are not installed. Docker Compose provides the pinned strict StyLua, Lua 5.2 syntax, and Luacheck path used by CI.

## Release And Generated Files

- Do not publish Mod Portal releases from a local checkout. The supported path is the GitHub Release workflow using repository secrets.
- Standard release source changes update `info.json`, `changelog.txt`, and generated public assets together before merging to `main`.
- `scripts/generate-public-assets.py` owns `docs/index.html`, GitHub Release notes, and Mod Portal copy generated from `info.json`, `changelog.txt`, and `docs/public-copy.json`.
- `scripts/release.sh` is only a local GitHub Release fallback. It should run from a clean, up-to-date `main`.
- Do not commit local build/runtime/research artifacts such as `dist/`, `.factorio-ci/`, `.codex_tmp/`, `case_study/`, `.env`, GUI snapshot review output, logs, or Mod Portal credentials.
