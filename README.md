# turret_xp

Factorio mod project workspace.

`turret_xp` adds the first layer of per-turret progression for vanilla gun turrets. Version 0.2.0 tracks XP, level, killing blows, kill credit, and lifetime damage for each gun turret, then extends the vanilla gun turret GUI with a polished right-side stats panel.

Homepage: <https://atyrode.github.io/turret_xp/>

## Current Shape

- Persistent agent/contributor workflow rules: [AGENTS.md](AGENTS.md).
- Planning and tracking documents: [docs/](docs/).
- Factorio mod scaffold: `info.json`, `data.lua`, `control.lua`, `settings.lua`, and `locale/`.
- Factorio changelog: `changelog.txt`.
- Current prototype: runtime-only XP tracking and a `flib`-styled right-side relative GUI panel for vanilla `gun-turret`.
- XP is awarded from damage dealt by gun turrets plus proportional kill credit based on damage contribution.
- XP pacing is configurable with runtime-global mod settings.
- The panel shows level, XP progress, HP, shooting speed, range, loaded ammo, estimated ammo damage, estimated DPS, killing blows, kill credit, lifetime damage, XP source breakdown, and total XP.
- Research bonuses are shown in a vanilla-like base plus bonus format where available.
- HP and range show the real quality-info marker with a custom hover summary derived from Factorio quality prototypes. The native Factoriopedia popover is not exposed as a reusable runtime GUI widget.

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

Build a local Factorio mod zip:

```sh
scripts/package.sh
```

The package is written to `dist/turret_xp_<version>.zip`.

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

The script also loads an ignored `.env` file and accepts `FACTORIO_API_KEY=<your-api-key>`. The API key must be created on `https://factorio.com/profile` with `ModPortal: Publish Mods`, `ModPortal: Upload Mods`, and `ModPortal: Edit Mods` usages. Do not commit the key or paste it into chat.

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
5. Let the turret shoot enemies, then reopen or keep the GUI open and confirm XP, level, damage, killing blows, and kill credit update.
6. Optional: select a gun turret and run `/turret-xp` to open its panel directly.

## Prototype Limits

- V0.2.0 tracks and displays XP/levels but does not apply stat bonuses yet.
- XP is currently scoped to vanilla `gun-turret`.
- Default XP pacing is intentionally conservative: damage gives very little XP, kill credit matters more, and level requirements grow exponentially.
- Damage shown in the GUI is a best-effort estimate from loaded ammo prototype data.
- Removed or destroyed turrets lose their tracked state.

## Documents

- [docs/README.md](docs/README.md): documentation index.
- [docs/index.html](docs/index.html): GitHub Pages homepage.
- [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md): high-level mod intent, scope, assumptions, and open decisions.
- [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md): user-visible behavior and release requirements.
- [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md): concrete first milestone and implementation target.
- [docs/TECHNICAL_DIRECTION.md](docs/TECHNICAL_DIRECTION.md): Factorio modding stack, validation path, and technical risks.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): repository structure, runtime responsibilities, and ownership boundaries.
- [docs/DESIGN.md](docs/DESIGN.md): gameplay, balance, UX, terminology, art, and compatibility direction.
- [docs/DEVELOPMENT_STEPS.md](docs/DEVELOPMENT_STEPS.md): working checklist.
- [docs/PLAYTEST.md](docs/PLAYTEST.md): install and report-back checklist.
