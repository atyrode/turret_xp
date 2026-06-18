# Turret XP GUI Spec

This is the product GUI spec produced from
[GUI_SPEC_FACTORY.md](GUI_SPEC_FACTORY.md). It targets the next Turret XP GUI
redesign tracked by issue #96.

## Status

Status: proposed future implementation, not current shipped behavior.

This spec supersedes the old two-column section-stack direction for future GUI
work. It also supersedes the failed focused-tabs rewrite. The current playable
implementation remains described in [PROJECT_SPEC.md](PROJECT_SPEC.md) until a
new implementation is accepted.

Code MUST NOT implement a new GUI shape that is not represented here. If this
spec is wrong, revise this spec before revising Lua.

## Problem Frame

The existing installed-core GUI exposes many real systems, but it feels like a
stack of implementation sections rather than a coherent player workbench. The
failed focused-tabs rewrite did not solve the product problem because it kept a
similar visual grammar, split related feedback across tabs, and made important
state harder to compare while editing.

The redesign must preserve the core gameplay loop:

- install a Veteran Core into a turret;
- earn XP and levels through combat;
- spend core and augment points;
- choose specialization, sub-specialization, and elements;
- inspect current and planned stats;
- name, label, bind, extract, and move the core;
- use Build Plan and Follow build for copied/blueprinted setup automation;
- pick exact cores for empty turrets from inventory or platform storage.

The redesign must not preserve the old layout by inertia.

## Design Thesis

The installed-core GUI is a Veteran Core Workbench.

The workbench has one main job: let the player shape this core while seeing the
consequences. Progression editing, build planning, and key stat feedback belong
on the same surface. Detailed diagnostics can be expandable or secondary, but
the core loop must not require switching away from the changed stats.

The empty-turret GUI is a Core Picker.

The picker has one main job: choose one exact Veteran Core for this turret. The
existing full-width picker direction is comparatively successful and SHOULD be
preserved unless a later spec proposes a better concrete table.

## Non-Goals And Rejected Shapes

The new installed workbench MUST NOT be:

- the old left-column stats plus right-column Evolution dashboard;
- a focused-tabs dashboard where Progression, Stats, and Automation hide each
  other;
- a generic card grid;
- an overview-first dashboard with no strong job;
- a nested stack of framed sections where every feature competes equally;
- a UI where changing progression hides the stats that changed;
- a UI where Build mode is isolated away from progression editing;
- a UI that repeats explanation text in large empty slabs.

The attached Factorio turret GUI remains the context. This spec does not
replace the vanilla turret GUI with a full custom screen unless Factorio API
constraints force that in a later approved spec change.

## Feature Inventory

| Feature | Current job | New location | State | Notes |
| --- | --- | --- | --- | --- |
| Veteran Core slot | Install, extract, identify exact core | Workbench Header, Core Picker Header | Preserve | Scripted tag-preserving slot remains explicit. |
| Empty inventory core selection | Install exact carried core | Core Picker | Preserve | Keep table-first picker; avoid dashboard shell. |
| Empty platform core selection | Install exact platform hub core | Core Picker source mode | Preserve | Source mode can be tabs or segmented controls. |
| XP and level | Show progress and available budget | Workbench Header | Preserve | Always visible for installed cores. |
| Core point budget | Show spendable base points | Header and Progression Editor | Preserve | Header shows summary; editor owns spend controls. |
| Augment point budget | Show spendable augment points | Header and Progression Editor | Preserve | Same as core budget. |
| Core upgrades | Spend repeatable base ranks | Progression Editor | Preserve | Affected stats preview in Stat Inspector. |
| Specialization | Choose role identity | Progression Editor role path | Preserve | Free choice at gate, with stat impact visible. |
| Sub-specialization | Choose stronger role branch | Progression Editor role path | Preserve | Locked state stays scannable. |
| First and second elements | Choose element identity and combo | Progression Editor element path | Preserve | Material progress visible in row. |
| Element material ranks | Track passive delivered materials | Progression Editor element rows | Preserve | Feeder status belongs here when relevant. |
| Powerful augments | Spend augment ranks | Progression Editor augment path | Preserve | Affected stats preview in Stat Inspector. |
| Evolution reset | Refund choices while preserving identity/history | Header overflow or Progression tools | Preserve | Must be clear, not visually dominant. |
| Build mode | Edit planned target without spending live points | Build Plan Mode in same workbench | Preserve and move | Visible mode toggle next to progression. |
| Follow build | Spend toward saved target in live mode | Mode Bar | Preserve and move | Toggle remains visible while inspecting progression. |
| Copied target state | Explain requested/blocked copied build | Mode Bar and Progression warnings | Preserve | Conflicts must be local to affected choices. |
| Loop priorities | Define repeated spending after finite target | Build Plan controls inside rows | Preserve | Do not duplicate summaries. |
| Detailed stats | Debug full stat breakdown | Detail Drawer | Preserve | Key stats stay pinned; full detail is secondary. |
| Combat history | Inspect kills, damage, XP sources | Detail Drawer | Preserve | Not a core progression-editing anchor. |
| Ammo productivity progress | Inspect loaded magazine/refill progress | Stat Inspector and Detail Drawer | Preserve | Key ammo state visible when relevant. |
| Shield bar/status | Inspect survivability | Stat Inspector and world shield bar | Preserve | Key shield value pinned. |
| Name field | Name core | Core Details Drawer | Preserve | Not a top-level layout driver. |
| Floating label toggles | Choose label parts | Core Details Drawer | Preserve | Keep separate Name, Level, Unspent toggles. |
| Label color picker | Choose world-label color | Color popup from Core Details | Preserve | Popup remains separate `player.gui.screen` surface. |
| Bind/Unbind | Toggle quick-move identity | Workbench Header action | Preserve | Bound state visible in header. |
| Extract | Move core to inventory | Workbench Header action and slot | Preserve | Must be clear and compact. |
| Dev controls | Local testing | Dev Drawer | Preserve hidden | Only visible after `/turret-xp-dev`. |

