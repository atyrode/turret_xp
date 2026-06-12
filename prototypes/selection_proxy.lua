return function(names)
  local proxy = {
    type = "arrow",
    name = names.selection_proxy,
    localised_name = { "entity-name." .. names.selection_proxy },
    localised_description = { "entity-description." .. names.selection_proxy },
    hidden = true,
    hidden_in_factoriopedia = true,
    flags = { "placeable-off-grid", "not-blueprintable", "not-deconstructable", "not-on-map" },
    selectable_in_game = true,
    selection_priority = 255,
    allow_copy_paste = false,
    minable = nil,
    collision_box = { { -0.49, -0.49 }, { 0.49, 0.49 } },
    selection_box = { { -0.55, -0.55 }, { 0.55, 0.55 } },
    collision_mask = { layers = {}, not_colliding_with_itself = true },
    arrow_picture = util.empty_sprite(),
    circle_picture = util.empty_sprite(),
    blinking = false,
    map_color = { 0, 0, 0, 0 },
    friendly_map_color = { 0, 0, 0, 0 },
    enemy_map_color = { 0, 0, 0, 0 },
  }

  proxy.icon = "__core__/graphics/empty.png"
  proxy.icon_size = 1

  data:extend({ proxy })
end
