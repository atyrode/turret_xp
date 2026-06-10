local TURRET_VARIANT_PREFIX = "turret-xp-gun-turret-"
local BASE_TURRET_NAME = "gun-turret"

local function as_array(value)
  if not value then
    return {}
  end

  if value[1] ~= nil then
    return value
  end

  return { value }
end

local function is_turret_xp_body(name)
  return name == BASE_TURRET_NAME or string.sub(name, 1, #TURRET_VARIANT_PREFIX) == TURRET_VARIANT_PREFIX
end

local function add_category(categories, category)
  if type(category) == "string" and category ~= "" then
    categories[category] = true
  end
end

local function collect_attack_categories(categories, attack_parameters)
  if not attack_parameters then
    return
  end

  add_category(categories, attack_parameters.ammo_category)

  local ammo_categories = attack_parameters.ammo_categories
  if type(ammo_categories) ~= "table" then
    return
  end

  for key, value in pairs(ammo_categories) do
    if type(value) == "string" then
      add_category(categories, value)
    elseif type(key) == "string" and value == true then
      add_category(categories, key)
    end
  end
end

local function gun_turret_categories()
  local categories = {}
  local turret = data.raw["ammo-turret"] and data.raw["ammo-turret"][BASE_TURRET_NAME]
  collect_attack_categories(categories, turret and turret.attack_parameters)
  return categories
end

local function max_quality_range_multiplier()
  local multiplier = 1
  for _, quality in pairs(data.raw.quality or {}) do
    local value = tonumber(quality.range_multiplier)
    if value and value > multiplier then
      multiplier = value
    end
  end
  return multiplier
end

local function max_generated_turret_range()
  local max_range = 0
  for name, turret in pairs(data.raw["ammo-turret"] or {}) do
    local attack_parameters = turret.attack_parameters
    local range = attack_parameters and tonumber(attack_parameters.range)
    if range and range > max_range and is_turret_xp_body(name) then
      max_range = range
    end
  end

  return max_range * max_quality_range_multiplier()
end

local function required_projectile_range(target_range, delivery)
  local range_deviation = math.max(0, tonumber(delivery.range_deviation) or 0)
  local minimum_factor = math.max(0.1, 1 - (range_deviation / 2))
  return math.ceil((target_range / minimum_factor) * 100) / 100
end

local function patch_delivery(delivery, target_range)
  if type(delivery) ~= "table" or delivery.type ~= "projectile" or delivery.max_range == nil then
    return false
  end

  local current_range = tonumber(delivery.max_range)
  if not current_range then
    return false
  end

  local needed_range = required_projectile_range(target_range, delivery)
  if current_range >= needed_range then
    return false
  end

  delivery.max_range = needed_range
  return true
end

local function patch_trigger_item(item, target_range)
  local changed = false
  for _, delivery in pairs(as_array(item and item.action_delivery)) do
    changed = patch_delivery(delivery, target_range) or changed
  end
  return changed
end

local function patch_ammo_type(ammo_type, target_range)
  local changed = false
  for _, item in pairs(as_array(ammo_type and ammo_type.action)) do
    changed = patch_trigger_item(item, target_range) or changed
  end
  return changed
end

local function source_type_of(ammo_type)
  return ammo_type and ammo_type.source_type or nil
end

local function find_ammo_type_by_source(ammo_types, source_type)
  for _, ammo_type in ipairs(ammo_types) do
    if source_type_of(ammo_type) == source_type then
      return ammo_type
    end
  end
  return nil
end

local function first_ammo_type(ammo_types)
  for _, ammo_type in ipairs(ammo_types) do
    if type(ammo_type) == "table" then
      return ammo_type
    end
  end
  return nil
end

local function patch_ammo(ammo, target_range)
  if type(ammo.ammo_type) ~= "table" then
    return false
  end

  if ammo.ammo_type[1] == nil then
    local turret_ammo_type = table.deepcopy(ammo.ammo_type)
    turret_ammo_type.source_type = "turret"
    if not patch_ammo_type(turret_ammo_type, target_range) then
      return false
    end

    local default_ammo_type = table.deepcopy(ammo.ammo_type)
    default_ammo_type.source_type = "default"
    ammo.ammo_type = {
      default_ammo_type,
      turret_ammo_type
    }
    return true
  end

  local turret_ammo_type = find_ammo_type_by_source(ammo.ammo_type, "turret")
  if turret_ammo_type then
    return patch_ammo_type(turret_ammo_type, target_range)
  end

  local source_ammo_type = find_ammo_type_by_source(ammo.ammo_type, "default") or first_ammo_type(ammo.ammo_type)
  if not source_ammo_type then
    return false
  end

  turret_ammo_type = table.deepcopy(source_ammo_type)
  turret_ammo_type.source_type = "turret"
  if not patch_ammo_type(turret_ammo_type, target_range) then
    return false
  end

  table.insert(ammo.ammo_type, turret_ammo_type)
  return true
end

return function()
  local target_range = max_generated_turret_range()
  if target_range <= 0 then
    return
  end

  local accepted_categories = gun_turret_categories()
  for _, ammo in pairs(data.raw.ammo or {}) do
    if accepted_categories[ammo.ammo_category] then
      patch_ammo(ammo, target_range)
    end
  end
end
