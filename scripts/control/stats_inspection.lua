local stats_inspection = {}

function stats_inspection.new(deps)
  local service = {}
  local safe_read = deps.safe_read
  local ensure_evolution_state = deps.ensure_evolution_state
  local get_specialized_turret_name = deps.get_specialized_turret_name
  local feeder = deps.feeder
  local inventory_defines = deps.inventory_defines
  local item_prototypes = deps.item_prototypes
  local entity_prototypes = deps.entity_prototypes
  local quality_prototypes = deps.quality_prototypes
  local compat = deps.compat
  local BASE_TURRET_NAME = deps.BASE_TURRET_NAME

  local sum_trigger_items
  local find_damage_type_in_trigger_items

  function service.as_array(value)
    if not value then
      return {}
    end

    if value[1] ~= nil then
      return value
    end

    return { value }
  end

  function service.sum_damage_effects(effects)
    local total = 0

    for _, effect in pairs(service.as_array(effects)) do
      local repeats = effect.repeat_count or 1
      local probability = effect.probability or 1

      if effect.type == "damage" and effect.damage and effect.damage.amount then
        total = total + (effect.damage.amount * repeats * probability)
      elseif effect.type == "nested-result" then
        total = total + (sum_trigger_items(effect.action) * repeats * probability)
      end
    end

    return total
  end

  function service.find_damage_type_in_effects(effects)
    for _, effect in pairs(service.as_array(effects)) do
      if effect.type == "damage" and effect.damage and effect.damage.type then
        return effect.damage.type
      elseif effect.type == "nested-result" then
        local damage_type = find_damage_type_in_trigger_items(effect.action)
        if damage_type then
          return damage_type
        end
      end
    end

    return nil
  end

  function service.sum_trigger_deliveries(deliveries)
    local total = 0

    for _, delivery in pairs(service.as_array(deliveries)) do
      total = total + service.sum_damage_effects(delivery.target_effects)
    end

    return total
  end

  function service.find_damage_type_in_deliveries(deliveries)
    for _, delivery in pairs(service.as_array(deliveries)) do
      local damage_type = service.find_damage_type_in_effects(delivery.target_effects)
      if damage_type then
        return damage_type
      end
    end

    return nil
  end

  sum_trigger_items = function(items)
    local total = 0

    for _, item in pairs(service.as_array(items)) do
      local repeats = item.repeat_count or 1
      local probability = item.probability or 1
      local damage = service.sum_trigger_deliveries(item.action_delivery)

      if item.type == "line" then
        damage = damage + service.sum_damage_effects(item.range_effects)
      end

      total = total + (damage * repeats * probability)
    end

    return total
  end

  find_damage_type_in_trigger_items = function(items)
    for _, item in pairs(service.as_array(items)) do
      local damage_type = service.find_damage_type_in_deliveries(item.action_delivery)
      if damage_type then
        return damage_type
      end

      if item.type == "line" then
        damage_type = service.find_damage_type_in_effects(item.range_effects)
        if damage_type then
          return damage_type
        end
      end
    end

    return nil
  end

  service.sum_trigger_items = sum_trigger_items
  service.find_damage_type_in_trigger_items = find_damage_type_in_trigger_items

  function service.get_effective_turret_prototype(entity, state)
    if state then
      local evolution = ensure_evolution_state(state)
      local target_name = get_specialized_turret_name(evolution.specialization, 0, 0, evolution.sub_specialization)
      local target_prototype = target_name and safe_read(entity_prototypes(), target_name, nil, "effective turret prototype")
      if target_prototype then
        return target_prototype, target_name
      end
    end

    return safe_read(entity, "prototype"), entity and entity.name or nil
  end

  function service.get_attack_parameters(entity, state)
    local prototype = service.get_effective_turret_prototype(entity, state)
    return safe_read(prototype, "attack_parameters") or {}
  end

  function service.get_loaded_ammo_snapshot(entity, preferred)
    local inventory = feeder.get_entity_inventory(entity, inventory_defines.turret_ammo)
    if not inventory or not inventory.valid then
      return nil
    end

    local preferred_name = preferred and preferred.name or nil
    local preferred_quality = preferred and (preferred.quality or "normal") or nil
    local first = nil
    local selected = nil

    for i = 1, #inventory do
      local stack = inventory[i]
      if stack and stack.valid_for_read and feeder.is_ammo_item(stack.name) then
        local quality = safe_read(stack, "quality")
        local quality_name = quality and quality.name or "normal"
        local prototype = safe_read(stack, "prototype")
        local magazine_size = tonumber(safe_read(prototype, "magazine_size")) or 0
        local snapshot = {
          stack = stack,
          slot_index = i,
          name = stack.name,
          quality = quality_name,
          count = math.max(0, math.floor(tonumber(stack.count) or 0)),
          ammo = math.max(0, math.floor(tonumber(safe_read(stack, "ammo")) or magazine_size or 0)),
          magazine_size = magazine_size,
        }

        first = first or snapshot
        if preferred_name and stack.name == preferred_name and quality_name == preferred_quality then
          selected = selected or snapshot
        end
      end
    end

    selected = selected or first
    if not selected then
      return nil
    end

    local total_count = 0
    for i = 1, #inventory do
      local stack = inventory[i]
      if stack and stack.valid_for_read and stack.name == selected.name then
        local quality = safe_read(stack, "quality")
        local quality_name = quality and quality.name or "normal"
        if quality_name == selected.quality then
          total_count = total_count + (tonumber(stack.count) or 0)
        end
      end
    end
    selected.count = math.max(0, math.floor(total_count))

    return selected
  end

  function service.get_loaded_ammo(entity)
    local snapshot = service.get_loaded_ammo_snapshot(entity)
    if not snapshot then
      return nil, 0, nil, nil, nil
    end

    return snapshot.name, snapshot.count, snapshot.quality, snapshot.ammo, snapshot.magazine_size
  end

  function service.get_ammo_type(ammo_name)
    if not ammo_name then
      return nil
    end

    local ammo = item_prototypes()[ammo_name]
    if not ammo then
      return nil
    end

    return compat.try("ammo type for turret", function()
      return ammo.get_ammo_type("turret")
    end)
  end

  function service.get_ammo_category_name(entity, ammo_name, state)
    if ammo_name then
      local ammo = item_prototypes()[ammo_name]
      local ammo_category = safe_read(ammo, "ammo_category")
      local ammo_category_name = safe_read(ammo_category, "name")
      if ammo_category_name then
        return ammo_category_name
      end
    end

    local attack_parameters = service.get_attack_parameters(entity, state)
    local categories = attack_parameters.ammo_categories
    if categories and categories[1] then
      return categories[1]
    end

    return nil
  end

  function service.get_entity_quality_name(entity)
    local quality = safe_read(entity, "quality")
    return quality and quality.name or "normal"
  end

  function service.get_quality_prototypes()
    local qualities = {}
    local qualities_by_name = quality_prototypes()

    if not qualities_by_name then
      return qualities
    end

    for _, quality in pairs(qualities_by_name) do
      if quality and quality.valid and quality.name ~= "quality-unknown" and not safe_read(quality, "hidden") then
        qualities[#qualities + 1] = quality
      end
    end

    table.sort(qualities, function(a, b)
      local a_level = safe_read(a, "level") or 0
      local b_level = safe_read(b, "level") or 0
      if a_level == b_level then
        return a.name < b.name
      end
      return a_level < b_level
    end)

    return qualities
  end

  function service.get_quality_localised_name(quality)
    return safe_read(quality, "localised_name") or { "quality-name." .. quality.name }
  end

  function service.get_quality_multiplier(quality, property)
    return safe_read(quality, property) or safe_read(quality, "default_multiplier") or 1
  end

  function service.make_quality_tooltip(value_for_quality, suffix)
    local qualities = service.get_quality_prototypes()
    if #qualities < 2 then
      return nil
    end

    local tooltip = { "", { "turret-xp.quality-summary-title" }, "\n" }
    for index, quality in ipairs(qualities) do
      local value = value_for_quality(quality)
      if value then
        tooltip[#tooltip + 1] = {
          "",
          "[quality=",
          quality.name,
          "] ",
          service.get_quality_localised_name(quality),
          ": ",
          value,
          suffix or "",
        }
        if index < #qualities then
          tooltip[#tooltip + 1] = "\n"
        end
      end
    end

    return tooltip
  end

  function service.get_shooting_speed_values(entity, ammo_name, state)
    local attack_parameters = service.get_attack_parameters(entity, state)
    if not attack_parameters.cooldown or attack_parameters.cooldown <= 0 then
      return nil, nil
    end

    local cooldown = attack_parameters.cooldown

    if ammo_name then
      local ammo_type = service.get_ammo_type(ammo_name)
      if ammo_type and ammo_type.cooldown_modifier then
        cooldown = cooldown * ammo_type.cooldown_modifier
      end
    end

    local base_speed = 60 / cooldown
    local speed_modifier = 0
    local force = safe_read(entity, "force")
    local ammo_category_name = service.get_ammo_category_name(entity, ammo_name, state)

    if force and ammo_category_name then
      local modifier = compat.try("gun speed modifier", function()
        return force.get_gun_speed_modifier(ammo_category_name)
      end)

      if modifier then
        speed_modifier = modifier
      end
    end

    local bonus_speed = base_speed * speed_modifier
    return base_speed, bonus_speed
  end

  function service.get_damage_values(entity, ammo_name, state)
    if not ammo_name then
      return nil, nil
    end

    local ammo_type = service.get_ammo_type(ammo_name)
    if not ammo_type then
      return nil, nil
    end

    local attack_parameters = service.get_attack_parameters(entity, state)
    local base_damage = service.sum_trigger_items(ammo_type.action) * (attack_parameters.damage_modifier or 1)
    local force = safe_read(entity, "force")
    local ammo_category_name = service.get_ammo_category_name(entity, ammo_name, state)
    local ammo_modifier = 0
    local turret_modifier = 0
    local _, turret_name = service.get_effective_turret_prototype(entity, state)

    if force and ammo_category_name then
      local modifier = compat.try("ammo damage modifier", function()
        return force.get_ammo_damage_modifier(ammo_category_name)
      end)

      if modifier then
        ammo_modifier = modifier
      end
    end

    if force then
      local modifier = compat.try("turret attack modifier", function()
        return force.get_turret_attack_modifier(turret_name or entity.name)
      end)

      if modifier then
        turret_modifier = modifier
      end
    end

    local final_damage = base_damage * (1 + ammo_modifier) * (1 + turret_modifier)
    local bonus_damage = final_damage - base_damage

    local damage_type = service.find_damage_type_in_trigger_items(ammo_type.action) or "physical"

    return base_damage, bonus_damage, damage_type
  end

  function service.get_range_for_quality(entity, quality_name, state)
    local attack_parameters = service.get_attack_parameters(entity, state)
    if not attack_parameters.range then
      return nil
    end

    local quality = safe_read(quality_prototypes(), quality_name)
    if not quality then
      return attack_parameters.range
    end

    return attack_parameters.range * service.get_quality_multiplier(quality, "range_multiplier")
  end

  function service.get_max_health_for_quality(entity, quality_name, state)
    local prototype = service.get_effective_turret_prototype(entity, state)
    if not prototype then
      return nil
    end

    return compat.try("prototype max health", function()
      return prototype.get_max_health(quality_name)
    end)
  end

  function service.get_base_turret_range_for_quality(quality_name)
    local quality = safe_read(quality_prototypes(), quality_name or "normal")
    local quality_multiplier = quality and service.get_quality_multiplier(quality, "range_multiplier") or 1
    local base_prototype = entity_prototypes()[BASE_TURRET_NAME]
    local base_attack_parameters = safe_read(base_prototype, "attack_parameters")
    if base_attack_parameters then
      return (base_attack_parameters.range or 0) * quality_multiplier
    end

    return nil
  end

  function service.get_base_turret_max_health(quality_name)
    local base_prototype = entity_prototypes()[BASE_TURRET_NAME]
    if not base_prototype then
      return nil
    end

    return compat.try("base prototype max health", function()
      return base_prototype.get_max_health(quality_name or "normal")
    end)
  end

  return service
end

return stats_inspection
