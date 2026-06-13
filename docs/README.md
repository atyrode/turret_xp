# Documentation

This directory is the working context for `turret_xp`. The goal is not more documents; it is one clear owner for each kind of truth so agents and operators can pick up the repository without reverse-engineering stale plans.

## Ownership Map

- Root [README.md](../README.md): repository entry point, player overview, install path, common commands, release workflow pointers, and documentation index. It should not duplicate deep behavior, architecture, or playtest checklists.
- [PROJECT_BRIEF.md](PROJECT_BRIEF.md): product intent, current scope, non-goals, and open product boundaries.
- [REQUIREMENTS.md](REQUIREMENTS.md): user-visible obligations and expected outputs. If gameplay or UX behavior becomes mandatory, record it here.
- [PROJECT_SPEC.md](PROJECT_SPEC.md): current implemented behavior for the active development line.
- [ARCHITECTURE.md](ARCHITECTURE.md): runtime/data/test ownership, storage shape, module boundaries, and invariants.
- [TECHNICAL_DIRECTION.md](TECHNICAL_DIRECTION.md): technical choices, research memory, dependencies, API notes, risks, and validation paths.
- [DESIGN.md](DESIGN.md): gameplay direction, UX direction, balance intent, compatibility posture, public identity, and feedback goals.
- [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md): future-only progression direction. It is not an implementation promise.
- [DEVELOPMENT_STEPS.md](DEVELOPMENT_STEPS.md): current baseline, completed foundations, near-term roadmap, and validation checklist.
- [PLAYTEST.md](PLAYTEST.md): smoke, regression, deep manual, compatibility, and report-back paths.
- [public-copy.json](public-copy.json): shared public copy source for the homepage, GitHub Release notes, and Mod Portal details.
- [index.html](index.html): generated GitHub Pages homepage. Do not hand-edit duplicated homepage copy; update the source files and regenerate it.

## Maintenance Rules

- Prefer moving information to its owning document over repeating it.
- Use short cross-references when another document owns the detail.
- Delete stale planning prose when the decision is already represented in current docs, code, issues, or git history.
- Mark future-only ideas explicitly, especially progression, GUI, dependency, and rewrite notes.
- Keep version-by-version release history in the root [changelog.txt](../changelog.txt); do not recreate release diaries in active docs.
- When changing behavior, architecture, workflow, CI, release, or assumptions, update the owning document in the same PR.

## Homepage

The public site is generated and committed:

- [index.html](index.html): generated GitHub Pages homepage.
- [public-copy.json](public-copy.json): public copy source. After editing it, run `scripts/generate-public-assets.py`.
