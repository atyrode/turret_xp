local CHIP_NAME = "turret-xp-veteran-core"
local SPECIALIZATIONS = {
  sniper = {
    range = 34,
    cooldown = 15,
    damage_modifier = 2.8,
    max_health = 350,
    rotation_speed = 0.01
  },
  machine_gun = {
    range = 16,
    cooldown = 3,
    damage_modifier = 0.58,
    max_health = 360,
    rotation_speed = 0.025
  },
  bulwark = {
    range = 17,
    cooldown = 8,
    damage_modifier = 0.65,
    max_health = 1200,
    rotation_speed = 0.012
  },
  brawler = {
    range = 7,
    cooldown = 8,
    damage_modifier = 4.0,
    max_health = 650,
    rotation_speed = 0.02
  }
}

local function make_turret_variant(id, settings)
  local base = data.raw["ammo-turret"]["gun-turret"]
  if not base then
    return nil
  end

  local variant = table.deepcopy(base)
  variant.name = "turret-xp-gun-turret-" .. id
  variant.localised_name = { "entity-name.gun-turret" }
  variant.localised_description = { "entity-description.turret-xp-specialized-gun-turret" }
  variant.hidden = true
  variant.hidden_in_factoriopedia = true
  variant.placeable_by = { item = "gun-turret", count = 1 }
  variant.minable = { mining_time = 0.5, result = "gun-turret" }
  variant.max_health = settings.max_health or variant.max_health
  variant.rotation_speed = settings.rotation_speed or variant.rotation_speed

  variant.attack_parameters = table.deepcopy(variant.attack_parameters)
  variant.attack_parameters.range = settings.range or variant.attack_parameters.range
  variant.attack_parameters.cooldown = settings.cooldown or variant.attack_parameters.cooldown
  variant.attack_parameters.damage_modifier = settings.damage_modifier or variant.attack_parameters.damage_modifier or 1

  return variant
end

local variants = {}
local variant_names = {}
for id, settings in pairs(SPECIALIZATIONS) do
  local variant = make_turret_variant(id, settings)
  if variant then
    variants[#variants + 1] = variant
    variant_names[#variant_names + 1] = variant.name
  end
end

if #variants > 0 then
  data:extend(variants)
end

if #variant_names > 0 then
  for _, technology in pairs(data.raw.technology) do
    for _, effect in ipairs(technology.effects or {}) do
      if effect.type == "turret-attack" and effect.turret_id == "gun-turret" then
        for _, variant_name in ipairs(variant_names) do
          local copied = table.deepcopy(effect)
          copied.turret_id = variant_name
          technology.effects[#technology.effects + 1] = copied
        end
      end
    end
  end
end

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
