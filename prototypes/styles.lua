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

  styles.turret_xp_inventory_core_table = {
    type = "table_style",
    parent = "table_with_selection",
    horizontally_stretchable = "on",
    vertical_spacing = 0,
    horizontal_spacing = 8,
    odd_row_graphical_set = {
      filename = "__core__/graphics/gui-new.png",
      position = { 472, 25 },
      size = 1,
    },
  }
end
