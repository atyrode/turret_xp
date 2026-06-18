# GUI Spec

This document owns the current Turret XP GUI redesign contract. It replaces the old installed-core dashboard direction with a focused player workflow. The goal is not to preserve the previous panel shape; the goal is to make the same core gameplay loop understandable, attractive, and efficient.

## Redesign Goal

The attached Turret XP panel should feel like one Factorio-native tool beside the vanilla turret GUI. It should answer one player question at a time instead of showing every system at once.

The core gameplay loop stays in scope:

- Install a Veteran Core into a turret.
- Earn XP and levels through combat.
- Spend progression choices.
- Shape the core through upgrades, specialization, elements, labels, binding, movement, and build automation.
- Move the core between turret bodies without losing identity.

The presentation is open to redesign. Progression surfaces may be regrouped around player intent, stats may become contextual or detail-only, and upgrades/specialization/elements/build automation may be presented as guided workflows when that makes the GUI clearer.

## Installed Core Mode

Installed-core mode uses a compact shell with one active content view.

```text
Turret XP
  status strip
    core icon/name/level/xp
    unspent point summary
    build/automation state
    primary actions
  view navigation
    Overview | Progression | Stats | Automation
  active content pane
    exactly one selected view
```

The old permanent left Stats column and right Evolution column must not return. Stats, progression decisions, and automation details are available through focused views, not simultaneous competing panes.

### Status Strip

The status strip is always visible for installed cores. It shows:

- Veteran Core icon or slot-style control.
- Core display name or fallback identity.
- Level and XP progress.
- Unspent progression summary.
- Specialization or pending specialization summary.
- Build mode or Follow build state when relevant.
- Primary actions: extract, bind/unbind, and build-mode entry/exit.

The status strip is compact. It should not contain full label editing, full stats, rank allocation rows, or long build target details.

### Overview View

Overview is the default installed-core view. It should show what matters now:

- Core identity summary.
- XP progress and next meaningful unlock or target.
- Current role/specialization summary.
- Current active build/follow state.
- Short current-strength highlights, such as damage/range/HP or active tradeoffs.
- Compact label/name controls if they fit calmly; otherwise label editing may move behind a small details group or another view.

Overview must not contain the full Stats table or the full progression allocation list.

### Progression View

Progression owns spendable decisions. It may combine systems that were previously split across "Core upgrades", "Specialization", "Augments", "Elements", and "Combos" if the grouped workflow is clearer.

Required capabilities:

- Show available core and augment points.
- Spend/refund repeatable upgrade ranks.
- Pick specialization and sub-specialization when unlocked.
- Pick elements and element combos when unlocked.
- Show locked gates without flooding the view.
- Show material progress for element ranks.
- Preserve current click behavior for rank steppers, including modifier-click shortcuts.

The view should group choices by player intent, such as "Improve damage", "Change role", "Add element", or "Unlock next milestone", when that reads better than implementation categories.

### Stats View

Stats is a detail view, not first-screen chrome. It keeps the existing stat contract but only appears when selected:

- Identity.
- Defense.
- Offense.
- Ammo.
- History.
- Effects.

Rows use stable label/value alignment. Formula details belong in tooltips or compact expandable text, not as always-visible clutter.

### Automation View

Automation owns Build mode and repeated setup workflows:

- Enter/exit Build mode.
- Follow build.
- Copied or blueprinted target summary.
- Planned required level.
- Planned point spending.
- Planned specialization, element, and material requirements.
- Conflict states when the live core cannot safely follow the copied target.

Only compact build state and a primary action may appear in the status strip or Overview. Full planning detail belongs here.

## Empty Turret Mode

Empty-turret mode is a separate picker screen, not the installed-core dashboard with missing sections.

```text
Turret XP
  empty status row
    Veteran Core slot / request state / pending copied build state
  source navigation
    Inventory | Platform
  filter and sort row
  compact core table
```

Required picker behavior:

- Show one Veteran Core display slot in the header area.
- Explain whether the turret can accept a carried core, platform core, or requested core.
- Keep inventory/platform source selection explicit.
- Keep `All` as the default filter, with Base and specialization filters.
- Sort by Name, Level, Specialization, HP, Attack, and Range.
- Show neutral preview values for level, HP, attack, and range.
- Keep exact install actions for carried and platform cores.
- Do not repeat the Veteran Core item icon in every picker row.
- Do not color neutral picker preview stats green or red.

## Visual Rules

- Use one visible shell: titlebar, status strip, navigation, active content pane.
- Use one primary scroll area at a time.
- Avoid nested boxed frames beyond one content grouping depth.
- Do not place independent scroll panes side by side inside the attached panel.
- Use Factorio-native dark surfaces, subheaders, buttons, progress bars, sprite-buttons, and table alignment.
- Use color only for semantic meaning: available points, beneficial values, harmful values, build mode, specialization identity, and element identity.
- Keep status text short enough to survive common UI scales.
- Prefer compact rows and grouped summaries over large cards unless the player is making a high-impact choice.

## Refresh Contract

- Opening, closing, and changing installed/empty mode may rebuild the whole panel.
- Switching selected views may rebuild the active content pane.
- Steady-state refresh should update named labels/progress bars/buttons without destroying the active view unless its structural key changes.
- View selection should persist per player while reopening compatible installed-core panels.
- Empty picker sort/filter/source selection should persist per player.

## Layout Regression Contract

Automated tests should fail when:

- Installed mode lacks a status strip, view navigation, or active content pane.
- More than one installed content view is visible at once.
- Stats rows appear in Overview.
- Automation detail controls appear outside Automation, except compact status indicators/actions.
- Empty turret mode uses the installed dashboard shell.
- Empty picker rows repeat the Veteran Core item icon.
- A new GUI mode adds a second permanent scroll region beside the active content pane.

Manual screenshot review remains required before calling the redesign successful. Headless tests can prove structure and behavior; they cannot prove that the panel is visually good.

## Acceptance Criteria

- The first installed-core view is calm and understandable at a glance.
- The panel no longer resembles the old left-stats/right-evolution dashboard.
- A player can find progression, stats, and automation without seeing all of them at once.
- The empty picker is a focused install workflow.
- The GUI is readable at common UI scales.
- If a static shell screenshot still looks like the old GUI, behavior wiring should stop until the shell is redesigned again.
