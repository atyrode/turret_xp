# Development Steps

This file tracks current work, validation checkpoints, and near-term roadmap only. Version-by-version release history belongs in the Factorio-compatible root [changelog.txt](../changelog.txt), which is included in packaged mod zips and should be reused by release and website automation.

## Current Baseline

- Main development line: `0.10.4`.
- Stable branch policy: short-lived issue branches into protected `main`; releases are GitHub Releases/tags named `v<info.json version>`.
- Required local lightweight check: `scripts/check.sh`.
- Strict local Lua tooling without host installs: `docker compose run --rm lua-tools`.
- Lua validation file discovery follows Git ignore rules, so tracked files and untracked non-ignored Lua files are checked while ignored local research/build corpora are excluded.
- Package build: `scripts/package.sh`.
- Gameplay regression suite: `scripts/test-headless.sh` when a local Factorio binary is available.
- GUI screenshot artifacts: `scripts/gui-screenshots.sh` when a graphical Factorio binary is available.
- Externally visible publish scripts: `scripts/release.sh` for GitHub Releases and `scripts/publish-portal.sh` for the stable Mod Portal path; both require release preflight on clean, up-to-date `main`.
- CI runs strict Lua tooling and packaging for package-impacting changes, and headless Factorio tests when Mod Portal download credentials are configured.
- Package-impacting changes are root `README.md`, `changelog.txt`, `thumbnail.png`, package source, package scripts, and validation infrastructure; internal `docs/` and generated public-site files are not mod package payload.

## Completed Foundations

- CI/release automation exists for package validation, cached Factorio headless tests, GitHub Release packaging, and gated Mod Portal publishing.
- `main` is protected through pull requests and selected required status checks.
- The private `turret_xp_test` remote interface is gated to the headless companion test mod and checked by a separate production-policy smoke test.
- Documentation ownership is split by durable truth: product intent, requirements, current spec, architecture, technical direction, design direction, future-only progression notes, development workflow, and playtest paths each have one owning document.
- Runtime code has been split into focused modules under `scripts/control/`, with explicit helper/service modules for Veteran Core profile schema/tags/inventory/labels/orchestration, hidden feeder lifecycle/inventory/inserter/refresh ownership, bound turret item handling, damage accounting, combat effect descriptors/application/targeting/visuals/scheduler/dispatch/budgets, GUI support/components, Factorio API compatibility, label color matching, stat math/inspection/formatting, GUI actions, and command registration.
- Runtime config ownership is split so `config.lua` wires domain aliases plus progression definitions, GUI constants, and runtime constants from explicit returned-table modules instead of carrying all constants directly.
- Data-stage prototype creation is split under `prototypes/`, with entrypoints kept small.
- `scripts/domain.lua` owns shared stable gameplay IDs, caps, specialization data, label presets, and generated variant-name helpers across data stage, runtime, and tests.
- Data-stage prototype generation now uses `scripts/domain.lua` for shared base turret and Turret XP body naming in turret variants, bound placeholders, bound previews, and ammo range compatibility.
- Lua formatting and linting are enforced through StyLua, Luacheck, Lua 5.2 syntax checks, CI, and the local Docker Compose tooling path.
- The headless suite is split by subsystem and covers the current hidden prototype budget, bound turret movement and ammo conservation, modded base turret range inheritance, turret-source projectile ammo range compatibility, damage accounting, combat effect descriptor/budget samples, GUI helper samples, compatibility helper samples, feeder routing, passive element progress, Shield, Resistance, Ammo Productivity, status damage, and gated remote policy.
- The invisible feeder remains the accepted material-input model and is documented as a narrow contract with headless coverage for lifecycle, ownership cleanup, source-aware filter priority, no-source non-management, restoration, ammo forwarding, wrong-item cleanup, mixed-element requests, and passive material progress.
- Published save/profile compatibility now lives in a named migration compatibility layer with headless coverage for legacy element slots, active element projects, retired element fuel buffers, retired augments, and old skill-tree ranks.
- GUI dependency direction is decided for the next major GUI pass: `flib` is an accepted runtime foundation, dependencies are allowed when they earn their cost, and the product target is a custom Factorio-native Turret XP interface with focused local helpers rather than a generic inherited framework.
- The 0.11 GUI glowup has started with an anchored `flib.gui` shell service. The panel should remain attached to the vanilla turret GUI when possible while adopting Factory Planner-style hierarchy, shallow content panes, reusable local builders, and explicit GUI service ownership.
- GUI widget action routing now lives in `scripts/control/gui/actions.lua`, keeping Factorio event registration thinner while preserving the existing `scripts/control/actions.lua` gameplay mutation service.
- Public homepage, GitHub release notes, and Mod Portal copy are generated from `info.json`, `changelog.txt`, and `docs/public-copy.json`, with `scripts/check.sh` detecting stale committed homepage output.
- High-complexity scope is decided for the current hardening line: keep/harden hidden feeder automation, keep optional bound turret movement, keep prototype-bound native stats limited to specialization/sub-specialization bodies, keep element combos curated and limited, and require separate approval for new progression systems.

## Current Roadmap

- Harden the current playable loop before adding progression scope. Balance/readability fixes, GUI quality, validation, and bug fixes are in scope; new branches, elements, mastery loops, quality-backed chassis work, range-band rewrites, repeatable HP/Range axes, or other prototype-backed stat axes need separate approved issues.
- Keep documentation edits ownership-based: move facts to the owning document, replace duplicates with cross-references, and delete stale planning prose once the current decision is represented elsewhere.
- Continue the 0.11 GUI glowup in focused slices: migrate section-local builders into explicit GUI services, improve Veteran Core/Evolution interaction density, and use screenshot/playtest checkpoints for visual regressions. Do not mix that work with balance or progression-system expansion.

## Validation Checklist

Use the narrowest meaningful checks for each change:

- Internal documentation-only changes: `scripts/check.sh`, `git diff --check`.
- Root `README.md`, `changelog.txt`, or `thumbnail.png` changes: `scripts/check.sh`, `scripts/package.sh`, `git diff --check`.
- Public copy, version, changelog, or homepage changes: `scripts/generate-public-assets.py`, `scripts/generate-public-assets.py --check`, `git diff --check`.
- Lua/runtime/tooling changes: `scripts/check.sh`, `docker compose run --rm lua-tools`, `scripts/package.sh`.
- Gameplay, migration, feeder, combat, profile, or test-surface changes: all Lua/runtime checks plus `scripts/test-headless.sh`.
- GUI layout changes: all Lua/runtime checks plus `scripts/gui-screenshots.sh` when a graphical Factorio binary is available; otherwise state the remaining manual visual-review risk.
- Runtime bug fixes: add or extend the narrowest deterministic headless or pure Lua regression test in the owning subsystem, or state why the behavior needs manual GUI/playtest validation instead.
- Release changes: local script smoke checks where practical, CI on the release branch, and the GitHub Release workflow before Mod Portal publication.
- Release preflight changes: `bash -n scripts/release-preflight.sh scripts/release.sh scripts/publish-portal.sh`, synthetic git-state checks, `scripts/check.sh`, `scripts/package.sh`, and `git diff --check`.
- Website changes: inspect generated `docs/index.html` locally or in the built GitHub Pages output, and confirm public links point to current docs.

## Playtest Focus

Use [PLAYTEST.md](PLAYTEST.md) as the owning checklist. It separates quick smoke coverage from regression, deep manual, compatibility, platform, and long-fight balance paths.

## Open Decisions

- Destroyed turret policy for installed Veteran Cores.