## Player Jobs

The GUI MUST support these jobs directly:

- Pick the exact Veteran Core to install into an empty turret.
- Understand the installed core's identity, level, XP progress, and bound state.
- Spend a progression point and see affected stats without changing screens.
- Choose a role, element, augment, or sub-role while seeing tradeoffs.
- Toggle Build Plan mode without losing progression context.
- Compare live values against planned values while editing a build target.
- Enable or disable Follow build while seeing what it will spend toward.
- Understand copied-build conflicts at the affected choice.
- Inspect full stats and history when debugging.
- Rename and label the core without crowding the progression editor.
- Extract or bind the core from a clear identity/action header.

## Screens And Modes

### Core Picker

Entry condition: opened turret has no installed Veteran Core.

Primary job: install one exact Veteran Core into this turret.

The Core Picker MUST NOT instantiate the installed workbench. It uses the full
Turret XP panel body for source selection, filters, sort controls, and a compact
table.

Required anchors:

- `Picker Header`: Veteran Core slot, short install instruction, pending copied
  target indicator when relevant.
- `Source Control`: Inventory and Platform when platform cores exist.
- `Filter Sort Row`: All/Base/Specialization filters plus active sort cue.
- `Core Table`: exact rows with install action.
- `Empty State`: concise message inside the table area when no rows match.

### Installed Workbench

Entry condition: opened turret has an installed Veteran Core.

Primary job: shape the core while seeing consequences.

The Installed Workbench has:

- `Workbench Header`: persistent identity and high-level state.
- `Mode Bar`: Live vs Build Plan, Follow build, copied-target warnings.
- `Progression Editor`: main editing surface.
- `Stat Inspector`: pinned consequence surface.
- `Detail Drawer`: optional secondary details, opened intentionally.
- `Core Details Drawer`: optional naming/label controls.

The workbench MAY use two columns, but the semantic split is not old left
metadata vs right Evolution. The main surface is Progression Editor plus pinned
Stat Inspector. The stat inspector must remain visible while editing progression
at normal supported GUI scales.

### Build Plan Mode

Build Plan is a mode of the Installed Workbench, not a separate screen.

In Build Plan Mode:

- progression controls edit the planned target instead of live core ranks;
- current and planned values are shown together where useful;
- the Stat Inspector shows current -> planned deltas;
- Follow build remains visible but cannot be confused with immediate live
  mutation;
- copied-build conflicts appear at the affected row or group.

### Detail Drawer

The Detail Drawer is secondary. It can be a lower expandable panel, a side
drawer, or a modal-like anchored panel if Factorio sizing requires it.

It owns:

- full stat groups;
- formulas;
- combat history;
- active effects;
- deep ammo/productivity details.

It MUST NOT be required for the normal spend-and-see-feedback loop.

