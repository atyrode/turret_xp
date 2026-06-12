return function(names)
  local feeder = table.deepcopy(data.raw["container"]["iron-chest"])
  feeder.name = names.feeder
  feeder.localised_name = { "entity-name." .. names.feeder }
  feeder.localised_description = { "entity-description." .. names.feeder }
  feeder.hidden = true
  feeder.hidden_in_factoriopedia = true
  feeder.flags = { "placeable-neutral", "placeable-off-grid", "not-blueprintable", "not-deconstructable", "not-on-map" }
  feeder.selectable_in_game = false
  feeder.minable = nil
  feeder.next_upgrade = nil
  feeder.fast_replaceable_group = nil
  feeder.max_health = 250
  feeder.inventory_size = 100
  feeder.inventory_type = "with_custom_stack_size"
  feeder.inventory_properties = {
    stack_size_min = 1,
    stack_size_max = 1,
    with_bar = true,
  }
  feeder.collision_box = { { -0.35, -0.35 }, { 0.35, 0.35 } }
  feeder.selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } }
  feeder.collision_mask = { layers = {}, not_colliding_with_itself = true }
  feeder.drawing_box_vertical_extension = 0
  feeder.icon = "__base__/graphics/icons/iron-chest.png"
  feeder.icons = {
    {
      icon = "__base__/graphics/icons/iron-chest.png",
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
  feeder.picture = {
    filename = "__core__/graphics/empty.png",
    priority = "extra-high",
    width = 1,
    height = 1,
  }

  data:extend({ feeder })
end
