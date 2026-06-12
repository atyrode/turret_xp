local domain = require("scripts.domain")
local label_colors = require("scripts.control.label_colors")

local prefix = domain.names.mod_prefix

local gui = {
  panel = prefix .. "panel",
  core = prefix .. "core",
  core_slot = prefix .. "core-slot",
  core_status = prefix .. "core-status",
  core_actions = prefix .. "core-actions",
  core_name = prefix .. "core-name",
  core_name_visible = prefix .. "core-name-visible",
  core_name_level_visible = prefix .. "core-name-level-visible",
  core_color_preview = prefix .. "core-color-preview",
  core_color_r = prefix .. "core-color-r",
  core_color_g = prefix .. "core-color-g",
  core_color_b = prefix .. "core-color-b",
  core_color_r_value = prefix .. "core-color-r-value",
  core_color_g_value = prefix .. "core-color-g-value",
  core_color_b_value = prefix .. "core-color-b-value",
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
  bonus = { 0.55, 0.82, 0.55 },
  penalty = { 0.95, 0.50, 0.48 },
  label_presets = label_colors.presets,
}

local layout = {
  column_spacing = 8,
  left_column_width = 380,
  evolution_column_width = 430,
  evolution_outer_height = 760,
  evolution_header_height = 36,
  stats_height = 360,
  stats_value_width = 190,
}

layout.panel_width = layout.left_column_width + layout.evolution_column_width + layout.column_spacing
layout.panel_max_width = layout.panel_width + 24
layout.stats_scroll_width = layout.left_column_width - 16
layout.stats_content_width = layout.stats_scroll_width - 30
layout.evolution_scroll_width = layout.evolution_column_width
layout.evolution_scroll_height = layout.evolution_outer_height - layout.evolution_header_height
layout.evolution_content_width = layout.evolution_scroll_width - 28
layout.evolution_section_margin = 6
layout.evolution_section_width = layout.evolution_content_width - (layout.evolution_section_margin * 2)
layout.evolution_inner_width = layout.evolution_section_width - 16
layout.evolution_card_inner_width = layout.evolution_inner_width - 28
layout.evolution_detail_width = layout.evolution_inner_width - 96
layout.evolution_effect_width = layout.evolution_inner_width - 64
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
