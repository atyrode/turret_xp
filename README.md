# turret_xp

Factorio mod project workspace.

`turret_xp` adds the first layer of progression for vanilla gun turrets. Version 0.4.5 moves progression onto a non-stackable Veteran Core item that the player chooses to install in a turret, adds an inserter-fed Veteran Core feeder inventory, and keeps specialization choices as real prototype-backed turret stat variants.

Homepage: <https://atyrode.github.io/turret_xp/>

## Current Shape

- Persistent agent/contributor workflow rules: [AGENTS.md](AGENTS.md).
- Planning and tracking documents: [docs/](docs/).
- Factorio mod scaffold: `info.json`, `data.lua`, `control.lua`, `settings.lua`, and `locale/`.
- Factorio changelog: `changelog.txt`.
- Current prototype: runtime-only XP tracking and a `flib`-styled right-side relative GUI panel for vanilla `gun-turret`.
- Ordinary gun turrets stay stackable and do not gain progression until a Veteran Core is installed.
- A Veteran Core is an `item-with-tags` profile item. Installing it makes the current turret unique; extracting or mining the turret returns the core with its XP, upgrades, element projects, custom name, and display-label preference.
- Installing a Veteran Core creates a nearby Veteran Core feeder inventory. Element projects and element mastery consume matching resources from that feeder instead of from the player inventory.
- XP is awarded from damage dealt by gun turrets with an installed core plus proportional kill credit based on damage contribution.
- XP pacing is configurable with runtime-global mod settings.
- The panel shows level, XP progress, HP, shooting speed, range, loaded ammo, estimated ammo damage, estimated DPS, kills, and lifetime damage.
- Research bonuses are shown in a vanilla-like base plus bonus format where available.
- HP and range show the real quality-info marker with a custom hover summary derived from Factorio quality prototypes. The native Factoriopedia popover is not exposed as a reusable runtime GUI widget.
- The Evolution panel replaces the experimental skill tree with five list sections: core upgrades, first element, specialization, powerful augments, and second element/combo.
- Element choices start material projects that can be filled by inserting resources into the feeder; dev buttons can quickly grant levels, create cores, or complete the active project for playtesting.

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
5. Install a Veteran Core from inventory, or use the dev core button in local testing.
6. Let the turret shoot enemies, then reopen or keep the GUI open and confirm XP, level, damage, kills, evolution points, and upgrades update.
7. Optional: select a gun turret and run `/turret-xp` to open its panel directly.

## Prototype Limits

- V0.4.5 adds tag-preserving slot-style Veteran Core transfer and floating label customization. V0.4.4 fixed fresh-core installation, high-level combat progression performance, cropped allocation buttons, and added respec/reset controls.
- The Veteran Core item currently uses vanilla layered icons; dedicated art can replace it later without changing the profile model.
- V0.4.x is a first draft of list-based evolution. Core upgrades, augments, elements, and combos still need playtest balance and effect readability passes.
- The failed embedded skill-tree drag spike was removed. The current progression UI is intentionally simple while the gameplay model is tested.
- XP is currently scoped to vanilla `gun-turret`.
- Default XP pacing is intentionally conservative: damage gives very little XP, kill credit matters more, and level requirements grow linearly by a configurable step.
- Damage shown in the GUI is a best-effort estimate from loaded ammo prototype data.
- Mined turrets return their installed Veteran Core and spill leftover feeder contents. Destroyed turrets currently lose the installed core.

## Documents

- [docs/README.md](docs/README.md): documentation index.
- [docs/index.html](docs/index.html): GitHub Pages homepage.
- [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md): high-level mod intent, scope, assumptions, and open decisions.
- [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md): user-visible behavior and release requirements.
- [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md): concrete first milestone and implementation target.
- [docs/TECHNICAL_DIRECTION.md](docs/TECHNICAL_DIRECTION.md): Factorio modding stack, validation path, and technical risks.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): repository structure, runtime responsibilities, and ownership boundaries.
- [docs/DESIGN.md](docs/DESIGN.md): gameplay, balance, UX, terminology, art, and compatibility direction.
- [docs/PROGRESSION_DESIGN.md](docs/PROGRESSION_DESIGN.md): intended XP, evolution, material-gate, duo-element, and infinite-scaling gameplay direction.
- [docs/DEVELOPMENT_STEPS.md](docs/DEVELOPMENT_STEPS.md): working checklist.
- [docs/PLAYTEST.md](docs/PLAYTEST.md): install and report-back checklist.
