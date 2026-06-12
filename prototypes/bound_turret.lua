return function(names)
  local base = data.raw["ammo-turret"] and data.raw["ammo-turret"]["gun-turret"]
  if not base then
    return
  end

  local placeholder = table.deepcopy(base)
  placeholder.name = names.bound_turret_placeholder
  placeholder.localised_name = { "entity-name." .. names.bound_turret_placeholder }
  placeholder.localised_description = { "entity-description." .. names.bound_turret_placeholder }
  placeholder.hidden = true
  placeholder.hidden_in_factoriopedia = true
  placeholder.next_upgrade = nil
  placeholder.fast_replaceable_group = nil
  placeholder.placeable_by = { item = names.bound_turret, count = 1 }
  placeholder.minable = { mining_time = 0.5, result = names.bound_turret }
  placeholder.icons = {
    {
      icon = "__base__/graphics/icons/gun-turret.png",
      icon_size = 64,
      scale = 0.5,
    },
    {
      icon = "__base__/graphics/icons/electronic-circuit.png",
      icon_size = 64,
      scale = 0.22,
      shift = { 9, -9 },
    },
  }
  placeholder.icon = nil

  data:extend({ placeholder })
end
