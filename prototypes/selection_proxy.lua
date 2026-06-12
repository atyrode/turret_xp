return function(names)
  local function read_base_selection_box()
    local base = data.raw["ammo-turret"] and data.raw["ammo-turret"]["gun-turret"]
    local box = base and base.selection_box or nil
    if not box or not box[1] or not box[2] then
      return { { -0.55, -0.55 }, { 0.55, 0.55 } }
    end

    return table.deepcopy(box)
  end

  local function expanded_selection_box()
    local box = read_base_selection_box()
    return {
      {
        math.min((box[1][1] or -0.55) - 0.35, -0.9),
        math.min((box[1][2] or -0.55) - 0.75, -1.3),
      },
      {
        math.max((box[2][1] or 0.55) + 0.35, 0.9),
        math.max((box[2][2] or 0.55) + 0.35, 0.9),
      },
    }
  end

  local selection_box = expanded_selection_box()
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
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
    selection_box = selection_box,
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
