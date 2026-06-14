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
  assert_true(layout.stats_section_header_height > 0, "Stats groups must reserve visible section headers")
  assert_true(layout.stats_section_header_top_margin > 0, "Stats group headers after the first must have separation")
  assert_true(layout.stats_section_header_bottom_margin > 0, "Stats group headers must separate from their rows")
  assert_true(layout.core_identity_slot_size > 0, "core identity slot must have an explicit size")
  assert_true(layout.core_identity_detail_width > 0, "installed core identity text must retain a positive width")
  assert_true(
    layout.core_identity_empty_detail_width > layout.core_identity_detail_width,
    "empty core identity text should expand in the full-width empty panel"
  )
  assert_eq(
    layout.core_identity_actions_width,
    layout.core_identity_tool_button_size + layout.core_identity_action_button_width + layout.core_identity_action_spacing,
    "core identity action width must derive from button and spacing budgets"
  )
  assert_true(layout.stats_scroll_width < layout.left_column_width, "Stats pane must stay inside the left column")
  assert_true(layout.inventory_core_picker_width < layout.left_column_width, "inventory core picker must stay inside the left column")
  assert_eq(layout.empty_panel_width, layout.panel_width, "empty core panel should use the full two-column shell width")
  assert_true(
    layout.empty_inventory_core_picker_width > layout.inventory_core_picker_width,
    "empty core picker should expand beyond the left column"
  )
  assert_true(
    layout.empty_inventory_core_picker_height > layout.inventory_core_picker_height,
    "empty core picker should reserve a tall viewport"
  )
  assert_true(
    layout.inventory_core_detail_width < layout.inventory_core_picker_width,
    "inventory core row details must reserve icon/action space"
  )
  assert_true(
    layout.empty_inventory_core_detail_width < layout.empty_inventory_core_picker_width,
    "wide inventory core row details must reserve stats/action space"
  )
  assert_eq(
    layout.stats_label_width + layout.stats_value_width + 12,
    layout.stats_content_width,
    "stats label/value widths must derive from the scroll content width"
  )
  local wide_table_width = layout.empty_inventory_core_level_width
    + layout.empty_inventory_core_name_width
    + layout.empty_inventory_core_specialization_width
    + layout.empty_inventory_core_stat_width
    + layout.empty_inventory_core_attack_width
    + layout.empty_inventory_core_stat_width
    + layout.empty_inventory_core_action_width
    + ((layout.inventory_core_table_column_count - 1) * layout.inventory_core_table_spacing)
    + layout.empty_inventory_core_table_cell_padding_width
  assert_true(
    wide_table_width <= layout.empty_inventory_core_table_width,
    "wide inventory core table columns and spacing must fit inside the reserved table viewport"
  )
  assert_eq(
    layout.empty_inventory_core_name_width + layout.empty_inventory_core_fixed_width,
    layout.empty_inventory_core_table_content_width,
    "wide inventory core table content widths must derive from the padded table content budget"
  )
  assert_true(
    layout.empty_inventory_core_table_width < layout.empty_inventory_core_picker_width,
    "wide inventory core table must reserve the scroll-pane scrollbar lane"
  )
  assert_eq(
    layout.empty_inventory_core_table_width + layout.inventory_core_scrollbar_width + (layout.inventory_core_table_side_margin * 2),
    layout.empty_inventory_core_picker_width,
    "wide inventory core table must reserve equal side margins and the scrollbar lane"
  )
  assert_true(
    layout.empty_inventory_core_action_button_size < layout.empty_inventory_core_action_width,
    "wide inventory core action button must be smaller than its table cell"
  )
  assert_true(
    layout.inventory_core_sort_arrow_slot_width < layout.empty_inventory_core_level_width,
    "wide inventory core sort arrow slot must fit inside compact stat headers"
  )
  assert_true(layout.rank_stepper_button_size > 0, "rank stepper buttons must have an explicit layout size")
  assert_true(layout.rank_stepper_label_width > 0, "rank stepper label must have an explicit layout width")
  assert_eq(
    layout.rank_stepper_width,
    (layout.rank_stepper_button_size * 2) + layout.rank_stepper_label_width + (layout.rank_stepper_spacing * 2),
    "rank stepper total width must derive from button, label, and spacing budgets"
  )
  assert_eq(
    layout.rank_allocation_detail_width
      + layout.rank_allocation_icon_size
      + layout.rank_allocation_value_width
      + layout.rank_stepper_width
      + layout.rank_allocation_spacing_width,
    layout.evolution_inner_width,
    "rank allocation row columns must derive from the Evolution inner width"
  )
  assert_true(layout.rank_allocation_detail_width > 0, "rank allocation detail text must retain a positive width")
  assert_true(
    layout.rank_stepper_width < layout.evolution_inner_width,
    "rank stepper controls must fit inside Evolution rows"
  )
  assert_true(
    layout.empty_inventory_core_name_width < layout.empty_inventory_core_specialization_width,
    "wide inventory core table should favor specialization readability over long names"
  )