### Core Details Drawer

The Core Details Drawer owns:

- custom name field;
- floating label toggles;
- label color swatch and popup trigger;
- dev controls when enabled.

It MUST NOT permanently occupy the primary progression/editor space.

## State Fixtures

These fixtures are required for design review and tests.

```text
id: empty_no_cores
screen: Core Picker
turret: vanilla gun turret
core: none
inventory_cores: 0
platform_cores: 0
expected_primary_job: explain no Veteran Core is available
```

```text
id: empty_inventory_cores
screen: Core Picker
turret: vanilla gun turret
core: none
inventory_cores: 5 mixed levels/specializations
platform_cores: 0
expected_primary_job: install exact inventory core
```

```text
id: empty_platform_cores
screen: Core Picker
turret: space platform gun turret
core: none
inventory_cores: 1
platform_cores: 4
expected_primary_job: choose source and install exact core
```

```text
id: installed_level_0
screen: Installed Workbench
core: unnamed base Veteran Core
level: 0
xp: 0 / 100
unspent_core_points: 0
unspent_augment_points: 0
specialization: none
build_mode: false
follow_build: false
expected_primary_job: show identity and first progression goals
```

```text
id: installed_level_100_unspent
screen: Installed Workbench
core: Veteran Core
level: 100
xp: 0 / 6600
unspent_core_points: 100
unspent_augment_points: 8
specialization: none
build_mode: false
follow_build: false
expected_primary_job: spend points with stat feedback visible
```

```text
id: installed_role_element
screen: Installed Workbench
core: named Sniper core
level: 45
specialization: sniper
sub_specialization: none
elements: fire rank 3
build_mode: false
follow_build: false
expected_primary_job: inspect role tradeoffs and next unlocks
```

```text
id: build_plan_unspent
screen: Installed Workbench
core: level 100 base Veteran Core
build_mode: true
follow_build: false
copied_target: none
expected_primary_job: edit planned ranks and compare current to planned stats
```

```text
id: copied_target_conflict
screen: Installed Workbench
core: manual Sniper core
build_mode: true
follow_build: false
copied_target: Machine Gun target
expected_primary_job: show conflict without hiding compatible spending
```

```text
id: follow_build_active
screen: Installed Workbench
core: partial copied target
build_mode: false
follow_build: true
expected_primary_job: show automatic spending status and locked manual edits
```

```text
id: dev_controls_enabled
screen: Installed Workbench
dev_mode: true
expected_primary_job: expose development controls without changing player-facing layout when hidden
```

## Visibility Matrix

| Element | Core Picker | Live Workbench | Build Plan Mode | Detail Drawer |
| --- | --- | --- | --- | --- |
| Veteran Core slot | yes | yes | yes | optional |
| Install action | yes | no | no | no |
| Extract action | no | yes | yes | no |
| Bind/Unbind action | no | yes | yes | no |
| XP bar | no | yes | yes | optional |
| Core/Augment budget | no | yes | yes | optional |
| Progression controls | no | yes | yes | no |
| Stat Inspector | no | yes | yes | yes |
| Current -> planned deltas | no | optional | yes | optional |
| Build Plan toggle | no | yes | yes | yes |
| Follow build toggle | no | yes | yes | yes |
| Copied target warning | optional | yes when relevant | yes when relevant | optional |
| Full formulas | no | hidden | hidden | yes |
| Combat history | no | hidden | hidden | yes |
| Name and label controls | no | hidden | hidden | optional |
| Dev controls | hidden | hidden unless dev mode | hidden unless dev mode | optional |

`optional` means the element may appear if it supports the drawer's current
job, but it is not required as a primary anchor there.

## ASCII Wireframes

### Core Picker

```text
Turret XP - Core Picker
+------------------------------------------------------------------+
| [Picker Header: core slot] Install Veteran Core                  |
| Choose a carried or platform core for this turret.               |
+------------------------------------------------------------------+
| [Source Control: Inventory | Platform]        [available count]  |
| [Filter Sort Row: All Base Sniper MG Bulwark Brawler | Sort]     |
+------------------------------------------------------------------+
| [Core Table]                                                     |
| Level | Name | Role | HP | Attack | Range | [Install]            |
| 100   | ...  | ...  | .. | ...    | ...   | +                   |
| ...                                                              |
| [Scroll only when row cap is exceeded]                           |
+------------------------------------------------------------------+
```

