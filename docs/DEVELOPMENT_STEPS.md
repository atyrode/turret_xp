# Development Steps

This file tracks current work, validation checkpoints, and near-term roadmap only. Version-by-version release history belongs in the Factorio-compatible root [changelog.txt](../changelog.txt), which is included in packaged mod zips and should be reused by release and website automation.

## Current Baseline

- Main development line: `0.12.0`.
- Stable branch policy: short-lived issue branches into protected `main`; releases are GitHub Releases/tags named `v<info.json version>`.
- Required local lightweight check: `scripts/check.sh`.
- Strict local Lua tooling without host installs: `docker compose run --rm lua-tools`.
- Lua formatting without host installs: `docker compose run --rm lua-format`.
- Optional local Git hooks: `scripts/install-git-hooks.sh` configures this clone to run Dockerized strict Lua tooling before commits that stage Lua or Lua-tooling changes.
- Lua validation file discovery checks tracked source plus untracked non-ignored Lua source, explicitly excludes local build/runtime caches such as `.factorio-ci/`, `dist/`, `.codex_tmp/`, and `case_study/`, and has a regression check in `scripts/check.sh` so downloaded Factorio data cannot be linted as mod source.
- Package build: `scripts/package.sh`.
- Gameplay regression suite: `scripts/test-headless.sh` when a local Factorio binary is available. Passing runs print hidden-prototype budget, Factorio benchmark timing, and process CPU/max-RSS metrics when the platform exposes them.
- Standard release trigger: merge a release PR into `main` with an unreleased `info.json` version and matching `changelog.txt` entry; Auto Release creates the missing GitHub Release/tag and dispatches the Release workflow when the package asset is missing.
- Externally visible release helper fallback: `scripts/release.sh` creates or updates the signed GitHub Release/tag after release preflight on clean, up-to-date `main`.
- Mod Portal releases are not published from local checkouts. The GitHub Release workflow publishes the exact GitHub Release package asset to the Mod Portal.
- CI runs strict Lua tooling and packaging for package-impacting changes, and headless Factorio tests when Mod Portal download credentials are configured.
- Package-impacting changes are root `README.md`, `changelog.txt`, `thumbnail.png`, package source, package scripts, and validation infrastructure; internal `docs/` and generated public-site files are not mod package payload.

## Completed Foundations

