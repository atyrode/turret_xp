local CHIP_NAME = "turret-xp-veteran-core"
local FEEDER_NAME = "turret-xp-veteran-feeder"
local LABEL_PANEL_PREFIX = "turret-xp-label-panel-"
local RANGE_AUGMENT_MAX = 20
local LABEL_PRESETS = {
  { id = "gold", color = { 1, 0.86, 0.46, 1 } },
  { id = "white", color = { 1, 1, 1, 1 } },
  { id = "green", color = { 0.45, 1, 0.45, 1 } },
  { id = "blue", color = { 0.45, 0.78, 1, 1 } },
  { id = "red", color = { 1, 0.36, 0.30, 1 } },
  { id = "purple", color = { 0.86, 0.48, 1, 1 } }
}
local SPECIALIZATIONS = {
  sniper = {
    range_multiplier = 1.8889,
    cooldown_multiplier = 2.5,
    damage_multiplier = 2.8,
    health_multiplier = 0.875,
    rotation_speed_multiplier = 0.6667
  },
  machine_gun = {
    range_multiplier = 0.8889,
    cooldown_multiplier = 0.5,
    damage_multiplier = 0.58,
    health_multiplier = 0.9,
    rotation_speed_multiplier = 1.6667
  },
  bulwark = {
    range_multiplier = 0.9445,
    cooldown_multiplier = 1.3334,
    damage_multiplier = 0.65,
    health_multiplier = 3.0,
    rotation_speed_multiplier = 0.8
  },
  brawler = {
    range_multiplier = 0.3889,
    cooldown_multiplier = 1.3334,
    damage_multiplier = 4.0,
    health_multiplier = 1.625,
    rotation_speed_multiplier = 1.3334
  }
}

local function make_turret_variant(id, settings, range_bonus)
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
  variant.max_health = math.floor((variant.max_health or 1) * (settings.health_multiplier or 1) + 0.5)
  variant.rotation_speed = (variant.rotation_speed or 0) * (settings.rotation_speed_multiplier or 1)

  variant.attack_parameters = table.deepcopy(variant.attack_parameters)
  variant.attack_parameters.range = ((variant.attack_parameters.range or 0) + (range_bonus or 0)) * (settings.range_multiplier or 1)
  variant.attack_parameters.cooldown = (variant.attack_parameters.cooldown or 1) * (settings.cooldown_multiplier or 1)
  variant.attack_parameters.damage_modifier = (variant.attack_parameters.damage_modifier or 1) * (settings.damage_multiplier or 1)

  return variant
end

local variants = {}
local variant_names = {}
for range_bonus = 1, RANGE_AUGMENT_MAX do
  local variant = make_turret_variant("range-" .. tostring(range_bonus), {}, range_bonus)
  if variant then
    variants[#variants + 1] = variant
    variant_names[#variant_names + 1] = variant.name
  end
end

for id, settings in pairs(SPECIALIZATIONS) do
  for range_bonus = 0, RANGE_AUGMENT_MAX do
    local variant_id = id
    if range_bonus > 0 then
      variant_id = id .. "-range-" .. tostring(range_bonus)
    end
    local variant = make_turret_variant(variant_id, settings, range_bonus)
    if variant then
      variants[#variants + 1] = variant
      variant_names[#variant_names + 1] = variant.name
    end
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

local feeder = table.deepcopy(data.raw["container"]["iron-chest"])
feeder.name = FEEDER_NAME
feeder.localised_name = { "entity-name." .. FEEDER_NAME }
feeder.localised_description = { "entity-description." .. FEEDER_NAME }
feeder.hidden = true
feeder.hidden_in_factoriopedia = true
feeder.flags = { "placeable-neutral", "placeable-off-grid", "not-blueprintable", "not-deconstructable", "not-on-map" }
feeder.selectable_in_game = false
feeder.minable = nil
feeder.next_upgrade = nil
feeder.fast_replaceable_group = nil
feeder.max_health = 250
feeder.inventory_size = 1
feeder.inventory_type = "with_custom_stack_size"
feeder.inventory_properties = {
  stack_size_min = 1,
  stack_size_max = 1,
  with_bar = true
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
    tint = { 0.72, 0.86, 1.0 }
  },
  {
    icon = "__base__/graphics/icons/electronic-circuit.png",
    icon_size = 64,
    scale = 0.28,
    shift = { 8, -8 }
  }
}
feeder.picture = {
  filename = "__core__/graphics/empty.png",
  priority = "extra-high",
  width = 1,
  height = 1
}

data:extend({ feeder })

local label_panel_base = data.raw["display-panel"] and data.raw["display-panel"]["display-panel"]
if label_panel_base then
  local label_panels = {}
  for _, preset in ipairs(LABEL_PRESETS) do
    local panel = table.deepcopy(label_panel_base)
    panel.name = LABEL_PANEL_PREFIX .. preset.id
    panel.localised_name = { "entity-name." .. panel.name }
    panel.localised_description = { "entity-description.turret-xp-label-panel" }
    panel.hidden = true
    panel.hidden_in_factoriopedia = true
    panel.flags = { "placeable-off-grid", "not-blueprintable", "not-deconstructable", "not-on-map" }
    panel.selectable_in_game = false
    panel.minable = nil
    panel.collision_box = { { -0.05, -0.05 }, { 0.05, 0.05 } }
    panel.selection_box = { { -0.05, -0.05 }, { 0.05, 0.05 } }
    panel.collision_mask = { layers = {}, not_colliding_with_itself = true }
    panel.circuit_connector = nil
    panel.circuit_wire_max_distance = 0
    panel.draw_copper_wires = false
    panel.draw_circuit_wires = false
    panel.sprites = util.empty_sprite()
    panel.icon = "__core__/graphics/empty.png"
    panel.icon_size = 1
    panel.icons = nil
    panel.max_text_width = 360
    panel.text_shift = util.by_pixel(0, -62)
    panel.text_color = preset.color
    panel.background_color = { 0, 0, 0, 0.38 }
    label_panels[#label_panels + 1] = panel
  end
  data:extend(label_panels)
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
