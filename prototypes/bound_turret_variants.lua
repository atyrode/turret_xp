local RANGE_AUGMENT_MAX = 20
local SPECIALIZATIONS = {
  "sniper",
  "machine_gun",
  "bulwark",
  "brawler"
}

local SUB_SPECIALIZATIONS = {
  { id = "sniper_deadeye", parent = "sniper" },
  { id = "sniper_overwatch", parent = "sniper" },
  { id = "machine_shredder", parent = "machine_gun" },
  { id = "machine_sustained", parent = "machine_gun" },
  { id = "bulwark_bastion", parent = "bulwark" },
  { id = "bulwark_guardian", parent = "bulwark" },
  { id = "brawler_executioner", parent = "brawler" },
  { id = "brawler_vampire", parent = "brawler" }
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

local function make_variant_id(specialization_id, range_rank, sub_specialization_id)
  local segments = {}
  if specialization_id then
    segments[#segments + 1] = specialization_id
  end
  local sub_segment = sub_specialization_segment(sub_specialization_id, specialization_id)
  if sub_segment then
    segments[#segments + 1] = sub_segment
  end
  if range_rank > 0 then
    segments[#segments + 1] = "range-" .. tostring(range_rank)
  end

  if #segments == 0 then
    return nil
  end

  return table.concat(segments, "-")
end

local function turret_variant_name(variant_id)
  if not variant_id then
    return "gun-turret"
  end

  return "turret-xp-gun-turret-" .. variant_id
end

local function bound_item_name(variant_id)
  if not variant_id then
    return "turret-xp-bound-gun-turret"
  end

  return "turret-xp-bound-gun-turret-" .. variant_id
end

local function placeholder_name(variant_id)
  if not variant_id then
    return "turret-xp-bound-gun-turret-placeholder"
  end

  return "turret-xp-bound-gun-turret-placeholder-" .. variant_id
end

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
  item.name = bound_item_name(variant_id)
  item.localised_name = { "item-name.turret-xp-bound-gun-turret" }
  item.localised_description = { "item-description.turret-xp-bound-gun-turret" }
  item.place_result = placeholder_name(variant_id)
  item.hidden = true
  item.hidden_in_factoriopedia = true
  return item
end

local function make_placeholder_variant(base_placeholder, variant_id, source)
  local placeholder = table.deepcopy(base_placeholder)
  placeholder.name = placeholder_name(variant_id)
  placeholder.localised_name = { "entity-name.turret-xp-bound-gun-turret-placeholder" }
  placeholder.localised_description = { "entity-description.turret-xp-bound-gun-turret-placeholder" }
  placeholder.placeable_by = { item = bound_item_name(variant_id), count = 1 }
  placeholder.minable = { mining_time = 0.5, result = bound_item_name(variant_id) }
  apply_preview_stats(placeholder, source)
  return placeholder
end

return function()
  local base_item = data.raw["item-with-tags"] and data.raw["item-with-tags"]["turret-xp-bound-gun-turret"]
  local base_placeholder = data.raw["ammo-turret"] and data.raw["ammo-turret"]["turret-xp-bound-gun-turret-placeholder"]
  local base_turret = data.raw["ammo-turret"] and data.raw["ammo-turret"]["gun-turret"]
  if not base_item or not base_placeholder or not base_turret then
    return
  end

  apply_preview_stats(base_placeholder, base_turret)

  local prototypes = {}
  for range_rank = 1, RANGE_AUGMENT_MAX do
    local variant_id = make_variant_id(nil, range_rank)
    local source = data.raw["ammo-turret"][turret_variant_name(variant_id)]
    if source then
      prototypes[#prototypes + 1] = make_item_variant(base_item, variant_id)
      prototypes[#prototypes + 1] = make_placeholder_variant(base_placeholder, variant_id, source)
    end
  end

  for _, specialization_id in ipairs(SPECIALIZATIONS) do
    for range_rank = 0, RANGE_AUGMENT_MAX do
      local variant_id = make_variant_id(specialization_id, range_rank)
      local source = data.raw["ammo-turret"][turret_variant_name(variant_id)]
      if source then
        prototypes[#prototypes + 1] = make_item_variant(base_item, variant_id)
        prototypes[#prototypes + 1] = make_placeholder_variant(base_placeholder, variant_id, source)
      end
    end
  end

  for _, sub_specialization in ipairs(SUB_SPECIALIZATIONS) do
    for range_rank = 0, RANGE_AUGMENT_MAX do
      local variant_id = make_variant_id(sub_specialization.parent, range_rank, sub_specialization.id)
      local source = data.raw["ammo-turret"][turret_variant_name(variant_id)]
      if source then
        prototypes[#prototypes + 1] = make_item_variant(base_item, variant_id)
        prototypes[#prototypes + 1] = make_placeholder_variant(base_placeholder, variant_id, source)
      end
    end
  end

  if #prototypes > 0 then
    data:extend(prototypes)
  end
end
