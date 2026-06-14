# turret_xp

`turret_xp` is a Factorio 2.0 mod that lets selected vanilla gun turrets become persistent veteran defenders. Install a Veteran Core, let the turret earn XP from combat, then shape it through upgrades, specializations, elemental material ranks, labels, and optional bound turret movement.

Homepage: <https://atyrode.github.io/turret_xp/>

## Player Overview

- Ordinary gun turrets stay stackable until a Veteran Core is installed.
- Veteran Cores store XP, levels, upgrades, elements, name/label preferences, and combat history.
- Installed cores can move between turret bodies, or bind to a turret for one-item quick moves.
- Current progression is scoped to vanilla `gun-turret`.
- The live turret panel shows core state, XP, stats, formulas, Evolution choices, and material progress beside the vanilla turret GUI.

For exact implemented behavior, use [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md). For playtest steps, use [docs/PLAYTEST.md](docs/PLAYTEST.md).

## Download And Install

Preferred once published: install `Turret XP` from Factorio's in-game Mods interface.

Fallback manual download: use the latest GitHub release:

```text
https://github.com/atyrode/turret_xp/releases/latest
```

For local development builds:

```sh
scripts/install-local.sh
```

Override the target folder when needed:

```sh
FACTORIO_MODS_DIR=/path/to/factorio/mods scripts/install-local.sh
```

## Development

Persistent repository workflow rules live in [AGENTS.md](AGENTS.md). The active documentation map is [docs/README.md](docs/README.md).

Before committing, branching, merging, or pushing, fetch remote state and check whether the branch is ahead, behind, or diverged:

```sh
git fetch
git status --short --branch
```

Use short-lived issue branches and pull requests into protected `main`. Keep releases on `main`: merge the release-ready PR, then publish a GitHub Release/tag named `v<info.json version>`.

Common checks:

```sh
scripts/check.sh
docker compose run --rm lua-tools
scripts/package.sh
scripts/test-headless.sh
```

`scripts/check.sh` is host-friendly and skips optional Lua tools that are not installed. The Docker command is the strict Lua syntax, StyLua, and Luacheck path used by CI. `scripts/test-headless.sh` packages the current mod and runs the Factorio headless regression suite when `factorio` is available or `FACTORIO_BIN=/path/to/factorio` is set.

GUI screenshot review uses a graphical Factorio client because Factorio does not write GUI screenshots in headless mode:

```sh
scripts/gui-snapshots.sh install
```

Then start Factorio, load a disposable development save, run `/turret-xp-snapshots`, and collect the images:

```sh
scripts/gui-snapshots.sh collect
```

The captured PNGs and generated index are copied into `tests/gui-snapshots/current/` for visual review and future documentation reuse.

Public website, release notes, and Mod Portal copy are generated from `info.json`, `changelog.txt`, and [docs/public-copy.json](docs/public-copy.json):

```sh
scripts/generate-public-assets.py
scripts/generate-public-assets.py --check
```

The package is written to `dist/turret_xp_<version>.zip`. It includes the root `README.md`, `changelog.txt`, locale, Lua/prototype source, and root `thumbnail.png` when present. Internal docs under `docs/` and generated public-site files are source/public-site material, not mod package payload.

## Release Workflow

Standard path:

1. Finish the issue branch and open a pull request into `main`.
2. Confirm CI passes.
3. Merge the PR into `main`.
4. Publish a GitHub Release named `v<info.json version>`.
5. Let the Release workflow build/test the package, attach the zip, wait for the `factorio-mod-portal` environment approval when configured, and publish the same version to the Factorio Mod Portal.

Local GitHub Release helper:

```sh
scripts/release.sh
```

Local Mod Portal helper:

```sh
FACTORIO_MOD_PORTAL_API_KEY=<your-api-key> scripts/publish-portal.sh
```

Both release helpers run release preflight and require clean, up-to-date `main`. Do not commit secrets, paste tokens into chat, or put real credentials in tracked files. Use ignored local env files, GitHub Secrets, and operator-run secret setup workflows.

## Documents

- [docs/README.md](docs/README.md): documentation ownership map.
- [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md): product intent, scope, and open product boundaries.
- [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md): user-visible obligations.
- [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md): current implemented behavior.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): runtime/data/test ownership and invariants.
- [docs/TECHNICAL_DIRECTION.md](docs/TECHNICAL_DIRECTION.md): technical choices, research memory, risks, dependencies, and validation.
- [docs/DESIGN.md](docs/DESIGN.md): UX, balance, compatibility, and public identity direction.
- [docs/PROGRESSION_DESIGN.md](docs/PROGRESSION_DESIGN.md): future-only progression design notes.
- [docs/DEVELOPMENT_STEPS.md](docs/DEVELOPMENT_STEPS.md): current work, validation checklist, and near-term roadmap.
- [docs/PLAYTEST.md](docs/PLAYTEST.md): smoke, regression, and deep manual playtest paths.
- [docs/index.html](docs/index.html): generated GitHub Pages homepage.
