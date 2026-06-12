local domain = {}

local function index_by_id(list)
  local indexed = {}
  for _, entry in ipairs(list) do
    indexed[entry.id] = entry
  end
  return indexed
end

local function group_by_parent(list)
  local grouped = {}
  for _, entry in ipairs(list) do
    grouped[entry.parent] = grouped[entry.parent] or {}
    grouped[entry.parent][#grouped[entry.parent] + 1] = entry
  end
  return grouped
end

domain.names = {
  mod_prefix = "turret-xp-",
  chip = "turret-xp-veteran-core",
  bound_turret = "turret-xp-bound-gun-turret",
  bound_turret_placeholder = "turret-xp-bound-gun-turret-placeholder",
  feeder = "turret-xp-veteran-feeder",
  label_panel_prefix = "turret-xp-label-panel-",
  profile_tag = "turret_xp_profile",
  bound_turret_tag = "turret_xp_bound_turret",
  base_turret = "gun-turret",
  specialized_turret_prefix = "turret-xp-gun-turret-",
}
domain.names.bound_turret_variant_prefix = domain.names.bound_turret .. "-"
domain.names.bound_turret_placeholder_variant_prefix = domain.names.bound_turret_placeholder .. "-"

domain.gates = {
  specialization = 10,
  first_element = 20,
  augments = 30,
  sub_specialization = 40,
  second_element = 50,
}

domain.range_augment_max = 20
domain.max_health_augment_max = 20
domain.max_health_per_rank = 50
domain.element_free_rank = 1
domain.label_custom_color_steps = 5

domain.elements = {
  {
    id = "explosive",
    sprite = "virtual-signal/signal-explosion",
    name = "Explosive",
    description = "Shots can splash explosion damage around the target.",
    resource = "grenade",
    base_requirement = 500,
  },
  {
    id = "fire",
    sprite = "virtual-signal/signal-fire",
    name = "Fire",
    description = "Shots can add fire damage and power incendiary combos.",
    resource = "sulfur",
    base_requirement = 2500,
  },
  {
    id = "electric",
    sprite = "virtual-signal/signal-lightning",
    name = "Electric",
    description = "Shots can arc electric damage to a nearby enemy.",
    resource = "battery",
    base_requirement = 750,
  },
  {
    id = "toxic",
    sprite = "item/poison-capsule",
    name = "Toxic",
    description = "Shots can stack poison damage over time and slow targets.",
    resource = "poison-capsule",
    base_requirement = 150,
  },
}
domain.element_by_id = index_by_id(domain.elements)

domain.specializations = {
  {
    id = "sniper",
    sprite = "entity/radar",
    name = "Sniper",
    range_multiplier = 1.8889,
    cooldown_multiplier = 4.0,
    damage_multiplier = 2.8,
    health_multiplier = 0.875,
    rotation_speed_multiplier = 0.6667,
    crit_damage_multiplier = 1.8,
    value = "x1.89 range, x2.8 damage, x0.25 fire rate, x1.8 crit damage, x0.88 HP",
    description = "Very high range and shot damage, stronger critical hits, extremely slow fire rate, lower durability.",
  },
  {
    id = "machine_gun",
    sprite = "item/submachine-gun",
    name = "Machine gun",
    range_multiplier = 0.8889,
    cooldown_multiplier = 0.5,
    damage_multiplier = 0.58,
    health_multiplier = 0.9,
    rotation_speed_multiplier = 1.6667,
    ammo_recovery_multiplier = 2.0,
    value = "x2 fire rate, x2 ammo recovery, x0.58 damage, x0.89 range, x0.9 HP",
    description = "Much faster fire rate and ammo recovery, slightly shorter range, lower shot damage.",
  },
  {
    id = "bulwark",
    sprite = "item/stone-wall",
    name = "Bulwark",
    range_multiplier = 0.9445,
    cooldown_multiplier = 1.3334,
    damage_multiplier = 0.65,
    health_multiplier = 3.0,
    rotation_speed_multiplier = 0.8,
    repair_multiplier = 2.5,
    value = "x3 HP, x2.5 regeneration, x0.65 damage, x0.75 fire rate",
    description = "Triple durability and stronger regeneration, lower shot damage, slightly shorter range.",
  },
  {
    id = "brawler",
    sprite = "item/shotgun",
    name = "Brawler",
    range_multiplier = 0.3889,
    cooldown_multiplier = 2.0,
    damage_multiplier = 3.0,
    health_multiplier = 1.625,
    rotation_speed_multiplier = 1.3334,
    lifesteal_multiplier = 2.5,
    value = "x3 damage, x2.5 lifesteal, x0.5 fire rate, x0.39 range, x1.63 HP",
    description = "Very short range, high shot damage, stronger lifesteal and durability, slower fire rate.",
  },
}
domain.specialization_by_id = index_by_id(domain.specializations)

domain.sub_specializations = {
  {
    id = "sniper_deadeye",
    parent = "sniper",
    sprite = "item/piercing-rounds-magazine",
    name = "Deadeye",
    crit_chance_flat = 0.08,
    crit_damage_multiplier = 1.25,
    damage_multiplier = 1.08,
    value = "+8% crit chance, x1.25 crit damage, x1.08 damage",
    description = "Turns Sniper into a precision killer that leans harder into critical shots.",
  },
  {
    id = "sniper_overwatch",
    parent = "sniper",
    sprite = "entity/radar",
    name = "Overwatch",
    range_multiplier = 1.18,
    cooldown_multiplier = 1.15,
    damage_multiplier = 1.08,
    value = "x1.18 range, x1.08 damage, x0.87 fire rate",
    description = "Pushes Sniper further into extreme range at the cost of an even slower firing rhythm.",
  },
  {
    id = "machine_shredder",
    parent = "machine_gun",
    sprite = "item/firearm-magazine",
    name = "Shredder",
    double_shot_chance_flat = 0.12,
    damage_multiplier = 0.92,
    value = "+12% double-shot chance, x0.92 damage",
    description = "Trades some shot weight for more frequent burst fire.",
  },
  {
    id = "machine_sustained",
    parent = "machine_gun",
    sprite = "item/piercing-rounds-magazine",
    name = "Sustained fire",
    cooldown_multiplier = 0.85,
    ammo_recovery_multiplier = 1.75,
    value = "x1.18 fire rate, x1.75 ammo recovery",
    description = "Improves sustained uptime by firing faster and recovering ammunition more aggressively.",
  },
  {
    id = "bulwark_bastion",
    parent = "bulwark",
    sprite = "item/concrete",
    name = "Bastion",
    health_multiplier = 1.35,
    resistance_flat = 0.05,
    cooldown_multiplier = 1.10,
    value = "x1.35 HP, +5% resistance, x0.91 fire rate",
    description = "Commits Bulwark to holding ground through raw durability and extra mitigation.",
  },
  {
    id = "bulwark_guardian",
    parent = "bulwark",
    sprite = "item/repair-pack",
    name = "Guardian",
    repair_multiplier = 1.80,
    range_multiplier = 1.08,
    value = "x1.8 regeneration, x1.08 range",
    description = "Turns Bulwark into a steadier protector with stronger self-repair and a little more reach.",
  },
  {
    id = "brawler_executioner",
    parent = "brawler",
    sprite = "item/shotgun",
    name = "Executioner",
    damage_multiplier = 1.35,
    crit_damage_multiplier = 1.35,
    lifesteal_multiplier = 0.80,
    value = "x1.35 damage, x1.35 crit damage, x0.8 lifesteal",
    description = "Makes Brawler more lethal at close range while softening its sustain.",
  },
  {
    id = "brawler_vampire",
    parent = "brawler",
    sprite = "item/steel-plate",
    name = "Vampire",
    lifesteal_multiplier = 1.80,
    health_multiplier = 1.18,
    damage_multiplier = 0.90,
    value = "x1.8 lifesteal, x1.18 HP, x0.9 damage",
    description = "Turns Brawler into a self-sustaining close-range anchor.",
  },
}
domain.sub_specialization_by_id = index_by_id(domain.sub_specializations)
domain.sub_specializations_by_parent = group_by_parent(domain.sub_specializations)

domain.label_color_presets = {
  { id = "gold", name = "Gold", color = { 1, 0.86, 0.46 }, display_color = { 1, 0.86, 0.46, 1 } },
  { id = "white", name = "White", color = { 1, 1, 1 }, display_color = { 1, 1, 1, 1 } },
  { id = "green", name = "Green", color = { 0.45, 1, 0.45 }, display_color = { 0.45, 1, 0.45, 1 } },
  { id = "blue", name = "Blue", color = { 0.45, 0.78, 1 }, display_color = { 0.45, 0.78, 1, 1 } },
  { id = "red", name = "Red", color = { 1, 0.36, 0.30 }, display_color = { 1, 0.36, 0.30, 1 } },
  { id = "purple", name = "Purple", color = { 0.86, 0.48, 1 }, display_color = { 0.86, 0.48, 1, 1 } },
}

domain.prototype_multiplier_fields = {
  "range_multiplier",
  "cooldown_multiplier",
  "damage_multiplier",
  "health_multiplier",
  "rotation_speed_multiplier",
}

local function clamp_rank(value, max_rank)
  return math.max(0, math.min(max_rank, math.floor(tonumber(value) or 0)))
end

function domain.clamp_range_rank(value)
  return clamp_rank(value, domain.range_augment_max)
end

function domain.clamp_max_health_rank(value)
  return clamp_rank(value, domain.max_health_augment_max)
end

function domain.get_sub_specialization_variant_segment(specialization_id, sub_specialization_id)
  if not specialization_id or not sub_specialization_id then
    return nil
  end

  local sub_specialization = domain.sub_specialization_by_id[sub_specialization_id]
  if not sub_specialization or sub_specialization.parent ~= specialization_id then
    return nil
  end

  local prefix = specialization_id .. "_"
  if string.sub(sub_specialization_id, 1, #prefix) == prefix then
    return string.sub(sub_specialization_id, #prefix + 1)
  end

  return sub_specialization_id
end

function domain.specialized_turret_variant_id(specialization_id, range_rank, health_rank, sub_specialization_id)
  range_rank = domain.clamp_range_rank(range_rank)
  health_rank = domain.clamp_max_health_rank(health_rank)

  local segments = {}
  if specialization_id and domain.specialization_by_id[specialization_id] then
    segments[#segments + 1] = specialization_id
    local sub_segment = domain.get_sub_specialization_variant_segment(specialization_id, sub_specialization_id)
    if sub_segment then
      segments[#segments + 1] = sub_segment
    end
  end
  if range_rank > 0 then
    segments[#segments + 1] = "range-" .. tostring(range_rank)
  end
  if health_rank > 0 then
    segments[#segments + 1] = "health-" .. tostring(health_rank)
  end

  if #segments == 0 then
    return nil
  end

  return table.concat(segments, "-")
end

function domain.specialized_turret_name(specialization_id, range_rank, health_rank, sub_specialization_id)
  local variant_id = domain.specialized_turret_variant_id(specialization_id, range_rank, health_rank, sub_specialization_id)
  if variant_id then
    return domain.names.specialized_turret_prefix .. variant_id
  end

  return domain.names.base_turret
end

function domain.bound_turret_variant_id(specialization_id, range_rank, sub_specialization_id)
  range_rank = domain.clamp_range_rank(range_rank)

  local segments = {}
  if specialization_id and domain.specialization_by_id[specialization_id] then
    segments[#segments + 1] = specialization_id
    local sub_segment = domain.get_sub_specialization_variant_segment(specialization_id, sub_specialization_id)
    if sub_segment then
      segments[#segments + 1] = sub_segment
    end
  end
  if range_rank > 0 then
    segments[#segments + 1] = "range-" .. tostring(range_rank)
  end

  if #segments == 0 then
    return nil
  end

  return table.concat(segments, "-")
end

function domain.bound_turret_item_name(variant_id)
  if not variant_id then
    return domain.names.bound_turret
  end

  return domain.names.bound_turret_variant_prefix .. variant_id
end

function domain.bound_turret_placeholder_name(variant_id)
  if not variant_id then
    return domain.names.bound_turret_placeholder
  end

  return domain.names.bound_turret_placeholder_variant_prefix .. variant_id
end

function domain.is_specialized_turret_name(name)
  return type(name) == "string" and string.sub(name, 1, #domain.names.specialized_turret_prefix) == domain.names.specialized_turret_prefix
end

function domain.is_bound_turret_item_name(name)
  return name == domain.names.bound_turret
    or (
      type(name) == "string"
      and string.sub(name, 1, #domain.names.bound_turret_variant_prefix) == domain.names.bound_turret_variant_prefix
      and string.sub(name, 1, #domain.names.bound_turret_placeholder) ~= domain.names.bound_turret_placeholder
    )
end

function domain.is_bound_turret_placeholder_name(name)
  return name == domain.names.bound_turret_placeholder
    or (
      type(name) == "string"
      and string.sub(name, 1, #domain.names.bound_turret_placeholder_variant_prefix)
        == domain.names.bound_turret_placeholder_variant_prefix
    )
end

function domain.combine_variant_settings(primary, secondary)
  local settings = {}
  for key, value in pairs(primary or {}) do
    settings[key] = value
  end

  for _, key in ipairs(domain.prototype_multiplier_fields) do
    local value = secondary and secondary[key] or nil
    if value ~= nil then
      settings[key] = (settings[key] or 1) * value
    end
  end

  return settings
end

function domain.for_each_specialized_turret_name(callback)
  for range_rank = 0, domain.range_augment_max do
    for health_rank = 0, domain.max_health_augment_max do
      if range_rank > 0 or health_rank > 0 then
        callback(domain.specialized_turret_name(nil, range_rank, health_rank), nil, range_rank, health_rank, nil)
      end
    end
  end

  for _, specialization in ipairs(domain.specializations) do
    for range_rank = 0, domain.range_augment_max do
      for health_rank = 0, domain.max_health_augment_max do
        callback(
          domain.specialized_turret_name(specialization.id, range_rank, health_rank),
          specialization.id,
          range_rank,
          health_rank,
          nil
        )
      end
    end
  end

  for _, sub_specialization in ipairs(domain.sub_specializations) do
    for range_rank = 0, domain.range_augment_max do
      for health_rank = 0, domain.max_health_augment_max do
        callback(
          domain.specialized_turret_name(sub_specialization.parent, range_rank, health_rank, sub_specialization.id),
          sub_specialization.parent,
          range_rank,
          health_rank,
          sub_specialization.id
        )
      end
    end
  end
end

function domain.for_each_bound_turret_variant(callback)
  for range_rank = 1, domain.range_augment_max do
    callback(domain.bound_turret_variant_id(nil, range_rank), nil, range_rank, nil)
  end

  for _, specialization in ipairs(domain.specializations) do
    for range_rank = 0, domain.range_augment_max do
      callback(domain.bound_turret_variant_id(specialization.id, range_rank), specialization.id, range_rank, nil)
    end
  end

  for _, sub_specialization in ipairs(domain.sub_specializations) do
    for range_rank = 0, domain.range_augment_max do
      callback(
        domain.bound_turret_variant_id(sub_specialization.parent, range_rank, sub_specialization.id),
        sub_specialization.parent,
        range_rank,
        sub_specialization.id
      )
    end
  end
end

return domain
