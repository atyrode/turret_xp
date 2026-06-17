return function()
  local styles = data.raw["gui-style"]["default"]

  styles.turret_xp_xp_progressbar = {
    type = "progressbar_style",
    parent = "health_progressbar",
    horizontally_stretchable = "on",
    color = { 0.98, 0.72, 0.24 },
    height = 18,
    bar_width = 16,
    embed_text_in_bar = false,
  }

  styles.turret_xp_ammo_productivity_progressbar = {
    type = "progressbar_style",
    parent = "health_progressbar",
    horizontally_stretchable = "on",
    color = { 0.72, 0.33, 0.95 },
    height = 10,
    bar_width = 8,
    embed_text_in_bar = false,
  }

  styles.turret_xp_inventory_core_table_header_row = {
    type = "horizontal_flow_style",
    horizontally_stretchable = "on",
    horizontal_spacing = 0,
    vertical_align = "center",
    top_padding = 0,
    right_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
  }

  styles.turret_xp_inventory_core_table_body = {
    type = "vertical_flow_style",
    horizontally_stretchable = "on",
    vertical_spacing = 0,
    top_padding = 0,
    right_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
  }

  styles.turret_xp_inventory_core_table_row_even = {
    type = "frame_style",
    parent = "frame",
    horizontally_stretchable = "on",
    graphical_set = {},
    horizontal_flow_style = {
      type = "horizontal_flow_style",
      horizontal_spacing = 0,
      vertical_align = "center",
    },
    top_padding = 0,
    right_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
  }

  styles.turret_xp_inventory_core_table_row_odd = {
    type = "frame_style",
    parent = "turret_xp_inventory_core_table_row_even",
    graphical_set = {
      base = {
        center = {
          filename = "__core__/graphics/gui-new.png",
          position = { 472, 25 },
          size = 1,
        },
      },
    },
  }

  styles.turret_xp_inventory_core_table_cell = {
    type = "horizontal_flow_style",
    left_padding = 4,
    right_padding = 4,
    top_padding = 0,
    bottom_padding = 0,
    horizontal_spacing = 0,
    vertical_align = "center",
  }

  styles.turret_xp_inventory_core_table_action_cell = {
    type = "horizontal_flow_style",
    parent = "turret_xp_inventory_core_table_cell",
    horizontal_align = "center",
  }

  styles.turret_xp_inventory_core_table_header_cell = {
    type = "horizontal_flow_style",
    parent = "turret_xp_inventory_core_table_cell",
  }

  styles.turret_xp_inventory_core_table_header_divider = {
    type = "empty_widget_style",
    height = 1,
    graphical_set = {
      base = {
        center = {
          filename = "__core__/graphics/gui-new.png",
          position = { 76, 8 },
          size = { 1, 1 },
        },
      },
    },
  }

  styles.turret_xp_table_header_button = {
    type = "button_style",
    parent = "transparent_button",
    font = "default-bold",
    default_font_color = { 0.62, 0.62, 0.62 },
    hovered_font_color = { 1, 1, 1 },
    clicked_font_color = { 1, 1, 1 },
    disabled_font_color = { 0.62, 0.62, 0.62 },
    default_graphical_set = {},
    hovered_graphical_set = {},
    clicked_graphical_set = {},
    disabled_graphical_set = {},
    left_padding = 0,
    right_padding = 0,
    top_padding = 0,
    bottom_padding = 0,
    clicked_vertical_offset = 0,
  }
end
