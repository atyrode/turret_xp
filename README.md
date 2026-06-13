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

Use short-lived issue branches and pull requests into protected `main`. Keep releases on `main`: merge the release-ready PR, then publish a GitHub Release/tag named `v<info.json version>`. Do not use a long-lived `dev` branch unless the workflow is explicitly revisited.

Run lightweight repository checks:

```sh
scripts/check.sh
```

`scripts/check.sh` stays host-friendly: it validates JSON and runs Lua syntax, StyLua, and Luacheck only when those tools are available on `PATH`.
It also verifies that generated public assets are current.

Public website, release notes, and Mod Portal copy are generated from `info.json`, `changelog.txt`, and [docs/public-copy.json](docs/public-copy.json). When public copy, version metadata, or changelog entries change, regenerate the committed homepage and verify it:

```sh
scripts/generate-public-assets.py
scripts/generate-public-assets.py --check
```

Run the strict Lua tooling suite without installing Lua tools on the host:

```sh
docker compose run --rm lua-tools
```

This uses the pinned tooling container from `tools/lua/Dockerfile` and requires `luac`, StyLua, and Luacheck to pass. CI uses the same strict path for package-impacting changes.

Run the Factorio headless regression suite:

```sh
scripts/test-headless.sh
```

Set `FACTORIO_BIN=/path/to/factorio` if the script cannot autodetect the local Factorio executable. The suite packages the current mod, loads it with a dedicated temporary test mod, reports the tracked hidden prototype budget, and fails if core gameplay invariants break. It also runs a separate smoke test for production remote-interface policy.
The `turret_xp_test` remote interface is registered only while that temporary test mod is active; it is not a production integration API.

Build a local Factorio mod zip:

```sh
scripts/package.sh
```

The package is written to `dist/turret_xp_<version>.zip`.
The mod zip includes the root `README.md`, `changelog.txt`, and root `thumbnail.png` when present. Internal docs under `docs/` and generated public-site files such as `docs/index.html`, `docs/site.css`, and `docs/public-copy.json` are source/public-site material and are not packaged.
Local packaging is a development workflow and does not require a clean branch or remote-state preflight.

GitHub Actions keeps the required check names stable for pull requests, pushes to `main`, and manual CI runs. Pull requests first classify changed files with `scripts/ci-change-scope.sh`: Lua changes run strict Lua tooling; root `README.md`, `changelog.txt`, `thumbnail.png`, package source, package scripts, and validation infrastructure run package validation; runtime source, prototypes, locale, headless tests, and validation infrastructure run the headless job when Mod Portal download credentials are available. Internal docs and generated public-site-only changes still run lightweight checks but skip package/headless work. Pushes to `main` and manual runs always run the full validation path. The workflow pins StyLua and the headless runner version, verifies the StyLua release hash, and caches the extracted Factorio directory plus dependency zips; update `STYLUA_VERSION`/`STYLUA_SHA256` or `FACTORIO_HEADLESS_VERSION` in the workflows when intentionally moving tooling or Factorio builds.

Install the packaged zip into the default Linux Factorio mods folder:

```sh
scripts/install-local.sh
```

Override the target folder when needed:

```sh
FACTORIO_MODS_DIR=/path/to/factorio/mods scripts/install-local.sh
```

## Release Workflow

The standard release path is:

1. Finish the issue branch and open a pull request into `main`.
2. Confirm CI passes, including headless tests when secrets are configured.
3. Merge the PR into `main`.
4. Publish a GitHub Release named `v<info.json version>`.
5. Let the Release workflow build/test the package, attach the zip to the GitHub Release, wait for the `factorio-mod-portal` environment approval when configured, and publish the same version to the Factorio Mod Portal.

Pull request conventions:

- Use concise change titles such as `Extract label color helper module` or `Measure hidden prototype budget`; do not prefix titles with issue numbers.
- Link issues in the PR body with `Closes #N` when the PR fully resolves the issue, or `Refs #N` when it is a partial step.
- Include a `What This Changes For The Future/Codebase` section for audit-driven work so the intended long-term effect is explicit.
- Keep design answers and follow-up decisions in issue comments for continuity.

Local helper for creating or updating the GitHub release for the current `info.json` version:

```sh
scripts/release.sh
```