end

function tests.run_gui_support_samples_test()
  local samples = call("gui_support_samples")
  assert_eq(samples.percent, "12.5%", "GUI percent formatting changed")
  assert_eq(samples.color, "0.55,0.82,0.55", "GUI rich color conversion changed")
  assert_eq(samples.rich_number, "[color=0.55,0.82,0.55]+5[/color]", "GUI rich number formatting changed")
  assert_eq(samples.rich_value, "[color=0.55,0.82,0.55]42/s[/color]", "GUI rich value formatting changed")
  assert_eq(samples.rich_metric[2], "HP", "GUI rich metric label changed")
  assert_eq(samples.rich_metric[4], "[color=0.55,0.82,0.55]400[/color]", "GUI rich metric value changed")
  assert_eq(samples.rich_specialization[2], "[color=0.45,0.78,1]", "GUI specialization color prefix changed")
  assert_eq(samples.rich_specialization[3], "Sniper", "GUI specialization caption changed")
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

  local rank_turret = create_turret(surface, { 6, 0 }, 10)
  summary = call("install_core", rank_turret, { level = 40 })
  assert_true(summary ~= nil, "failed to install core for GUI rank modifier dispatch test")

  local rank_sample = call("dispatch_rank_modifier_sample", rank_turret)
  assert_true(rank_sample ~= nil, "GUI rank modifier dispatch did not return a sample")
  assert_eq(rank_sample.base_after_ctrl_add, 40, "Ctrl-click did not spend all available core points")
  assert_eq(rank_sample.base_available_after_ctrl_add, 0, "Ctrl-click core allocation left available points")
  assert_eq(rank_sample.base_after_ctrl_remove, 0, "Ctrl-click did not remove all core ranks")
  assert_eq(rank_sample.base_available_after_ctrl_remove, 40, "Ctrl-click core removal did not refund all points")
  assert_eq(rank_sample.augment_after_ctrl_add, 2, "Ctrl-click did not spend all available augment points")
  assert_eq(rank_sample.augment_available_after_ctrl_add, 0, "Ctrl-click augment allocation left available points")
  assert_eq(rank_sample.augment_after_ctrl_remove, 0, "Ctrl-click did not remove all augment ranks")
  assert_eq(rank_sample.augment_available_after_ctrl_remove, 2, "Ctrl-click augment removal did not refund all points")
end

