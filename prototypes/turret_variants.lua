local RANGE_AUGMENT_MAX = 20
local MAX_HEALTH_AUGMENT_MAX = 20
local MAX_HEALTH_PER_RANK = 50
local SPECIALIZATIONS = {
  sniper = {
    range_multiplier = 1.8889,
    cooldown_multiplier = 4.0,
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
    cooldown_multiplier = 2.0,
    damage_multiplier = 3.0,
    health_multiplier = 1.625,
    rotation_speed_multiplier = 1.3334
  }
}

local SUB_SPECIALIZATIONS = {
  sniper_deadeye = {
    parent = "sniper",
    damage_multiplier = 1.08
  },
  sniper_overwatch = {
    parent = "sniper",
    range_multiplier = 1.18,
    cooldown_multiplier = 1.15,
    damage_multiplier = 1.08
  },
  machine_shredder = {
    parent = "machine_gun",
    damage_multiplier = 0.92
  },
  machine_sustained = {
    parent = "machine_gun",
    cooldown_multiplier = 0.85
  },
  bulwark_bastion = {
    parent = "bulwark",
    health_multiplier = 1.35,
    cooldown_multiplier = 1.10
  },
  bulwark_guardian = {
    parent = "bulwark",
    range_multiplier = 1.08
  },
  brawler_executioner = {
    parent = "brawler",
    damage_multiplier = 1.35
  },
  brawler_vampire = {
    parent = "brawler",
    health_multiplier = 1.18,
    damage_multiplier = 0.90
  }
}

local function sub_specialization_segment(sub_specialization_id, specialization_id)
  if not sub_specialization_id then
    return nil
  end

  local prefix = tostring(specialization_id or "") .. "_"
  if string.sub(sub_specialization_id, 1, #prefix) == prefix then
    return string.sub(sub_specialization_id, #prefix + 1)
  end

  return sub_specialization_id
end

local function make_variant_id(specialization_id, range_bonus, health_rank, sub_specialization_id)
  local segments = {}
  if specialization_id then
    segments[#segments + 1] = specialization_id
  end
  local sub_segment = sub_specialization_segment(sub_specialization_id, specialization_id)
  if sub_segment then
    segments[#segments + 1] = sub_segment
  end
  if range_bonus > 0 then
    segments[#segments + 1] = "range-" .. tostring(range_bonus)
  end
  if health_rank > 0 then
    segments[#segments + 1] = "health-" .. tostring(health_rank)
  end

  if #segments == 0 then
    return nil
  end

  return table.concat(segments, "-")
end

local function combine_settings(primary, secondary)
  local settings = {}
  for key, value in pairs(primary or {}) do
    settings[key] = value
  end

  for _, key in ipairs({
    "range_multiplier",
    "cooldown_multiplier",
    "damage_multiplier",
    "health_multiplier",
    "rotation_speed_multiplier"
  }) do
    local value = secondary and secondary[key] or nil
    if value ~= nil then
      settings[key] = (settings[key] or 1) * value
    end
  end

  return settings
end

local function make_turret_variant(id, settings, range_bonus, health_rank)
  local base = data.raw["ammo-turret"] and data.raw["ammo-turret"]["gun-turret"]
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
  local health_bonus = (math.max(0, health_rank or 0) * MAX_HEALTH_PER_RANK)
  variant.max_health = math.floor(((variant.max_health or 1) + health_bonus) * (settings.health_multiplier or 1) + 0.5)
  variant.rotation_speed = (variant.rotation_speed or 0) * (settings.rotation_speed_multiplier or 1)

  variant.attack_parameters = table.deepcopy(variant.attack_parameters or {})
  variant.attack_parameters.range = ((variant.attack_parameters.range or 0) + (range_bonus or 0)) * (settings.range_multiplier or 1)
  variant.attack_parameters.cooldown = (variant.attack_parameters.cooldown or 1) * (settings.cooldown_multiplier or 1)
  variant.attack_parameters.damage_modifier = (variant.attack_parameters.damage_modifier or 1) * (settings.damage_multiplier or 1)

  return variant
end

return function()
  local variants = {}
  for range_bonus = 0, RANGE_AUGMENT_MAX do
    for health_rank = 0, MAX_HEALTH_AUGMENT_MAX do
      local variant_id = make_variant_id(nil, range_bonus, health_rank)
      if variant_id then
        local variant = make_turret_variant(variant_id, {}, range_bonus, health_rank)
        if variant then
          variants[#variants + 1] = variant
        end
      end
    end
  end

  for id, settings in pairs(SPECIALIZATIONS) do
    for range_bonus = 0, RANGE_AUGMENT_MAX do
      for health_rank = 0, MAX_HEALTH_AUGMENT_MAX do
        local variant_id = make_variant_id(id, range_bonus, health_rank)
        local variant = make_turret_variant(variant_id, settings, range_bonus, health_rank)
        if variant then
          variants[#variants + 1] = variant
        end
      end
    end
  end

  for sub_id, sub_settings in pairs(SUB_SPECIALIZATIONS) do
    local specialization_id = sub_settings.parent
    local primary_settings = SPECIALIZATIONS[specialization_id]
    if primary_settings then
      local settings = combine_settings(primary_settings, sub_settings)
      for range_bonus = 0, RANGE_AUGMENT_MAX do
        for health_rank = 0, MAX_HEALTH_AUGMENT_MAX do
          local variant_id = make_variant_id(specialization_id, range_bonus, health_rank, sub_id)
          local variant = make_turret_variant(variant_id, settings, range_bonus, health_rank)
          if variant then
            variants[#variants + 1] = variant
          end
        end
      end
    end
  end

  if #variants > 0 then
    data:extend(variants)
  end
end