### Installed Workbench

```text
Turret XP - Veteran Core Workbench
+------------------------------------------------------------------+
| [Workbench Header]                                               |
| [slot] Veteran Core      Level 100     XP: 0 / 6600              |
| Bound: no             Core 100 / Aug 8       [Extract] [Bind]    |
+------------------------------------------------------------------+
| [Mode Bar]  Live | Build Plan    [Follow build] [target status]  |
+-------------------------------------------+----------------------+
| [Scroll: Progression Editor]              | [Pinned: Stat        |
| [Budget Strip] Core 100  Aug 8            |  Inspector]          |
|                                           | Damage        20     |
| Core Upgrades                             | DPS           25/s   |
|  icon Damage       Rank 0   +0.5 / shot   | Range         18     |
|                    [-] 0 [+]              | HP/Shield     400    |
|  icon Shield       Rank 0   +10 shield    | Resistance    0%     |
|                    [-] 0 [+]              | Crit          0/50%  |
|                                           | Ammo          status |
| Role Path                                 | [Details]            |
|  Sniper / Machine Gun / Bulwark / Brawler |                      |
|                                           |                      |
| Elements                                  |                      |
|  Fire rank 3: material progress           |                      |
|                                           |                      |
| Augments                                  |                      |
|  Regeneration, Bounce, Double Shot...     |                      |
+-------------------------------------------+----------------------+
| [Collapsed Core Details: name, label, color] [when opened]       |
+------------------------------------------------------------------+
```

### Build Plan Mode

```text
Turret XP - Veteran Core Workbench
+------------------------------------------------------------------+
| [Workbench Header] current core identity and XP                  |
+------------------------------------------------------------------+
| [Mode Bar]  Live | Build Plan    [Follow build] [plan status]    |
+-------------------------------------------+----------------------+
| [Scroll: Progression Editor edits plan]    | [Pinned: Stat       |
| [Budget Strip] Planned Core 100 / Aug 8    |  Inspector]         |
|                                           | Damage 20 -> 27     |
| Core Upgrades                             | DPS    25 -> 33/s   |
|  Damage  Live 0  Plan 14  +7 / shot       | Range  18 -> 18     |
|          [-] 14 [+] [Loop forever]        | HP     400 -> 400   |
|                                           | Warnings, if any    |
| Role Path                                 |                      |
|  Current: none   Planned: Sniper          |                      |
|                                           |                      |
| [Conflict rows appear at affected choices, not in a separate tab] |
+-------------------------------------------+----------------------+
```

### Detail Drawer

```text
[Detail Drawer]
+------------------------------------------------------------------+
| Stats | History | Effects                                        |
| Identity: role, elements, bound state                            |
| Defense: HP, shield, resistance, regeneration                    |
| Offense: speed, range, damage, DPS, crit                         |
| Ammo: magazine, ammo count, productivity progress                |
| History: kills, damage, XP contribution                          |
+------------------------------------------------------------------+
```

## Component Contracts

### Workbench Header

Purpose: keep identity and high-level state visible.

Inputs: core profile, turret binding state, XP summary, point budgets,
inventory/extract availability.

Outputs/actions: Extract, Bind/Unbind, slot interaction, optional Details
entry.

Always visible: core slot, display name, level, XP progress, bound state, core
budget, augment budget, Extract, Bind/Unbind.

Never shows: progression rows, full formulas, name form, label color controls.

Sizing rules: one compact header band; action buttons fixed width; XP bar does
not resize action controls.

Test anchors: `turret_xp_workbench_header`, `turret_xp_core_slot`,
`turret_xp_xp_bar`, `turret_xp_bind_action`.

### Mode Bar

Purpose: choose mutation target and expose automation state without hiding
progression.

Inputs: build mode, follow state, copied target summary, conflict summary.

Outputs/actions: toggle Live/Build Plan, toggle Follow build, open target
details when needed.

Always visible: Live/Build Plan control and Follow build control.

Visible only when: copied target warnings appear only when relevant.

Never shows: full progression lists or full stats.

Test anchors: `turret_xp_mode_bar`, `turret_xp_build_plan_toggle`,
`turret_xp_follow_build_toggle`.

### Progression Editor

Purpose: edit live or planned progression choices.

Inputs: profile evolution, build target, available budgets, unlock gates,
current stats, planned stats.

