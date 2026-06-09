return function(names)
  data:extend({
    {
      type = "item-with-tags",
      name = names.chip,
      localised_name = { "item-name." .. names.chip },
      localised_description = { "item-description." .. names.chip },
      icons = {
        {
          icon = "__base__/graphics/icons/electronic-circuit.png",
          icon_size = 64,
          scale = 0.5
        },
        {
          icon = "__base__/graphics/icons/gun-turret.png",
          icon_size = 64,
          scale = 0.26,
          shift = { 8, -8 }
        }
      },
      subgroup = "defensive-structure",
      order = "b[turret]-a[gun-turret]-b[veteran-core]",
      stack_size = 1,
      weight = 20 * kg
    },
    {
      type = "item-with-tags",
      name = names.bound_turret,
      localised_name = { "item-name." .. names.bound_turret },
      localised_description = { "item-description." .. names.bound_turret },
      icons = {
        {
          icon = "__base__/graphics/icons/gun-turret.png",
          icon_size = 64,
          scale = 0.5
        },
        {
          icon = "__base__/graphics/icons/electronic-circuit.png",
          icon_size = 64,
          scale = 0.22,
          shift = { 9, -9 }
        }
      },
      flags = { "not-stackable" },
      subgroup = "defensive-structure",
      order = "b[turret]-a[gun-turret]-c[bound-veteran]",
      place_result = names.bound_turret_placeholder,
      stack_size = 1,
      weight = 120 * kg
    },
    {
      type = "recipe",
      name = names.chip,
      localised_name = { "recipe-name." .. names.chip },
      enabled = false,
      ingredients = {
        { type = "item", name = "electronic-circuit", amount = 20 },
        { type = "item", name = "steel-plate", amount = 10 },
        { type = "item", name = "copper-cable", amount = 40 },
        { type = "item", name = "repair-pack", amount = 2 }
      },
      results = {
        { type = "item", name = names.chip, amount = 1 }
      },
      energy_required = 5
    }
  })

  local military = data.raw.technology["military"]
  if military then
    military.effects = military.effects or {}
    military.effects[#military.effects + 1] = {
      type = "unlock-recipe",
      recipe = names.chip
    }
  end
end
