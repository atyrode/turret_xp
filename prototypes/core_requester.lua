return function(names)
  local base = data.raw["logistic-container"] and data.raw["logistic-container"]["requester-chest"]
  if not base then
    return
  end

  local requester = table.deepcopy(base)
  requester.name = names.core_requester
  requester.localised_name = { "entity-name." .. names.core_requester }
  requester.localised_description = { "entity-description." .. names.core_requester }
  requester.hidden = true
  requester.hidden_in_factoriopedia = true
  requester.flags = { "placeable-neutral", "placeable-off-grid", "not-blueprintable", "not-deconstructable", "not-on-map" }
  requester.selectable_in_game = false
  requester.minable = nil
  requester.next_upgrade = nil
  requester.fast_replaceable_group = nil
  requester.max_health = 250
  requester.inventory_size = 1
  requester.inventory_type = "with_custom_stack_size"
  requester.inventory_properties = {
    stack_size_min = 1,
    stack_size_max = 1,
    with_bar = true,
  }
  requester.collision_box = { { -0.35, -0.35 }, { 0.35, 0.35 } }
  requester.selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } }
  requester.collision_mask = { layers = {}, not_colliding_with_itself = true }
  requester.drawing_box_vertical_extension = 0
  requester.icon = "__base__/graphics/icons/requester-chest.png"
  requester.icons = {
    {
      icon = "__base__/graphics/icons/requester-chest.png",
      icon_size = 64,
      tint = { 0.72, 0.86, 1.0 },
    },
    {
      icon = "__base__/graphics/icons/electronic-circuit.png",
      icon_size = 64,
      scale = 0.28,
      shift = { 8, -8 },
    },
  }
  requester.picture = {
    filename = "__core__/graphics/empty.png",
    priority = "extra-high",
    width = 1,
    height = 1,
  }

  data:extend({ requester })
end