This script is the GitHub Release publishing path. It first runs `scripts/release-preflight.sh`, which fetches the configured release remote and blocks unless the working tree is clean, the current branch is `main`, and local `main` exactly matches `origin/main`. It then checks the generated homepage and writes GitHub release notes into `dist/` from the same public-copy sources before uploading the package.

Local helper for manually publishing or updating the Factorio Mod Portal release:

```sh
FACTORIO_MOD_PORTAL_API_KEY=<your-api-key> scripts/publish-portal.sh
```

The script checks generated public assets, writes the Mod Portal description and metadata into `dist/`, and runs `scripts/test-headless.sh` before uploading. Set `SKIP_HEADLESS_TESTS=1` only for exceptional machines that cannot run Factorio locally. Mod Portal API failures print the portal response body so CI logs show the rejected field or endpoint. The script also loads an ignored `.env` file and accepts `FACTORIO_API_KEY=<your-api-key>`. The API key must be created on `https://factorio.com/profile` with `ModPortal: Publish Mods`, `ModPortal: Upload Mods`, and `ModPortal: Edit Mods` usages. Do not commit the key or paste it into chat.
This is the stable Mod Portal publishing path for the current `info.json` version. It uses the same release preflight as `scripts/release.sh`, and it passes Mod Portal authorization plus temporary upload URLs through local curl config files so token-bearing values are not placed in curl process arguments. There is no separate experimental Mod Portal upload path; add an explicit channel/version policy before using this script for experimental releases.

GitHub setup required for the automated release path:

- Repository secret `FACTORIO_SERVICE_USERNAME`: Factorio service username used for authenticated Mod Portal dependency downloads.
- Repository secret `FACTORIO_SERVICE_TOKEN`: Factorio service token used with `FACTORIO_SERVICE_USERNAME`.
- Repository secret `FACTORIO_MOD_PORTAL_API_KEY`: Mod Portal API key with publish/upload/edit permissions.
- GitHub Environment `factorio-mod-portal`: recommended for the portal publish job, with required reviewer approval before upload.
- Branch protection for `main`: require pull requests and the `Basic Checks And Package` status check first; add `Headless Factorio Tests` as a required check after the download secrets are configured and the job is confirmed to run.

Do not store these values in tracked files or paste them into chat. The CI dependency downloader reads credentials from environment variables and does not print authenticated download URLs.

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

## Current Limits

- V0.10.3 is the current development line. Veteran Cores start at level 0; level 10 grants 10 core points and a specialization choice; level 20 grants the first free element; level 40 adds sub-specializations; and level 50 unlocks the second element/combo. Evolution uses a bounded second main column with a fixed summary header and one scrollable section body. Selected elements always show next-rank material progress. Max HP, Range, specialization, and sub-specialization use hidden prototype variants generated after other mods' data updates. Resistance stays scripted to avoid another hidden variant axis. Bound veteran turrets can quick-move as one tagged placeable item without polluting normal gun-turret replacement ghosts or duplicating saved ammo.
- Turret XP also patches gun-turret accepted projectile ammo at the data-final stage when that ammo has a shorter turret-source projectile range than the highest generated Turret XP range. This preserves non-turret ammo behavior while making K2/K2SO-style realistic rifle ammo compatible with long-range veteran turret bodies.
- The Veteran Core item currently uses vanilla layered icons; dedicated art can replace it later without changing the profile model.
- Core upgrades, augments, elements, and combos still need playtest balance and effect readability passes.
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
- [docs/public-copy.json](docs/public-copy.json): shared public copy source for the homepage, release notes, and Mod Portal details.
- [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md): high-level mod intent, scope, assumptions, and open decisions.
- [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md): user-visible behavior and release requirements.
- [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md): concrete first milestone and implementation target.
- [docs/TECHNICAL_DIRECTION.md](docs/TECHNICAL_DIRECTION.md): Factorio modding stack, validation path, and technical risks.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): repository structure, runtime responsibilities, and ownership boundaries.
- [docs/DESIGN.md](docs/DESIGN.md): gameplay, balance, UX, terminology, art, and compatibility direction.
- [docs/PROGRESSION_DESIGN.md](docs/PROGRESSION_DESIGN.md): intended XP, evolution, material-gate, duo-element, and infinite-scaling gameplay direction.
- [docs/DEVELOPMENT_STEPS.md](docs/DEVELOPMENT_STEPS.md): working checklist.
- [docs/PLAYTEST.md](docs/PLAYTEST.md): install and report-back checklist.
