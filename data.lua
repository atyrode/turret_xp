local styles = data.raw["gui-style"]["default"]
local MOD_PREFIX = "turret-xp-"

styles.turret_xp_xp_progressbar = {
  type = "progressbar_style",
  parent = "health_progressbar",
  horizontally_stretchable = "on",
  color = { 0.98, 0.72, 0.24 },
  height = 18,
  bar_width = 16,
  embed_text_in_bar = false
}

data:extend({
  {
    type = "custom-input",
    name = MOD_PREFIX .. "skill-tree-drag-start",
    key_sequence = "",
    linked_game_control = "open-gui",
    consuming = "none",
    action = "lua"
  }
})