function tests.run_inventory_core_picker_test(surface)
  local turret = create_turret(surface, { 8, 0 }, 10)
  local sample = call("inventory_core_picker_sample", turret)

  assert_true(sample ~= nil, "inventory core picker sample returned nothing")
  assert_eq(#sample.options, 4, "inventory core picker did not discover all tagged cores")
  assert_eq(sample.options[1].name, "High", "inventory core picker did not sort highest level first")
  assert_eq(sample.options[1].slot, 2, "inventory core picker lost the source slot for the highest-level core")
  assert_eq(sample.options[2].name, "Mid", "inventory core picker did not sort the middle-level core second")
  assert_eq(sample.options[3].name, "Low", "inventory core picker did not sort the lower-level named core third")
  assert_eq(sample.options[4].name, "", "inventory core picker did not keep the unnamed core last")
  assert_eq(sample.sort_samples.kills, "Mid", "inventory core picker did not sort highest kills first")
  assert_eq(sample.sort_samples.damage, "Mid", "inventory core picker did not sort highest damage first")
  assert_eq(sample.sort_samples.name, "High", "inventory core picker did not sort alphabetically")
  assert_eq(sample.sort_samples.name_desc, "Mid", "inventory core picker did not reverse name sorting")
  assert_eq(sample.sort_samples.name_last, "", "inventory core picker did not keep unnamed cores last under name sorting")
  assert_eq(sample.sort_samples.display_level_asc, "", "inventory core display sort did not sort level ascending")
  assert_eq(sample.sort_samples.display_level_desc, "High", "inventory core display sort did not sort level descending")
  assert_eq(sample.sort_samples.display_name_asc, "High", "inventory core display sort did not sort name ascending")
  assert_eq(sample.sort_samples.display_name_desc, "Mid", "inventory core display sort did not sort name descending")
  assert_eq(sample.sort_samples.display_specialization_asc, "Low", "inventory core display sort did not sort specialization ascending")
  assert_eq(sample.sort_samples.display_specialization_desc, "High", "inventory core display sort did not sort specialization descending")
  assert_true(sample.sort_samples.display_hp_asc ~= nil, "inventory core display HP ascending sort crashed")
  assert_true(sample.sort_samples.display_hp_desc ~= nil, "inventory core display HP descending sort crashed")
  assert_true(sample.sort_samples.display_attack_asc ~= nil, "inventory core display attack ascending sort crashed")
  assert_true(sample.sort_samples.display_range_asc ~= nil, "inventory core display range ascending sort crashed")
  assert_eq(sample.filter_samples.all_count, 4, "inventory core picker All filter did not include all cores")
  assert_eq(sample.filter_samples.all_filter_enabled, true, "inventory core picker All filter did not normalize as enabled")
  assert_eq(sample.filter_samples.none_filter_enabled, true, "inventory core picker empty filters did not snap back to All")
  assert_eq(
    sample.filter_samples.legacy_all_filter_enabled,
    true,
    "inventory core picker legacy all-selected filters did not normalize to All"
  )
  assert_eq(sample.filter_samples.base_count, 2, "inventory core picker base filter did not include only unspecialized cores")
  assert_eq(sample.filter_samples.base_first, "Low", "inventory core picker base filter did not keep sorted visible rows")
  assert_eq(sample.filter_samples.sniper_count, 1, "inventory core picker specialization filter did not isolate sniper cores")
  assert_eq(sample.filter_samples.sniper_first, "High", "inventory core picker specialization filter returned the wrong core")
  assert_eq(
    sample.persisted_preferences.before_close.sort,
    "name:asc",
    "inventory core picker sort did not store the selected sort before close"
  )
  assert_eq(
    sample.persisted_preferences.after_reopen.sort,
    "name:asc",
    "inventory core picker sort did not persist after reopening the turret GUI"
  )
  assert_eq(
    sample.persisted_preferences.after_reopen.filters.sniper,
    true,
    "inventory core picker specialization filter did not persist after reopening the turret GUI"
  )
  assert_eq(
    sample.persisted_preferences.after_reopen.filters.all,
    false,
    "inventory core picker All filter should remain disabled when a specific persisted filter is active"
  )
  assert_eq(sample.installed.custom_name, "High", "inventory core picker action did not install the selected slot")
  assert_eq(sample.installed.level, 14, "inventory core picker action lost the selected core level")
  assert_eq(sample.installed.evolution.specialization, "sniper", "inventory core picker action lost the selected specialization")
  assert_eq(#sample.remaining_names, 3, "inventory core picker action did not remove one selected inventory core")
  assert_eq(sample.remaining_names[1], "Mid", "remaining inventory cores were not still sorted after install")
  assert_eq(sample.remaining_names[3], "", "remaining inventory cores lost the unnamed core")
end

return tests
