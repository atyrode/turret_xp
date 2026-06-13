local support = require("support")

local assert_true = support.assert_true
local assert_eq = support.assert_eq
local create_turret = support.create_turret
local call = support.call

local tests = {}
function tests.run_layout_constants_test()
  local layout = call("layout")
  assert_true(type(layout) == "table", "layout constants were not exposed to the headless suite")
  assert_eq(
    layout.left_column_width + layout.evolution_column_width + layout.column_spacing,
    layout.panel_width,
    "panel width must derive from the column model"
  )
  assert_eq(layout.evolution_scroll_width, layout.evolution_column_width, "Evolution scroll pane should own the full right-column viewport")
  assert_eq(
    layout.evolution_content_width,
    layout.evolution_scroll_width - 28,
    "Evolution content width must reserve the default scrollbar lane"
  )
  assert_eq(
    layout.evolution_section_width,
    layout.evolution_content_width - (layout.evolution_section_margin * 2),
    "Evolution section width must reserve visible side margins"
  )
  assert_eq(layout.evolution_inner_width, layout.evolution_section_width - 16, "Evolution inner rows must derive from section width")
  assert_eq(layout.evolution_card_inner_width, layout.evolution_inner_width - 28, "Element-card child rows must account for card padding")
  assert_true(layout.evolution_inner_width < layout.evolution_scroll_width, "Evolution rows must stay inside the scroll viewport")
  assert_true(layout.evolution_detail_width < layout.evolution_inner_width, "Evolution text details must stay capped inside inner rows")
  assert_true(layout.stats_header_height > 0, "Stats pane must reserve a visible subheader")
  assert_true(layout.stats_scroll_width < layout.left_column_width, "Stats pane must stay inside the left column")
end

function tests.run_gui_support_samples_test()
  local samples = call("gui_support_samples")
  assert_eq(samples.percent, "12.5%", "GUI percent formatting changed")
  assert_eq(samples.color, "0.55,0.82,0.55", "GUI rich color conversion changed")
  assert_eq(samples.rich_number, "[color=0.55,0.82,0.55]+5[/color]", "GUI rich number formatting changed")
  assert_eq(
    samples.rich_stat,
    "Damage [color=0.55,0.82,0.55]+5[/color] [color=0.55,0.82,0.55]x1.2[/color]",
    "GUI rich stat token formatting changed"
  )
end

function tests.run_profile_label_test(surface)
  local turret = create_turret(surface, { 0, 0 }, 10)
  local summary = call("install_core", turret, {
    custom_name = "Alpha",
    show_name_label = true,
    label_color = { 1, 0.86, 0.46 },
    label_color_preset = "gold",
  })

  assert_true(summary ~= nil, "install_core returned no profile summary")
  assert_eq(summary.custom_name, "Alpha", "core custom name did not persist")
  assert_eq(summary.show_name_label, true, "show label flag did not persist")
  assert_eq(summary.label_color_preset, "gold", "preset label color did not persist")
  assert_eq(summary.label_entity_valid, false, "preset label unexpectedly used a display-panel entity")
  assert_true(summary.name_render_valid, "enabled label did not create a render object")

  summary = call("set_profile", turret, {
    label_color = { 0.12, 0.34, 0.56 },
    label_color_preset = "custom",
  })
  assert_eq(summary.label_color_preset, "custom", "RGB label edit did not mark the profile as custom")
  assert_eq(summary.label_entity_valid, false, "custom RGB label unexpectedly used a display-panel entity")
  assert_true(summary.name_render_valid, "custom RGB label did not keep using rendered text")

  summary = call("attach_stale_label_entity", turret)
  assert_true(summary ~= nil, "stale label cleanup did not return a profile summary")
  assert_eq(summary.stale_label_entity_valid, false, "stale display-panel label entity was not destroyed")
  assert_eq(summary.label_entity_valid, false, "stale display-panel label handle was preserved")
  assert_true(summary.name_render_valid, "stale label cleanup did not leave a render object label")
end

function tests.run_gui_action_dispatch_test(surface)
  local turret = create_turret(surface, { 4, 0 }, 10)
  local summary = call("install_core", turret, {
    custom_name = "Dispatch",
    show_name_label = true,
    label_color = { 1, 0.86, 0.46 },
    label_color_preset = "gold",
  })
  assert_true(summary ~= nil, "failed to install core for GUI action dispatch test")

  summary = call("dispatch_cycle_label_color", turret)
  assert_true(summary ~= nil, "GUI action dispatch did not return a turret summary")
  assert_eq(summary.label_color_preset, "white", "GUI action dispatch did not cycle the label color preset")
  assert_eq(summary.label_color[1], 1, "GUI action dispatch changed the red label channel unexpectedly")
  assert_eq(summary.label_color[2], 1, "GUI action dispatch did not update the green label channel")
  assert_eq(summary.label_color[3], 1, "GUI action dispatch did not update the blue label channel")

  summary = call("dispatch_toggle_label_level", turret, false)
  assert_true(summary ~= nil, "GUI checked-state dispatch did not return a turret summary")
  assert_eq(summary.show_label_level, false, "GUI checked-state dispatch did not hide the level suffix")

  summary = call("dispatch_toggle_label_level", turret, true)
  assert_true(summary ~= nil, "GUI checked-state dispatch did not return a turret summary after re-enable")
  assert_eq(summary.show_label_level, true, "GUI checked-state dispatch did not restore the level suffix")
end

return tests