- CI/release automation exists for package validation, cached Factorio headless tests, automatic GitHub Release creation from unreleased `main` versions, GitHub Release packaging, and Mod Portal publishing.
- `main` is protected through pull requests and selected required status checks.
- The private `turret_xp_test` remote interface is gated to the headless companion test mod and checked by a separate production-policy smoke test.
- Documentation ownership is split by durable truth: product intent, requirements, current spec, architecture, technical direction, design direction, future-only progression notes, development workflow, and playtest paths each have one owning document.
- Runtime code has been split into focused modules under `scripts/control/`, with explicit helper/service modules for Veteran Core profile schema/tags/inventory/labels/orchestration, hidden feeder lifecycle/inventory/inserter/refresh ownership, bound turret item handling, damage accounting, combat effect descriptors/application/targeting/visuals/scheduler/dispatch/budgets, GUI support/components, Factorio API compatibility, label color matching, stat math/inspection/formatting, GUI actions, and command registration.
- Runtime config ownership is split so `config.lua` wires domain aliases plus progression definitions, GUI constants, and runtime constants from explicit returned-table modules instead of carrying all constants directly.
- Data-stage prototype creation is split under `prototypes/`, with entrypoints kept small.
- `scripts/domain.lua` owns shared stable gameplay IDs, progression gates, caps, specialization data, label presets, and generated variant-name helpers across data stage, runtime, and tests. Tests and runtime helpers should derive specialization, element, augment, and sub-specialization unlock expectations from `domain.gates`.
- Data-stage prototype generation now uses `scripts/domain.lua` for shared base turret and Turret XP body naming in turret variants, bound placeholders, bound previews, and ammo range compatibility.
- Lua formatting and linting are enforced through StyLua, Luacheck, Lua 5.2 syntax checks, CI, and the local Docker Compose tooling path.
- The headless suite is split by subsystem and covers the current hidden prototype budget, bound turret movement and ammo conservation, modded base turret range inheritance, turret-source projectile ammo range compatibility, damage accounting, combat effect descriptor/budget samples, GUI helper samples, compatibility helper samples, feeder routing, passive element progress, Shield, Resistance, Ammo Productivity, status damage, and gated remote policy.
- The invisible feeder remains the accepted material-input model and is documented as a narrow contract with headless coverage for lifecycle, ownership cleanup, source-aware filter priority, no-source non-management, restoration, ammo forwarding, wrong-item cleanup, mixed-element requests, and passive material progress.
- Published save/profile compatibility now lives in a named migration compatibility layer with headless coverage for legacy element slots, active element projects, retired element fuel buffers, retired augments, and old skill-tree ranks.
- GUI dependency direction is decided for the next major GUI pass: `flib` is an accepted runtime foundation, dependencies are allowed when they earn their cost, and the product target is a custom Factorio-native Turret XP interface with focused local helpers rather than a generic inherited framework.
- The 0.11 GUI glowup has started with an anchored `flib.gui` shell service. The panel should remain attached to the vanilla turret GUI when possible while adopting Factory Planner-style hierarchy, shallow content panes, reusable local builders, and explicit GUI service ownership.
- GUI widget action routing now lives in `scripts/control/gui/actions.lua`, keeping Factorio event registration thinner while preserving the existing `scripts/control/actions.lua` gameplay mutation service.
- Opened-turret GUI context assembly and refresh orchestration now live in `scripts/control/gui/runtime.lua`, keeping `gui_panels.lua` closer to a compatibility wiring layer for legacy callers.
- Compact icon-led action buttons and action toolbars are now built through `scripts/control/gui/widgets.lua` and used in the Veteran Core identity/platform/dev controls as reusable widget helpers.
- The scratch GUI rewrite centralizes the left stack in `scripts/control/gui/core_panel.lua`: Veteran Core, Label, Build, Level, Dev, Inventory Cores, and Platform Cores are explicit sibling sections built from the shared left-stack section primitive.
- Installed-core naming/floating-label controls, Build mode controls, platform rows, and core identity actions are no longer separate helper modules; they are owned by the scratch-built core panel service so the section grammar stays in one place during this rewrite.
- Stats and Evolution now share a reusable fixed-header content-pane primitive from `scripts/control/gui_components.lua`, keeping their shallow frame, subheader, scroll policy, and sizing language aligned.
- Evolution rank +/- controls now share a reusable rank-stepper primitive from `scripts/control/gui_components.lua`, with stepper sizing owned by `scripts/control/gui_constants.lua`.
- Installed-core label, platform, and dev subpanels now use a shared shallow section-frame primitive, and platform core rows use neutral preview stats so rich green/red values stay reserved for actual stat deltas.
- Stats now use compact section headers for identity, defense, offense, ammo, history, and active effects, while Crit Chance/Crit Damage live with offense output instead of history totals.
- Installed-core GUI layout has been restored to the two-column shell: core identity, naming, XP, dev controls, and Stats on the left; Evolution remains the right-column progression surface.
- Evolution base upgrades and augments share the rank-allocation row builder with explicit icon, detail, value, and stepper widths derived from the Evolution viewport.
- `gui_panels.lua` has shed internal Stats/Evolution row-builder aliases; it now keeps the runtime-facing panel/update entrypoints and legacy helpers still consumed by non-GUI services.
- Empty-turret Veteran Core selection now has a dedicated full-width picker mode. The scripted slot and explanatory text stay at the top, while inventory cores render as a Factorio-style sortable striped table component with exact install actions, persistent tri-state clickable headers, base/specialization filter checkboxes, a separate specialization column, neutral stat preview labels, and shared specialization rich-text colors. The picker height adapts to a small capped row count so short inventories do not produce empty vertical slabs, while larger inventories scroll. Sort, filter, inventory, and preview-stat changes refresh only the picker frame rather than rebuilding the whole core panel.
- Installed-core labels now expose independent Name, Level, and Unspent display toggles with one shared color row. Legacy visible labels migrate to the old name-plus-level shape, while hidden labels stay hidden.
- Installed-core Build mode now supports planning core ranks, augment ranks, specialization, sub-specialization, elements, and loop priorities without spending live points. Follow build runs outside Build mode, stays enabled for open-ended loop priorities, locks live Evolution buttons while active, and unticks once finite paths are satisfied. Headless coverage protects build editing, Follow build read-only behavior, off-path required-level recalculation, copied target policies, requester delivery, and GUI dispatch.
- Copied/blueprinted empty turrets can request one delivered Veteran Core through a hidden logistic requester helper, and their pending core slot also accepts manual Veteran Core placement. Headless coverage protects request creation, delivery/install, teardown spills, bounded refresh processing, copied setup policy, and manual pending-slot fulfillment.
- Blueprint/setup policy copy now carries label visibility, label color, build targets, Follow build state, copied bound state, and copied-core fulfillment settings without copying XP/history/name-bearing profile data.
- GUI refreshes now distinguish empty and installed shell modes, rebuild when the mode changes, and key Evolution content so the once-per-second open-GUI refresh does not destroy and recreate unchanged interactive Evolution controls.
- A graphical-client GUI snapshot workflow now exists for the 0.11 GUI PR: `scripts/gui-snapshots.sh install` installs the local mod and dev companion, `/turret-xp-snapshots` captures centered standalone Turret XP fixture views in Factorio, including configured top/bottom scroll views for overflowing panes, and `scripts/gui-snapshots.sh collect` copies raw PNGs into `tests/gui-snapshots/current/full/` while writing frame-cropped review images into `tests/gui-snapshots/current/ui/`.
- Dev controls now include a dev-core creation action, +100 levels, and dev-XP delevel buttons in addition to existing rank/material/reset helpers.
- Public homepage, GitHub release notes, and Mod Portal copy are generated from `info.json`, `changelog.txt`, and `docs/public-copy.json`, with `scripts/check.sh` detecting stale committed homepage output.
- High-complexity scope is decided for the current hardening line: keep/harden hidden feeder automation, keep optional bound turret movement, keep prototype-bound native stats limited to specialization/sub-specialization bodies, keep element combos curated and limited, and require separate approval for new progression systems.

