# turret_xp

`turret_xp` makes chosen vanilla gun turrets grow into veteran defenses. Install a Veteran Core, let the turret earn XP, then shape it through upgrades, specializations, passive elemental material ranks, and a portable history that can move to another turret.

Homepage: <https://atyrode.github.io/turret_xp/>

## Current Shape

- Persistent agent/contributor workflow rules: [AGENTS.md](AGENTS.md).
- Planning and tracking documents: [docs/](docs/).
- Factorio mod scaffold: `info.json`, entrypoint Lua files, runtime modules in `scripts/control/`, data-stage modules in `prototypes/`, `settings.lua`, and `locale/`.
- Factorio changelog: `changelog.txt`.
- Chosen turrets become veterans when a Veteran Core is installed; ordinary turrets stay stackable.
- Veteran Cores store XP, levels, upgrades, elements, name and label preferences, and combat history.
- Installed Veteran Cores can be bound to a turret body for quick moves as one tagged placeable item, then unbound to return to the separate core/turret workflow.
- Turrets gain XP from damage and kill contribution; target type and space-platform context affect XP pacing.
- Evolution offers repeatable upgrades, specializations, sub-specializations, augments, and elemental material ranks.
- Inserters can passively feed selected element ranks while normal ammo logistics still work.
- Fire and Toxic now apply tracked damage over time; those delayed ticks count for XP and lifesteal.
- Space-platform turrets can choose exact cores from the platform hub.
- Bullet Trails is an optional visual dependency for richer scripted bullet and element tracers.
- The turret panel shows XP, combat stats, active custom bonuses, formulas when useful, and a bounded two-column layout with scrollable stats and Evolution choices separated from the core/stat summary.

## Development

Before committing, branching, merging, or pushing, fetch the remote branch state when a remote exists and check whether the local branch is ahead, behind, or diverged:

```sh
git fetch
git status --short --branch
```

Run lightweight repository checks:

```sh
scripts/check.sh
```

Run the Factorio headless regression suite:

```sh
scripts/test-headless.sh
```

Set `FACTORIO_BIN=/path/to/factorio` if the script cannot autodetect the local Factorio executable. The suite packages the current mod, loads it with a dedicated temporary test mod, and fails if core gameplay invariants break.

Build a local Factorio mod zip:

```sh
scripts/package.sh
```

The package is written to `dist/turret_xp_<version>.zip`.
If `thumbnail.png` exists at the repository root, it is included at the mod zip root for Mod Portal display.

Install the packaged zip into the default Linux Factorio mods folder:

```sh
scripts/install-local.sh
```

Override the target folder when needed:

```sh
FACTORIO_MODS_DIR=/path/to/factorio/mods scripts/install-local.sh
```

Publish or update the GitHub release for the current `info.json` version:

```sh
scripts/release.sh
```

Publish or update the Factorio Mod Portal release:

```sh
FACTORIO_MOD_PORTAL_API_KEY=<your-api-key> scripts/publish-portal.sh
```

The script runs `scripts/test-headless.sh` before uploading. Set `SKIP_HEADLESS_TESTS=1` only for exceptional machines that cannot run Factorio locally. The script also loads an ignored `.env` file and accepts `FACTORIO_API_KEY=<your-api-key>`. The API key must be created on `https://factorio.com/profile` with `ModPortal: Publish Mods`, `ModPortal: Upload Mods`, and `ModPortal: Edit Mods` usages. Do not commit the key or paste it into chat.

## Download And Playtest

Preferred once published: install `Turret XP` from Factorio's in-game Mods interface.

Fallback manual download: use the latest GitHub release:

```text
https://github.com/atyrode/turret_xp/releases/latest
```

The focused playtest path is in [docs/PLAYTEST.md](docs/PLAYTEST.md).

## Fast Manual Test

1. Run `scripts/install-local.sh` or install from the in-game Mods interface after publishing.
2. Start Factorio 2.0 with `turret_xp` enabled.
3. Place a vanilla gun turret and add ammo.
4. Open the turret. The vanilla turret GUI should show a `Turret XP` panel on the right.
5. Install a Veteran Core from inventory, or run `/turret-xp-dev` and use the dev core button in local testing.
6. Let the turret shoot enemies, then reopen or keep the GUI open and confirm XP, level, damage, kills, evolution points, and upgrades update.
7. Optional: select a gun turret and run `/turret-xp` to open its panel directly.

## Prototype Limits

