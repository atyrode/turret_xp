local domain = require("scripts.domain")
local label_colors = require("scripts.control.label_colors")

local prefix = domain.names.mod_prefix

local gui = {
  panel = prefix .. "panel",
  panel_columns = prefix .. "panel-columns",
  panel_body = prefix .. "panel-body",
  sort_arrow_up = domain.names.sort_arrow_up,
  sort_arrow_down = domain.names.sort_arrow_down,
  core = prefix .. "core",
  core_slot = prefix .. "core-slot",
  core_status = prefix .. "core-status",
  core_actions = prefix .. "core-actions",
  core_name = prefix .. "core-name",
  core_name_visible = prefix .. "core-name-visible",
  core_name_level_visible = prefix .. "core-name-level-visible",
  core_color_preview = prefix .. "core-color-preview",
  core_color_swatch = prefix .. "core-color-swatch",
  core_color_picker = prefix .. "core-color-picker",
  core_color_picker_header = prefix .. "core-color-picker-header",
  core_color_picker_title = prefix .. "core-color-picker-title",
  core_color_r = prefix .. "core-color-r",
  core_color_g = prefix .. "core-color-g",
  core_color_b = prefix .. "core-color-b",
  core_color_r_value = prefix .. "core-color-r-value",
  core_color_g_value = prefix .. "core-color-g-value",
  core_color_b_value = prefix .. "core-color-b-value",
  inventory_cores = prefix .. "inventory-cores",
  inventory_core_filters = prefix .. "inventory-core-filters",
  platform_cores = prefix .. "platform-cores",
  level = prefix .. "level",
  xp = prefix .. "xp",
  xp_bar = prefix .. "xp-bar",
  xp_percent = prefix .. "xp-percent",
  hp = prefix .. "hp",
  shooting_speed = prefix .. "shooting-speed",
  range = prefix .. "range",
  ammo = prefix .. "ammo",
  magazine = prefix .. "magazine",
  ammo_productivity = prefix .. "ammo-productivity",
  ammo_productivity_bar = prefix .. "ammo-productivity-bar",
  ammo_productivity_label = prefix .. "ammo-productivity-label",
  damage = prefix .. "damage",
  dps = prefix .. "dps",
  kills = prefix .. "kills",
  damage_dealt = prefix .. "damage-dealt",
  stats_header = prefix .. "stats-header",
  stats = prefix .. "stats",
  stats_scroll = prefix .. "stats-scroll",
  dev = prefix .. "dev",
  evolution_summary = prefix .. "evolution-summary",
  evolution = prefix .. "evolution",
  active_elements = prefix .. "active-elements",
  active_specialization = prefix .. "active-specialization",
  active_sub_specialization = prefix .. "active-sub-specialization",
  active_combo = prefix .. "active-combo",
  element_progress_bar = prefix .. "element-progress-bar",
}

local color = {
  caption = { 0.62, 0.62, 0.62 },
  muted = { 0.74, 0.74, 0.74 },
  section_header = { 1, 0.86, 0.46 },
  bonus = { 0.55, 0.82, 0.55 },
  penalty = { 0.95, 0.50, 0.48 },
  specialization = {
    base = { 0.74, 0.74, 0.74 },
    sniper = { 0.45, 0.78, 1 },
    machine_gun = { 0.55, 0.82, 0.55 },
    bulwark = { 1, 0.86, 0.46 },
    brawler = { 1, 0.36, 0.30 },
  },
  label_presets = label_colors.presets,
}

local layout = {
  column_spacing = 8,
  left_column_width = 380,
  evolution_column_width = 430,
  core_panel_padding = 16,
  inventory_core_frame_padding = 32,
  inventory_core_scrollbar_width = 20,
  inventory_core_table_side_margin = 8,
  inventory_core_table_spacing = 0,
  inventory_core_table_column_count = 7,
  inventory_core_table_cell_horizontal_padding = 4,
  inventory_core_sort_arrow_slot_width = 12,
  inventory_core_table_header_height = 24,
  inventory_core_table_row_height = 30,
  core_identity_slot_size = 40,
  core_identity_tool_button_size = 28,
  core_identity_action_button_width = 82,
  core_identity_action_spacing = 4,
  platform_core_icon_size = 34,
  label_color_picker_min_width = 300,
  evolution_outer_height = 760,
  evolution_header_height = 36,
  stats_header_height = 34,
  stats_height = 360,
  stats_value_width = 190,
  stats_section_header_height = 24,
  stats_section_header_top_margin = 8,
  stats_section_header_bottom_margin = 3,
  evolution_card_icon_size = 28,
  evolution_card_action_width = 64,
  evolution_effect_table_spacing = 8,
  rank_stepper_button_size = 30,
  rank_stepper_label_width = 24,
  rank_stepper_spacing = 4,
  rank_allocation_icon_size = 28,
  rank_allocation_value_width = 96,
  rank_allocation_horizontal_spacing = 8,
  inventory_core_picker_height = 230,
  empty_inventory_core_picker_min_rows = 4,
  empty_inventory_core_picker_max_rows = 6,
  empty_inventory_core_picker_vertical_padding = 10,
}

