# Turret XP GUI Prototype Lab

This is a static browser prototype for the future Turret XP GUI redesign. It
renders the split spec in [../../docs/gui-spec](../../docs/gui-spec) before any
Lua rewrite happens.

Open [index.html](index.html) in a browser. No build step or server is required.

## Why This Exists

The previous GUI attempts reached Lua too early. This lab gives us a cheaper
place to judge structure, hierarchy, spacing, and interaction flow. Once the
browser prototype is accepted, the in-game implementation should translate the
same anchors and fixtures into Factorio GUI primitives.

## What It Covers

- Empty-turret Core Picker with Inventory and Platform sources.
- Installed Veteran Core Workbench.
- Live mode rank spending with pinned stat feedback.
- Build Plan mode with current -> planned stat deltas.
- Follow build visibility while progression remains visible.
- Copied-target conflict display at the affected role group.
- Detail and Core Details drawers as secondary surfaces.

## Style References

The prototype uses a local Factorio-inspired token layer based on public
inspection of:

- <https://factorio.com/>
- <https://mods.factorio.com/>
- <https://factorio.com/blog/>
- <https://lua-api.factorio.com/latest/>
- <https://man.sr.ht/~raiguard/factorio-gui-style-guide/>
- <https://mods.factorio.com/user/raiguard>

It does not vendor Wube's CSS, minified page assets, or image payloads. It
loads Factorio's public Titillium Web font when online and falls back to local
system fonts.

Raiguard's style guide and public Factorio work are treated as high-value
references, not as code to copy. The Mod Portal and Codeberg profile connect
Raiguard to `flib`, Editor Extensions, Krastorio 2, and Wube Software. Future
style work should cite the exact inspected guide section, repository, or file.

Graphical Factorio's style tools are part of the intended review loop:
`Ctrl+F6` for the GUI style inspector, `Ctrl+F5` for bounding boxes, and
`Ctrl+F7` for shadows. These tools are not available through Factorio headless,
so captures from a normal graphical game should be translated into tokens,
constraints, or fixture notes before Lua implementation.

## Builder Direction

This can grow into a constrained component builder, but not a freeform pixel
editor. Factorio GUI layout is flow/table/style based, so drag-anything-anywhere
would create browser layouts that translate poorly to Lua. The safer path is:
edit fixtures, choose approved layout variants, reorder major groups, tune
bounded widths/density, export a JSON/Markdown layout model, then export a Lua
skeleton with stable anchors for an agent to implement.

The larger roadmap is tracked in
[../../docs/gui-spec/browser-builder-roadmap.md](../../docs/gui-spec/browser-builder-roadmap.md).
The possible end state is one constrained layout model that can render in this
browser tool, generate the in-game Lua structure, and later power a read-only
official website demo.

## External Resource Check

`JanSharp/FactorioGUIEditor` was checked as a possible prior art resource. It
is an in-game Factorio GUI editor prototype with unreleased dependencies, not a
browser renderer for design review. The useful takeaway for this repo is to
respect Factorio GUI constraints such as stretch/fixed-size quirks, scroll-pane
edge cases, and click-event behavior. The browser lab remains repo-owned and
dependency-light.

## Validation

Run:

```sh
scripts/check-gui-prototype.sh
```

The repository-wide `scripts/check.sh` also runs this check.

The check proves source/fixture/anchor coverage only. Human review still owns
visual taste and acceptance.
