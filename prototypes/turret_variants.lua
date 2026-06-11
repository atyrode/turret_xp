local domain = require("scripts.domain")

local function make_turret_variant(id, settings, range_bonus, health_rank)
  local base = data.raw["ammo-turret"] and data.raw["ammo-turret"]["gun-turret"]
  if not base then
    return nil
  end

  local variant = table.deepcopy(base)
  variant.name = domain.names.specialized_turret_prefix .. id
  variant.localised_name = { "entity-name.gun-turret" }
  variant.localised_description = { "entity-description.turret-xp-specialized-gun-turret" }
  variant.hidden = true
  variant.hidden_in_factoriopedia = true
  variant.placeable_by = { item = "gun-turret", count = 1 }
  variant.minable = { mining_time = 0.5, result = "gun-turret" }
  local health_bonus = (math.max(0, health_rank or 0) * domain.max_health_per_rank)
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
  for range_bonus = 0, domain.range_augment_max do
    for health_rank = 0, domain.max_health_augment_max do
      local variant_id = domain.specialized_turret_variant_id(nil, range_bonus, health_rank)
      if variant_id then
        local variant = make_turret_variant(variant_id, {}, range_bonus, health_rank)
        if variant then
          variants[#variants + 1] = variant
        end
      end
    end
  end

  for _, specialization in ipairs(domain.specializations) do
    for range_bonus = 0, domain.range_augment_max do
      for health_rank = 0, domain.max_health_augment_max do
        local variant_id = domain.specialized_turret_variant_id(specialization.id, range_bonus, health_rank)
        local variant = make_turret_variant(variant_id, specialization, range_bonus, health_rank)
        if variant then
          variants[#variants + 1] = variant
        end
      end
    end
  end

  for _, sub_settings in ipairs(domain.sub_specializations) do
    local specialization_id = sub_settings.parent
    local primary_settings = domain.specialization_by_id[specialization_id]
    if primary_settings then
      local settings = domain.combine_variant_settings(primary_settings, sub_settings)
      for range_bonus = 0, domain.range_augment_max do
        for health_rank = 0, domain.max_health_augment_max do
          local variant_id = domain.specialized_turret_variant_id(specialization_id, range_bonus, health_rank, sub_settings.id)
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