- V0.10.2 is the current development line after the 0.10.0 Mod Portal playtest release: Veteran Cores start at level 0, level 10 grants 10 core points and a specialization choice, level 20 grants the first free element, level 40 adds sub-specializations, and level 50 unlocks the second element/combo. Evolution lives in a bounded second main column with a richer static summary header and a single scrollable section body, stats can scroll, selected elements always show their next material rank progress, duplicate pure-element stat rows are collapsed, active custom stats are dynamic, baseline crit stats are visible, Max HP is a capped prototype-backed augment, Regeneration scales from current max HP, Ammo Recovery slowly regenerates the loaded or remembered ammo item, Resistance mitigates incoming damage without adding hidden prototypes, Toxic adds poison-capsule-fed stacking poison and slow, Fire adds tracked burn damage, Luck affects proc odds, specialization formulas are visible with green benefits and red tradeoffs, sub-specializations deepen each role, space-platform turrets can pick cores from the platform hub, target-aware XP slows asteroid farming, optional Bullet Trails visuals are supported for readable bounce/double-shot/element tracers, custom floating-label colors keep Factorio-style display-panel backing, bound veteran turrets can quick-move as one tagged placeable item without polluting normal gun-turret replacement ghosts, one Evolution header Reset clears all Evolution choices while preserving XP/history, element selections expose a `Change` action, element and specialization choices use clearer card-style rows with contained right-aligned actions, and hidden variants are generated after other mods' data updates so Range ranks, Max HP ranks, and role branches preserve modded base gun-turret stats.
- The Veteran Core item currently uses vanilla layered icons; dedicated art can replace it later without changing the profile model.
- V0.9.x is still a first playable draft of list-based evolution. Core upgrades, augments, elements, and combos still need playtest balance and effect readability passes.
- The failed embedded skill-tree drag spike was removed. The current progression UI is intentionally simple while the gameplay model is tested.
- XP is currently scoped to vanilla `gun-turret`.
- Default XP pacing is intentionally conservative: damage gives very little XP, kill credit matters more, and level requirements grow linearly by a configurable step.
- Real specialization, Range, and Max HP stat changes still use hidden turret prototypes because runtime per-entity turret range, cooldown, damage modifier, and max health are not writable. Those variants are generated in `data-final-fixes.lua` so they inherit late prototype edits from other mods, and research damage bonuses are synced to those variants at runtime instead of copied into technology effect lists. Resistance deliberately avoids new variants by refunding part of non-lethal incoming damage after Factorio applies vanilla resistances.
- Damage shown in the GUI is a best-effort estimate from loaded ammo prototype data.
- Tagged Veteran Core and bound turret items include a build summary in their custom item descriptions. Placed turret hover tooltips cannot show per-core build data through runtime custom descriptions; Factorio's extra tooltip fields are static prototype data, so the attached Turret XP panel remains the source of truth for live placed-turret build details.
- Mined unbound turrets return their installed Veteran Core and spill leftover feeder contents. Mined bound turrets return one tagged bound turret item. The bound item places a bound-only placeholder that is immediately converted into a real gun turret with its stored core profile, so normal gun-turret ghosts keep requesting the normal gun turret item. Destroyed turrets currently lose the installed core.

## Documents

- [docs/README.md](docs/README.md): documentation index.
- [docs/index.html](docs/index.html): GitHub Pages homepage.
- [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md): high-level mod intent, scope, assumptions, and open decisions.
- [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md): user-visible behavior and release requirements.
- [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md): concrete first milestone and implementation target.
- [docs/TECHNICAL_DIRECTION.md](docs/TECHNICAL_DIRECTION.md): Factorio modding stack, validation path, and technical risks.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): repository structure, runtime responsibilities, and ownership boundaries.
- [docs/REFACTOR_PLAN_0.9.1.md](docs/REFACTOR_PLAN_0.9.1.md): V0.9.1 modularization plan and Veteran Core slot boundary.
- [docs/DESIGN.md](docs/DESIGN.md): gameplay, balance, UX, terminology, art, and compatibility direction.
- [docs/PROGRESSION_DESIGN.md](docs/PROGRESSION_DESIGN.md): intended XP, evolution, material-gate, duo-element, and infinite-scaling gameplay direction.
- [docs/DEVELOPMENT_STEPS.md](docs/DEVELOPMENT_STEPS.md): working checklist.
- [docs/PLAYTEST.md](docs/PLAYTEST.md): install and report-back checklist.