## Current Roadmap

- Harden the current playable loop before adding progression scope. Balance/readability fixes, GUI quality, validation, and bug fixes are in scope; new branches, elements, mastery loops, quality-backed chassis work, range-band rewrites, repeatable HP/Range axes, or other prototype-backed stat axes need separate approved issues.
- Keep documentation edits ownership-based: move facts to the owning document, replace duplicates with cross-references, and delete stale planning prose once the current decision is represented elsewhere.
- Continue the attached turret GUI rewrite from [GUI_SPEC.md](GUI_SPEC.md), not as a sequence of isolated visual tweaks. Acceptance criteria for this branch: GUI surfaces live under focused `scripts/control/gui/` services, table/action/header sizing comes from `gui_constants.lua` or a component-owned layout model, reusable controls move into local widgets/components before they are repeated, refresh keys avoid rebuilding unchanged interactive controls, structural layout tests reject ad hoc top-stack sections, and docs/PR tracking stay updated with every GUI ownership decision. Do not mix that work with balance or progression-system expansion.

## Validation Checklist

Use the narrowest meaningful checks for each change:

- Internal documentation-only changes: `scripts/check.sh`, `git diff --check`.
- Root `README.md`, `changelog.txt`, or `thumbnail.png` changes: `scripts/check.sh`, `scripts/package.sh`, `git diff --check`.
- Public copy, version, changelog, or homepage changes: `scripts/generate-public-assets.py`, `scripts/generate-public-assets.py --check`, `git diff --check`.
- Lua/runtime/tooling changes: `scripts/check.sh`, `docker compose run --rm lua-format`, `docker compose run --rm lua-tools`, `scripts/package.sh`.
- Gameplay, migration, feeder, combat, profile, logistics, automation, or test-surface changes: all Lua/runtime checks plus `scripts/test-headless.sh`.
- GUI layout changes: all Lua/runtime checks plus manual in-game visual review; state the remaining manual visual-review risk when local playtesting is not performed.
- GUI screenshot review: `scripts/gui-snapshots.sh install`, `/turret-xp-snapshots` in a graphical development save, then `scripts/gui-snapshots.sh collect`. Use the cropped `tests/gui-snapshots/current/ui/` images for layout review before asking for another manual pass.
- Runtime bug fixes: add or extend the narrowest deterministic headless or pure Lua regression test in the owning subsystem, or state why the behavior needs manual GUI/playtest validation instead.
- Release changes: local script smoke checks where practical, CI on the release branch, Auto Release after merge, and the GitHub Release workflow before Mod Portal publication.
- Release preflight changes: `bash -n scripts/release-preflight.sh scripts/release.sh scripts/publish-mod-portal-release.sh`, synthetic git-state checks, `scripts/check.sh`, `scripts/package.sh`, and `git diff --check`.
- Website changes: inspect generated `docs/index.html` locally or in the built GitHub Pages output, and confirm public links point to current docs.

## Playtest Focus

Use [PLAYTEST.md](PLAYTEST.md) as the owning checklist. It separates quick smoke coverage from regression, deep manual, compatibility, platform, and long-fight balance paths.

## Open Decisions

- Destroyed turret policy for installed Veteran Cores.
