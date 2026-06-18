# GUI Spec

This document owns the current Turret XP GUI rewrite contract. It describes what the GUI must show, how the major surfaces are arranged, and which layout rules are mandatory. It is intentionally implementation-neutral: it should be used to build and review the GUI without treating any previous panel code as the source of truth.

## Rewrite Goal

The attached Turret XP panel should feel like one Factorio-native tool beside the vanilla turret GUI. It should make the opened turret answer these questions quickly:

- Is a Veteran Core installed or pending?
- What is this core's identity, level, binding, label state, and movement action?
- Is Build mode active, following a planned build, or idle?
- How close is the core to the next level or planned required level?
- What are the turret's current stats and active tradeoffs?
- What Evolution choices are available, locked, selected, or being planned?
- If no core is installed, which exact carried or platform core can be installed?

The rewrite should not preserve an old layout merely because code already exists for it. Existing names, tags, events, profile fields, and formatting helpers may be treated as integration contracts. Panel construction, section composition, spacing, and refresh ownership should be fresh.

## Surfaces

### Installed Core

Installed-core mode uses a two-column dashboard.

Left column:

- Veteran Core identity and actions.
- Label/name controls.
- Build mode controls.
- Level and XP progress.
- Dev controls when enabled.
- Stats with fixed header and bounded scroll body.

Right column:

- Evolution with fixed summary header and one bounded scroll body.

### Empty Turret

Empty-turret mode uses the full attached panel width as a core picker.

Top area:

- Veteran Core slot-style control.
- Core request or pending copied-build state when relevant.
- Short install explanation.

Picker area:

- Inventory core filters.
- Sortable inventory core table.
- Exact-slot install action.
- Platform hub core list when the opened turret is on a platform.

## Left Column Layout Grammar

The left column must use one predictable stack model.

- The shell owns top-level vertical spacing.
- Every top-level left-column region uses the same section primitive unless it is a fixed-header scroll pane.
- Core, label, Build mode, Level, Dev, and any future top-stack region are sibling sections with the same width, padding, and margin contract.
- Stats is the only left-column fixed-header scroll pane in installed mode.
- No top-level left-column child may rely on one-off sibling `top_margin` or `bottom_margin` to create rhythm.
- Build mode can tint a section, but it must not change that section's role, width, or sibling spacing.
- The Level section is always a real section with a title/summary row and a progress bar. It must never be a bare strip between panels.

Expected installed order:

```text
left column
  section: Veteran Core
  section: Label
  section: Build
  section: Level
  section: Dev, only when enabled
  pane: Stats
```

Expected empty order:

```text
full-width body
  section: Veteran Core
  section: Inventory Cores
  section: Platform Cores, only when applicable
```

## Required Values

### Veteran Core

Show:

- Scripted Veteran Core slot.
- Core display name or empty/pending state.
- Level.
- Bound or unbound state.
- Extract action when installed.
- Bind or Unbind action when installed.
- Dev-create action only when dev controls are enabled and no core is installed.

Do not show Build mode controls inside the Veteran Core section.

### Label

Show only when a core is installed:

- Name text field.
- Label visibility toggles for Name, Level, and Unspent.
- Color swatch and picker action when any floating-label output is enabled.

### Build

Show only when a core is installed.

When Build mode is inactive:

- Title.
- Follow build checkbox only when an unfinished target exists.
- Enter action.

When Build mode is active:

- Title with active tint.
- Exit action.
- Target summary rows for required level, core point spending, augment spending, specialization, and elements.
- A neutral empty-target summary when no plan exists.

### Level

Show only when a core is installed.

Live mode:

- Level.
- Current XP and required XP.
- Percent suffix.
- XP progress bar.
- Combat XP modifier line only when the modifier summary is visible.

Build preview mode:

- Live level.
- Required planned level or open-ended required level.
- Level progress toward the planned requirement.
- XP modifier line hidden unless the preview model explicitly requires one.

### Stats

Show only when a core is installed. The Stats pane keeps the existing grouped value contract:

- Identity.
- Defense.
- Offense.
- Ammo.
- History.
- Effects.

The header is fixed. The scroll body reserves scrollbar space so values do not render underneath a scrollbar.

### Evolution

Show only when a core is installed. Evolution owns progression decisions and remains the right column:

- Summary header with available core/augment points or Build-mode planned points.
- Reset action.
- Locked and unlocked sections with consistent headers.
- Rank steppers for core upgrades and augments.
- Choice rows for specialization, sub-specialization, elements, and combos.
- Material progress inside unlocked element sections.

### Empty Core Picker

Show when no core is installed:

- One Veteran Core display slot in the top section.
- Inventory count.
- `All` filter plus Base and specialization filters.
- Sortable table headers for Name, Level, Specialization, HP, Attack, and Range.
- Neutral preview values for level, HP, attack, and range.
- Exact `+` install action for each row.
- Platform hub rows when available.

Do not repeat the Veteran Core item icon in every inventory row. Do not color neutral picker preview stats green or red.

## Refresh Contract

- Opening, closing, and mode switches may rebuild the full panel.
- Steady-state refreshes should update named values or rebuild only keyed sections whose data changed.
- Build mode, Follow build, label controls, inventory picker sort/filter, and Evolution actions must keep stable element names and action tags.
- Any refresh key must include only data that changes rendered structure or visible values.

## Layout Regression Contract

Automated layout tests should fail when:

- A left-column top-level child is neither a left section nor an approved fixed-header pane.
- Core, Build, Level, and Dev use different section widths.
- A top-level left section has ad hoc sibling margins.
- Build mode changes hierarchy instead of style.
- Build controls appear inside the Veteran Core section.
- The Level section is missing or not tagged as a left section.
- Stats lacks a fixed header and bounded scroll body.

Manual screenshot review remains required for final acceptance because Factorio headless tests cannot prove final rendered pixel spacing.

## Acceptance Criteria

- The first view reads as one attached Factorio panel, not stacked fragments.
- Veteran Core, Label, Build, Level, Dev, Stats, and Evolution each have a clear purpose.
- The top stack has consistent spacing and section boundaries at 75%, 100%, and automatic UI scale.
- Build mode tint is visible but restrained.
- No control jumps position because optional summary text appears or disappears.
- Empty-turret picker stays compact with few cores and scrolls with many cores.
- New left-column features have one obvious primitive to use.
- Headless structural contracts and local Lua checks pass.
- Screenshot review artifacts are captured or the remaining visual risk is stated explicitly.
