local domain = require("scripts.domain")

local function apply_preview_stats(placeholder, source)
  if not placeholder or not source then
    return
  end

  placeholder.attack_parameters = table.deepcopy(source.attack_parameters or placeholder.attack_parameters)
  placeholder.rotation_speed = source.rotation_speed or placeholder.rotation_speed
  placeholder.call_for_help_radius = source.call_for_help_radius or placeholder.call_for_help_radius
end

local function make_item_variant(base_item, variant_id)
  local item = table.deepcopy(base_item)
  item.name = domain.bound_turret_item_name(variant_id)
  item.localised_name = { "item-name.turret-xp-bound-gun-turret" }
  item.localised_description = { "item-description.turret-xp-bound-gun-turret" }
  item.place_result = domain.bound_turret_placeholder_name(variant_id)
  item.hidden = true
  item.hidden_in_factoriopedia = true
  return item
end

local function make_placeholder_variant(base_placeholder, variant_id, source)
  local placeholder = table.deepcopy(base_placeholder)
  placeholder.name = domain.bound_turret_placeholder_name(variant_id)
  placeholder.localised_name = { "entity-name.turret-xp-bound-gun-turret-placeholder" }
  placeholder.localised_description = { "entity-description.turret-xp-bound-gun-turret-placeholder" }
  placeholder.placeable_by = { item = domain.bound_turret_item_name(variant_id), count = 1 }
  placeholder.minable = { mining_time = 0.5, result = domain.bound_turret_item_name(variant_id) }
  apply_preview_stats(placeholder, source)
  return placeholder
end

return function()
  local base_item = data.raw["item-with-tags"] and data.raw["item-with-tags"][domain.names.bound_turret]
  local base_placeholder = data.raw["ammo-turret"] and data.raw["ammo-turret"][domain.names.bound_turret_placeholder]
  local base_turret = data.raw["ammo-turret"] and data.raw["ammo-turret"][domain.names.base_turret]
  if not base_item or not base_placeholder or not base_turret then
    return
  end

  apply_preview_stats(base_placeholder, base_turret)

  local prototypes = {}
  domain.for_each_bound_turret_variant(function(variant_id, specialization_id, range_rank, sub_specialization_id)
    local source_name = domain.specialized_turret_name(specialization_id, range_rank, 0, sub_specialization_id)
    local source = data.raw["ammo-turret"][source_name]
    if source then
      prototypes[#prototypes + 1] = make_item_variant(base_item, variant_id)
      prototypes[#prototypes + 1] = make_placeholder_variant(base_placeholder, variant_id, source)
    end
  end)

  if #prototypes > 0 then
    data:extend(prototypes)
  end
end
