local CHIP_NAME = "turret-xp-veteran-core"

data:extend({
  {
    type = "item-with-tags",
    name = CHIP_NAME,
    localised_name = { "item-name." .. CHIP_NAME },
    localised_description = { "item-description." .. CHIP_NAME },
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
    type = "recipe",
    name = CHIP_NAME,
    localised_name = { "recipe-name." .. CHIP_NAME },
    enabled = false,
    ingredients = {
      { type = "item", name = "electronic-circuit", amount = 20 },
      { type = "item", name = "steel-plate", amount = 10 },
      { type = "item", name = "copper-cable", amount = 40 },
      { type = "item", name = "repair-pack", amount = 2 }
    },
    results = {
      { type = "item", name = CHIP_NAME, amount = 1 }
    },
    energy_required = 5
  }
})

local military = data.raw.technology["military"]
if military then
  military.effects = military.effects or {}
  military.effects[#military.effects + 1] = {
    type = "unlock-recipe",
    recipe = CHIP_NAME
  }
end

local styles = data.raw["gui-style"]["default"]

styles.turret_xp_xp_progressbar = {
  type = "progressbar_style",
  parent = "health_progressbar",
  horizontally_stretchable = "on",
  color = { 0.98, 0.72, 0.24 },
  height = 18,
  bar_width = 16,
  embed_text_in_bar = false
}