Outputs/actions: spend/refund ranks, pick specialization, pick
sub-specialization, pick elements, reset or change local choices, set loop
priorities in Build Plan Mode.

Always visible: budget strip and unlocked/next progression groups.

Visible only when: locked groups show compact gate rows; conflict messages show
only on affected rows.

Never shows: full combat history, floating-label form, dev controls.

Scroll behavior: this is the primary scroll region in the installed workbench.
The Stat Inspector is outside this scroll region.

Refresh behavior: rank clicks update affected row, budgets, and Stat Inspector
without rebuilding unrelated stable controls.

Test anchors: `turret_xp_progression_editor`,
`turret_xp_progression_core_upgrades`, `turret_xp_progression_role_path`,
`turret_xp_progression_elements`, `turret_xp_progression_augments`.

### Stat Inspector

Purpose: show consequences while editing.

Inputs: current stats, planned stats, selected/hovered row context where
available.

Outputs/actions: open Detail Drawer.

Always visible in installed workbench: damage, estimated DPS or available
damage proxy, shooting speed, range, HP, shield when relevant, resistance,
crit, ammo/productivity when relevant.

Visible only when: current -> planned deltas appear in Build Plan Mode or when
previewing a live spend before confirmation if such preview exists.

Never shows: point spend controls or long prose.

Scroll behavior: pinned; no vertical scroll in normal fixtures. If the UI scale
cannot fit all rows, lower-priority rows collapse under Details before the
inspector itself scrolls.

Color rules: unchanged values neutral; beneficial numeric deltas muted green;
harmful numeric deltas muted red; units and prose neutral.

Test anchors: `turret_xp_stat_inspector`, `turret_xp_stat_damage`,
`turret_xp_stat_dps`, `turret_xp_stat_range`, `turret_xp_stat_hp`.

### Core Picker Table

Purpose: install one exact Veteran Core into an empty turret.

Inputs: inventory cores, platform cores, filter state, sort state, copied target
policy.

Outputs/actions: source selection, filter selection, sort header clicks,
install exact row.

Always visible: table header, source/filter controls, exact install action for
each row.

Visible only when: Platform source appears when platform cores are available.

Never shows: installed workbench progression editor or stat inspector.

Sizing rules: capped row height before scrolling; no dead vertical slab when
few rows exist; neutral preview stats.

Test anchors: `turret_xp_core_picker`, `turret_xp_core_picker_table`,
`turret_xp_core_picker_source`, `turret_xp_core_picker_filter_sort`.

## Behavior Scenarios

```gherkin
Scenario: Empty turret opens picker mode
  Given a gun turret has no installed Veteran Core
  When the player opens the turret GUI
  Then the Turret XP panel shows the Core Picker
  And the Installed Workbench anchors are absent
```

```gherkin
Scenario: Spending a live point keeps affected stats visible
  Given the Installed Workbench is open for a level 100 core with unspent points
  When the player clicks the Damage plus control
  Then the Damage rank increases by 1
  And the core point budget decreases by 1
  And the Stat Inspector remains visible
  And the Stat Inspector shows the changed damage value without changing screens
```

```gherkin
Scenario: Build Plan mode edits planned ranks on the same surface
  Given the Installed Workbench is open in Live mode
  When the player switches to Build Plan mode
  Then the Progression Editor remains visible
  And the Stat Inspector remains visible
  And rank controls mutate the planned target instead of live ranks
  And the Stat Inspector shows current to planned deltas
```

```gherkin
Scenario: Follow build is visible while inspecting progression
  Given the installed core has a saved build target
  When the player views the Progression Editor
  Then the Follow build toggle is visible in the Mode Bar
  And the player does not need to open a separate Automation tab
```

```gherkin
Scenario: Copied target conflict is local to the affected choice
  Given a Sniper core has a copied Machine Gun target
  When the player opens Build Plan mode
  Then the Role Path group shows the specialization conflict
  And compatible core upgrade rows remain editable
```

```gherkin
Scenario: Detailed stats are secondary but reachable
  Given the Installed Workbench is open
  When the player opens Details from the Stat Inspector
  Then full stat groups and combat history are shown
  And closing Details returns to the same progression scroll position
```

## Visual Style And Tokens

The GUI should feel like a Factorio-native engineering workbench: dense,
legible, mechanical, and deliberate. It should not look like a web dashboard
ported into Factorio.

Tokens:

- `shell`: native Factorio frame attached beside the vanilla turret GUI.
- `header_band`: compact native band for identity and actions.
- `mode_bar`: one shallow row below the header; no card treatment.
- `editor_row`: stable compact row with fixed icon, label, effect, and controls.
- `inspector`: pinned consequence panel with stronger value alignment than
  decorative framing.
- `section_header`: native dark strip with gold title for major editor groups.
- `neutral_value`: plain light text.
- `benefit_delta`: muted green numeric improvements only.
- `harm_delta`: muted red numeric drawbacks only.
- `element_value`: element colors only for elemental damage or element identity.
- `warning_inline`: restrained amber conflict text near the affected row.
- `disabled`: native disabled gray for locked gates and unavailable actions.

Style rules:

- Use icons in fixed cells; icon art must not collide with text at UI scale.
- Keep text short and action-oriented.
- Do not repeat explanatory copy in empty slabs.
- Do not put cards inside cards.
- Use scrollbars only for clear overflow regions.
- Reserve red/green for semantic deltas, not picker preview stats.
- Keep rows aligned even when controls are disabled or locked.
- Avoid large blank panels; if content is absent, show a concise empty state
  inside the component that would otherwise contain rows.

## Visual Review Gates

Gate 1: static shell screenshots before behavior wiring.

Required screenshots:

- `empty_no_cores`
- `empty_inventory_cores`
- `installed_level_0`
- `installed_level_100_unspent`
- `build_plan_unspent`
- `copied_target_conflict`

Review questions:

- Does the first read match the fixture's primary job?
- Are progression edits and key stat feedback visible together?
- Is Build Plan a visible mode of the workbench, not a separate page?
- Is Follow build visible without opening an Automation tab?
- Does the empty picker keep the successful table-first shape?
- Does the screen avoid the old left-stats/right-Evolution dashboard shape?
- Does the screen avoid the failed focused-tabs shape?
- Are there dead slabs, clipped rows, or text under scrollbars?

If any answer fails, stop and revise this spec before wiring behavior.

Gate 2: behavior screenshots after each wired slice.

Required screenshot slices:

- one core upgrade spend;
- one specialization choice;
- one element material progress fixture;
- Build Plan rank edit with current -> planned stat deltas;
- copied-target conflict;
- opened Detail Drawer;
- opened Core Details Drawer.

## Automated Test Contracts

Structural GUI tests SHOULD prove:

- empty turret creates `turret_xp_core_picker` and not
  `turret_xp_installed_workbench`;
- installed turret creates `turret_xp_installed_workbench`;
- installed workbench includes Workbench Header, Mode Bar, Progression Editor,
  and Stat Inspector anchors;
- Stat Inspector is not inside the Progression Editor scroll region;
- Build Plan mode preserves Progression Editor and Stat Inspector anchors;
- Follow build control is visible in Live and Build Plan modes when relevant;
- full stat history is absent from the primary workbench until Details opens;
- Core Details controls are absent until the drawer opens;
- picker source/filter/sort choices persist across close/reopen;
- rank spend updates budgets and inspector values.

Headless behavior tests SHOULD continue to cover gameplay mutation. Structural
tests do not replace profile, automation, feeder, or combat tests.

## Implementation Sequence

1. Commit this spec and the factory document with no Lua changes.
2. Build only the static shell for Core Picker and Installed Workbench.
3. Capture required Gate 1 screenshots.
4. If screenshots fail the spec, revise the spec and shell before behavior
   wiring.
5. Wire Core Picker behavior, preserving exact-slot install and sort/filter.
6. Wire Workbench Header and Mode Bar.
7. Wire Progression Editor core upgrades plus Stat Inspector updates.
8. Wire role path, elements, augments, and sub-specialization.
9. Wire Build Plan mode and Follow build visibility.
10. Wire Details and Core Details drawers.
11. Update structural tests and screenshot fixtures as each slice lands.
12. Run full validation before requesting review.

## Open Questions

- Should the Detail Drawer open below the workbench body, replace the Stat
  Inspector temporarily, or use a separate anchored screen popup?
- Should row hover or selection change the Stat Inspector focus, or should the
  inspector show only current/planned totals?
- What is the minimum supported Factorio interface scale for keeping the Stat
  Inspector pinned beside the Progression Editor?
- Should Evolution reset live in the Workbench Header overflow, the Progression
  Editor budget strip, or a local group action?
- Which stat subset is mandatory in the pinned inspector when ammo is missing?