layout.panel_width = layout.left_column_width + layout.evolution_column_width + layout.column_spacing
layout.panel_max_width = layout.panel_width + 24
layout.empty_panel_width = layout.panel_width
layout.empty_panel_max_width = layout.panel_max_width
layout.core_identity_actions_width = layout.core_identity_tool_button_size
  + layout.core_identity_action_button_width
  + layout.core_identity_action_spacing
layout.core_identity_detail_width = layout.left_column_width
  - layout.core_panel_padding
  - layout.core_identity_slot_size
  - layout.core_identity_actions_width
  - 24
layout.core_identity_empty_detail_width = layout.empty_panel_width
  - layout.core_panel_padding
  - layout.core_identity_slot_size
  - layout.core_identity_tool_button_size
  - 32
layout.platform_core_row_detail_width = layout.left_column_width
  - layout.core_panel_padding
  - layout.platform_core_icon_size
  - layout.core_identity_tool_button_size
  - 24
layout.stats_scroll_width = layout.left_column_width - 16
layout.stats_content_width = layout.stats_scroll_width - 30
layout.stats_label_width = layout.stats_content_width - layout.stats_value_width - 12
layout.inventory_core_picker_width = layout.left_column_width - layout.core_panel_padding - layout.inventory_core_frame_padding
layout.inventory_core_detail_width = layout.inventory_core_picker_width - layout.inventory_core_scrollbar_width - 112
layout.empty_inventory_core_picker_width = layout.empty_panel_width - layout.core_panel_padding - layout.inventory_core_frame_padding
layout.empty_inventory_core_picker_height = layout.inventory_core_table_header_height
  + (layout.inventory_core_table_row_height * layout.empty_inventory_core_picker_max_rows)
  + layout.empty_inventory_core_picker_vertical_padding
layout.empty_inventory_core_table_width = layout.empty_inventory_core_picker_width
  - layout.inventory_core_scrollbar_width
  - (layout.inventory_core_table_side_margin * 2)
layout.empty_inventory_core_table_cell_padding_width = 0
layout.empty_inventory_core_table_content_width = layout.empty_inventory_core_table_width
layout.inventory_core_sample_slot_size = 32
layout.empty_inventory_core_specialization_width = 250
layout.empty_inventory_core_level_width = 64
layout.empty_inventory_core_stat_width = 68
layout.empty_inventory_core_attack_width = 84
layout.empty_inventory_core_action_width = 38
layout.empty_inventory_core_action_button_size = 26
layout.empty_inventory_core_fixed_width = layout.empty_inventory_core_level_width
  + layout.empty_inventory_core_specialization_width
  + layout.empty_inventory_core_stat_width
  + layout.empty_inventory_core_attack_width
  + layout.empty_inventory_core_stat_width
  + layout.empty_inventory_core_action_width
  + ((layout.inventory_core_table_column_count - 1) * layout.inventory_core_table_spacing)
layout.empty_inventory_core_name_width = layout.empty_inventory_core_table_content_width - layout.empty_inventory_core_fixed_width
layout.empty_inventory_core_detail_width = layout.empty_inventory_core_name_width
layout.evolution_scroll_width = layout.evolution_column_width
layout.evolution_scroll_height = layout.evolution_outer_height - layout.evolution_header_height
layout.evolution_content_width = layout.evolution_scroll_width - 28
layout.evolution_section_margin = 6
layout.evolution_section_width = layout.evolution_content_width - (layout.evolution_section_margin * 2)
layout.evolution_inner_width = layout.evolution_section_width - 16
layout.evolution_card_inner_width = layout.evolution_inner_width - 28
layout.evolution_card_title_width = layout.evolution_card_inner_width
  - layout.evolution_card_icon_size
  - layout.evolution_card_action_width
  - 24
layout.evolution_card_title_full_width = layout.evolution_card_inner_width - layout.evolution_card_icon_size - 12
layout.evolution_effect_column_width = math.floor(
  (layout.evolution_card_inner_width - layout.evolution_effect_table_spacing) / 2
)
layout.evolution_detail_width = layout.evolution_inner_width - 96
layout.evolution_effect_width = layout.evolution_inner_width - 64
layout.rank_stepper_width = (layout.rank_stepper_button_size * 2)
  + layout.rank_stepper_label_width
  + (layout.rank_stepper_spacing * 2)
layout.rank_allocation_spacing_width = layout.rank_allocation_horizontal_spacing * 3
layout.rank_allocation_detail_width = layout.evolution_inner_width
  - layout.rank_allocation_icon_size
  - layout.rank_allocation_value_width
  - layout.rank_stepper_width
  - layout.rank_allocation_spacing_width
layout.element_mastery_icon_width = 36
layout.element_mastery_action_width = 96
layout.element_mastery_label_width = layout.evolution_inner_width
  - layout.element_mastery_icon_width
  - layout.element_mastery_action_width
  - 40

return {
  gui = gui,
  color = color,
  layout = layout,
}
