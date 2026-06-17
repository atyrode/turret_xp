# GUI Snapshots

This folder holds graphical-client screenshots used to review the Turret XP GUI during development. The snapshot harness is intentionally not part of normal gameplay or the packaged mod.

## Capture Workflow

1. Install the local mod package and snapshot companion:

   ```sh
   scripts/gui-snapshots.sh install
   ```

2. Start Factorio normally with `turret_xp`, `flib`, and `turret_xp_gui_snapshots` enabled.

3. In a disposable or development save, run:

   ```text
   /turret-xp-snapshots
   ```

   The command briefly moves the player to a temporary fixture surface, opens the real Turret XP GUI as a centered standalone screen frame for each configured view, selects the requested scroll position, records that frame's bounds, captures screenshots with `game.take_screenshot(show_gui=true)`, then restores the player position and removes the temporary scene entities and sample Veteran Cores.

4. Copy the images from Factorio `script-output` into the repo:

   ```sh
   scripts/gui-snapshots.sh collect
   ```

The collected files land in `tests/gui-snapshots/current/`. The `ui/` directory contains cropped Turret XP-only review images derived from the recorded frame bounds, while `full/` keeps the raw graphical-client screenshots for context. They are regular repo files so they can be inspected by Codex, compared manually, or promoted later for documentation.

## Scenes

- `empty-picker`: empty turret plus sample Veteran Cores in the player inventory.
- `installed-basic`: named installed core with label controls and bound state, including a stats-bottom scroll view.
- `evolution-choices`: high-level core with unspent progression choices, including top and bottom Evolution scroll views.
- `evolution-progress`: specialized elemental core with augments and material progress, including top and bottom Evolution scroll views.

Capture only one scene by passing its id:

```text
/turret-xp-snapshots evolution-progress
```
