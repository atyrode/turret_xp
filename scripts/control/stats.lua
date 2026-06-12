local damage_accounting = require("scripts.control.damage_accounting")

return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  local damage_accounting_service = nil

  local function get_damage_accounting_service()
    if not damage_accounting_service then
      damage_accounting_service = damage_accounting.new({
        target_damage_ttl = TARGET_DAMAGE_TTL,
        ensure_storage = ensure_storage,
        storage_root = function()
          return storage.turret_xp
        end,
        game_tick = function()
          return game.tick
        end,
        safe_read = safe_read,
        entity_tracking_key = entity_tracking_key,
        turret_key = turret_key,
        is_gun_turret = is_gun_turret,
        get_turret_state = get_turret_state,
        get_entity_xp_context = function(entity)
          return combat.get_entity_xp_context(entity)
        end,
        add_profile_kill_credit = add_profile_kill_credit,
        sync_turret_progression = sync_turret_progression,
        update_name_render = update_name_render,
      })
    end

    return damage_accounting_service
  end

  function as_array(value)
    if not value then
      return {}
    end

    if value[1] ~= nil then
      return value
    end

    return { value }
  end

  sum_trigger_items = nil
  find_damage_type_in_trigger_items = nil

  function sum_damage_effects(effects)
    local total = 0

    for _, effect in pairs(as_array(effects)) do
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

  function find_damage_type_in_effects(effects)
    for _, effect in pairs(as_array(effects)) do
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

  function sum_trigger_deliveries(deliveries)
    local total = 0

    for _, delivery in pairs(as_array(deliveries)) do
      total = total + sum_damage_effects(delivery.target_effects)
    end

    return total
  end

  function find_damage_type_in_deliveries(deliveries)
    for _, delivery in pairs(as_array(deliveries)) do
      local damage_type = find_damage_type_in_effects(delivery.target_effects)
      if damage_type then
        return damage_type
      end
    end

    return nil
  end

  sum_trigger_items = function(items)
    local total = 0

    for _, item in pairs(as_array(items)) do
      local repeats = item.repeat_count or 1
      local probability = item.probability or 1
      local damage = sum_trigger_deliveries(item.action_delivery)

      if item.type == "line" then
        damage = damage + sum_damage_effects(item.range_effects)
      end

      total = total + (damage * repeats * probability)
    end

    return total
  end

  find_damage_type_in_trigger_items = function(items)
    for _, item in pairs(as_array(items)) do
      local damage_type = find_damage_type_in_deliveries(item.action_delivery)
      if damage_type then
        return damage_type
      end

      if item.type == "line" then
        damage_type = find_damage_type_in_effects(item.range_effects)
        if damage_type then
          return damage_type
        end
      end
    end

    return nil
  end

  function get_attack_parameters(entity)
    return safe_read(safe_read(entity, "prototype"), "attack_parameters") or {}
  end

  function get_loaded_ammo(entity)
    local inventory = entity.get_inventory(defines.inventory.turret_ammo)
    if not inventory or not inventory.valid then
      return nil, 0, nil
    end

    local ammo_name = nil
    local ammo_quality = nil
    local count = 0

    for i = 1, #inventory do
      local stack = inventory[i]
      if stack and stack.valid_for_read then
        ammo_name = ammo_name or stack.name
        if not ammo_quality and stack.name == ammo_name then
          local quality = safe_read(stack, "quality")
          ammo_quality = quality and quality.name or "normal"
        end
        if stack.name == ammo_name then
          count = count + stack.count
        end
      end
    end

    return ammo_name, count, ammo_quality
  end

  function get_ammo_type(ammo_name)
    if not ammo_name then
      return nil
    end

    local ammo = prototypes.item[ammo_name]
    if not ammo then
      return nil
    end

    return compat.try("ammo type for turret", function()
      return ammo.get_ammo_type("turret")
    end)
  end

  function get_ammo_category_name(entity, ammo_name)
    if ammo_name then
      local ammo = prototypes.item[ammo_name]
      local ammo_category = safe_read(ammo, "ammo_category")
      local ammo_category_name = safe_read(ammo_category, "name")
      if ammo_category_name then
        return ammo_category_name
      end
    end

    local attack_parameters = get_attack_parameters(entity)
    local categories = attack_parameters.ammo_categories
    if categories and categories[1] then
      return categories[1]
    end

    return nil
  end

  function format_number(value, decimals)
    if not value then
      return "-"
    end

    if math.abs(value - math.floor(value)) < 0.01 then
      return string.format("%d", math.floor(value + 0.5))
    end

    return string.format("%." .. tostring(decimals or 1) .. "f", value)
  end

  function format_colored_bonus(value, decimals, numeric_suffix)
    local formatted = format_number(math.abs(value), decimals)
    local sign = value < 0 and "- " or "+ "
    local color = value < 0 and COLOR.penalty or COLOR.bonus
    return "[color=" .. color[1] .. "," .. color[2] .. "," .. color[3] .. "]" .. sign .. formatted .. (numeric_suffix or "") .. "[/color]"
  end

  function format_base_plus_bonus(base, bonus, suffix, decimals)
    suffix = suffix or ""

    if not base then
      return "-"
    end

    if bonus and math.abs(bonus) >= 0.005 then
      local numeric_suffix = ""
      local text_suffix = suffix
      if string.sub(suffix, 1, 1) == "%" then
        numeric_suffix = "%"
        text_suffix = string.sub(suffix, 2)
      end
      return format_number(base, decimals) .. " " .. format_colored_bonus(bonus, decimals, numeric_suffix) .. text_suffix
    end

    return format_number(base, decimals) .. suffix
  end

  function format_colored_multiplier(multiplier)
    if not multiplier or math.abs(multiplier - 1) < 0.005 then
      return nil
    end

    local color = multiplier < 1 and COLOR.penalty or COLOR.bonus
    return "[color=" .. color[1] .. "," .. color[2] .. "," .. color[3] .. "]x" .. format_number(multiplier, 2) .. "[/color]"
  end

  function append_multiplier(caption, multiplier)
    local formatted = format_colored_multiplier(multiplier)
    if not formatted then
      return caption
    end

    return { "", caption, " ", formatted }
  end

  function format_stat_formula(base, additive, multiplier, total, suffix, decimals)
    if not total then
      return "-"
    end

    suffix = suffix or ""
    local numeric_suffix = ""
    local text_suffix = suffix
    if string.sub(suffix, 1, 1) == "%" then
      numeric_suffix = "%"
      text_suffix = string.sub(suffix, 2)
    end
    local has_additive = additive and math.abs(additive) >= 0.005
    local has_multiplier = multiplier and math.abs(multiplier - 1) >= 0.005
    if not has_additive and not has_multiplier then
      return format_number(total, decimals) .. suffix
    end

    local base_text = format_number(base or 0, decimals) .. numeric_suffix
    local total_text = format_number(total, decimals) .. numeric_suffix .. text_suffix
    if has_additive and has_multiplier then
      return {
        "",
        "(",
        base_text,
        " ",
        format_colored_bonus(additive, decimals, numeric_suffix),
        ") ",
        format_colored_multiplier(multiplier),
        " = ",
        total_text,
      }
    end

    if has_additive then
      return {
        "",
        base_text,
        " ",
        format_colored_bonus(additive, decimals, numeric_suffix),
        " = ",
        total_text,
      }
    end

    return {
      "",
      base_text,
      " ",
      format_colored_multiplier(multiplier),
      " = ",
      total_text,
    }
  end

  function get_specialization(state)
    if not state then
      return nil
    end

    local specialization_id = ensure_evolution_state(state).specialization
    return specialization_id and SPECIALIZATION_BY_ID[specialization_id] or nil
  end

  function get_sub_specialization(state)
    if not state then
      return nil
    end

    local evolution = ensure_evolution_state(state)
    local sub_specialization = evolution.sub_specialization and SUB_SPECIALIZATION_BY_ID[evolution.sub_specialization] or nil
    if sub_specialization and sub_specialization.parent == evolution.specialization then
      return sub_specialization
    end

    return nil
  end

  function get_specialization_multiplier(state, field)
    local specialization = get_specialization(state)
    if not field then
      return 1
    end

    local multiplier = specialization and (tonumber(specialization[field]) or 1) or 1
    local sub_specialization = get_sub_specialization(state)
    if sub_specialization then
      multiplier = multiplier * (tonumber(sub_specialization[field]) or 1)
    end

    return multiplier
  end

  function get_sub_specialization_flat_bonus(state, field)
    local sub_specialization = get_sub_specialization(state)
    return sub_specialization and (tonumber(sub_specialization[field]) or 0) or 0
  end

  function get_repair_reference_health(state, entity)
    local source = entity
    if not is_gun_turret(source) and state then
      source = state.entity
    end

    local max_health = safe_read(source, "max_health")
    if max_health and max_health > 0 then
      return max_health
    end

    return 400
  end

  function get_repair_base_per_second(state, entity)
    return get_base_rank(state, "repair") * REPAIR_MAX_HEALTH_FRACTION_PER_RANK * get_repair_reference_health(state, entity)
  end

  function get_repair_per_second(state, entity)
    return get_repair_base_per_second(state, entity) * get_specialization_multiplier(state, "repair_multiplier")
  end

  function get_ammo_recovery_per_minute(state)
    return get_base_rank(state, "ammo_regen") * get_specialization_multiplier(state, "ammo_recovery_multiplier")
  end

  function get_lifesteal_rate(state)
    return get_base_rank(state, "siphon") * 0.004 * get_specialization_multiplier(state, "lifesteal_multiplier")
  end

  function get_damage_resistance_fraction(state)
    return math.min(
      RESISTANCE_MAX,
      (get_base_rank(state, "resistance") * RESISTANCE_PER_RANK) + get_sub_specialization_flat_bonus(state, "resistance_flat")
    )
  end

  function get_crit_damage_multiplier(state)
    return get_specialization_multiplier(state, "crit_damage_multiplier")
  end

  function get_crit_damage_fraction(state)
    return (0.50 + (get_base_rank(state, "crit_damage") * 0.01)) * get_crit_damage_multiplier(state)
  end

  function get_crit_chance_fraction(state)
    return apply_luck_to_chance(
      state,
      (get_base_rank(state, "crit_chance") * 0.0025) + get_sub_specialization_flat_bonus(state, "crit_chance_flat")
    )
  end

  function get_double_shot_chance(state)
    return apply_luck_to_chance(
      state,
      (get_augment_rank(state, "double_shot") * 0.04) + get_sub_specialization_flat_bonus(state, "double_shot_chance_flat")
    )
  end

  function get_crit_damage_formula_values(state)
    return {
      base = 50,
      additive = get_base_rank(state, "crit_damage"),
      multiplier = get_crit_damage_multiplier(state),
      total = get_crit_damage_fraction(state) * 100,
    }
  end

  function get_luck_multiplier(state)
    return 1 + (get_augment_rank(state, "luck") * 0.05)
  end

  function apply_luck_to_chance(state, chance)
    return math.min(0.95, math.max(0, (chance or 0) * get_luck_multiplier(state)))
  end

  function get_entity_quality_name(entity)
    local quality = safe_read(entity, "quality")
    return quality and quality.name or "normal"
  end

  function get_quality_prototypes()
    local qualities = {}
    local quality_prototypes = safe_read(prototypes, "quality")

    if not quality_prototypes then
      return qualities
    end

    for _, quality in pairs(quality_prototypes) do
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

  function get_quality_localised_name(quality)
    return safe_read(quality, "localised_name") or { "quality-name." .. quality.name }
  end

  function get_quality_multiplier(quality, property)
    return safe_read(quality, property) or safe_read(quality, "default_multiplier") or 1
  end

  function make_quality_tooltip(value_for_quality, suffix)
    local qualities = get_quality_prototypes()
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
          get_quality_localised_name(quality),
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

  function with_info_marker(caption, tooltip)
    if tooltip then
      return { "", caption, " [img=info]" }
    end

    return caption
  end

  function with_quality_marker(caption, tooltip)
    if tooltip then
      return { "", caption, " [img=quality_info]" }
    end

    return caption
  end

  function get_shooting_speed_values(entity, ammo_name)
    local attack_parameters = get_attack_parameters(entity)
    if not attack_parameters.cooldown or attack_parameters.cooldown <= 0 then
      return nil, nil
    end

    local cooldown = attack_parameters.cooldown

    if ammo_name then
      local ammo_type = get_ammo_type(ammo_name)
      if ammo_type and ammo_type.cooldown_modifier then
        cooldown = cooldown * ammo_type.cooldown_modifier
      end
    end

    local base_speed = 60 / cooldown
    local speed_modifier = 0
    local force = safe_read(entity, "force")
    local ammo_category_name = get_ammo_category_name(entity, ammo_name)

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

  function format_shots_per_second(entity, ammo_name)
    local base_speed, bonus_speed = get_shooting_speed_values(entity, ammo_name)
    return format_base_plus_bonus(base_speed, bonus_speed, "/s", 2)
  end

  function get_damage_values(entity, ammo_name)
    if not ammo_name then
      return nil, nil
    end

    local ammo_type = get_ammo_type(ammo_name)
    if not ammo_type then
      return nil, nil
    end

    local attack_parameters = get_attack_parameters(entity)
    local base_damage = sum_trigger_items(ammo_type.action) * (attack_parameters.damage_modifier or 1)
    local force = safe_read(entity, "force")
    local ammo_category_name = get_ammo_category_name(entity, ammo_name)
    local ammo_modifier = 0
    local turret_modifier = 0

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
        return force.get_turret_attack_modifier(entity.name)
      end)

      if modifier then
        turret_modifier = modifier
      end
    end

    local final_damage = base_damage * (1 + ammo_modifier) * (1 + turret_modifier)
    local bonus_damage = final_damage - base_damage

    local damage_type = find_damage_type_in_trigger_items(ammo_type.action) or "physical"

    return base_damage, bonus_damage, damage_type
  end

  function format_damage_per_shot(entity, ammo_name)
    local base_damage, bonus_damage, damage_type = get_damage_values(entity, ammo_name)
    local formatted = format_base_plus_bonus(base_damage, bonus_damage, "", 1)
    if damage_type and formatted ~= "-" then
      return { "turret-xp.damage-value-with-type", formatted, { "damage-type-name." .. damage_type } }
    end

    return formatted
  end

  function get_final_damage_per_shot(entity, ammo_name)
    local base_damage, bonus_damage = get_damage_values(entity, ammo_name)
    if not base_damage then
      return nil
    end

    return base_damage + (bonus_damage or 0)
  end

  function get_final_shots_per_second(entity, ammo_name)
    local base_speed, bonus_speed = get_shooting_speed_values(entity, ammo_name)
    if not base_speed then
      return nil
    end

    return base_speed + (bonus_speed or 0)
  end

  get_range_for_quality = nil

  function get_shooting_speed_formula_values(entity, state, ammo_name)
    local base_speed, bonus_speed = get_shooting_speed_values(entity, ammo_name)
    if not base_speed then
      return nil
    end

    local multiplier = 1 / get_specialization_multiplier(state, "cooldown_multiplier")
    return {
      base = base_speed / multiplier,
      additive = (bonus_speed or 0) / multiplier,
      multiplier = multiplier,
      total = base_speed + (bonus_speed or 0),
    }
  end

  function get_damage_formula_values(entity, state, ammo_name)
    local base_damage, bonus_damage, damage_type = get_damage_values(entity, ammo_name)
    if not base_damage then
      return nil
    end

    local multiplier = get_specialization_multiplier(state, "damage_multiplier")
    local core_additive = get_base_rank(state, "damage") * 0.5
    local vanilla_base = base_damage / multiplier
    local vanilla_bonus = (bonus_damage or 0) / multiplier
    local additive = vanilla_bonus + core_additive

    return {
      base = vanilla_base,
      additive = additive,
      multiplier = multiplier,
      total = (vanilla_base + additive) * multiplier,
      damage_type = damage_type,
      core_additive = core_additive,
      research_additive = vanilla_bonus,
    }
  end

  function get_expected_damage_per_shot(entity, state, ammo_name)
    local values = get_damage_formula_values(entity, state, ammo_name)
    if not values then
      return nil
    end

    local shot_damage = values.total
    local crit_chance = get_crit_chance_fraction(state)
    local crit_extra = shot_damage * crit_chance * get_crit_damage_fraction(state)
    local double_extra = shot_damage * get_double_shot_chance(state)
    local bounce_extra = shot_damage * 0.35 * apply_luck_to_chance(state, get_augment_rank(state, "bounce") * 0.05)

    return {
      base = shot_damage,
      expected_bonus = crit_extra + double_extra + bounce_extra,
      total = shot_damage + crit_extra + double_extra + bounce_extra,
    }
  end

  function format_estimated_dps(entity, ammo_name, state)
    local expected = get_expected_damage_per_shot(entity, state, ammo_name)
    local speed = get_final_shots_per_second(entity, ammo_name)
    if not expected or not speed then
      return "-"
    end

    local damage = expected.total
    local total = damage * speed
    if expected.expected_bonus and expected.expected_bonus >= 0.005 then
      return {
        "",
        "(",
        format_number(expected.base, 1),
        " ",
        format_colored_bonus(expected.expected_bonus, 1),
        ") x ",
        format_number(speed, 2),
        "/s = ",
        format_number(total, 1),
        "/s",
      }
    end

    return format_number(total, 1) .. "/s"
  end

  function get_range_formula_values(entity, state, quality_name)
    local total = get_range_for_quality(entity, quality_name)
    if not total then
      return nil
    end

    local multiplier = get_specialization_multiplier(state, "range_multiplier")
    local range_rank = get_augment_rank(state, "range")
    local quality = safe_read(prototypes.quality, quality_name or "normal")
    local quality_multiplier = quality and get_quality_multiplier(quality, "range_multiplier") or 1
    local base_range = nil
    local base_prototype = prototypes.entity[BASE_TURRET_NAME]
    local base_attack_parameters = safe_read(base_prototype, "attack_parameters")
    if base_attack_parameters then
      base_range = (base_attack_parameters.range or 0) * quality_multiplier
    end

    if not base_range then
      base_range = (total / multiplier) - (range_rank * quality_multiplier)
    end

    return {
      base = base_range,
      additive = range_rank * quality_multiplier,
      multiplier = multiplier,
      total = total,
    }
  end

  function get_health_formula_values(entity, state, quality_name, max_health)
    if not max_health then
      return nil
    end

    local multiplier = get_specialization_multiplier(state, "health_multiplier")
    local health_rank = get_augment_rank(state, "max_health")
    local quality = safe_read(prototypes.quality, quality_name or "normal")
    local quality_multiplier = quality and get_quality_multiplier(quality, "health_multiplier") or 1
    local additive = health_rank * MAX_HEALTH_PER_RANK * quality_multiplier
    local base_health = nil
    local base_prototype = prototypes.entity[BASE_TURRET_NAME]
    if base_prototype then
      base_health = compat.try("base prototype max health", function()
        return base_prototype.get_max_health(quality_name or "normal")
      end)
    end

    local total = max_health
    if base_health then
      total = math.floor(((base_health + additive) * multiplier) + 0.5)
    end

    return {
      base = base_health or (max_health / multiplier),
      additive = additive,
      multiplier = multiplier,
      total = total,
    }
  end

  function get_max_health_for_quality(entity, quality_name)
    local prototype = safe_read(entity, "prototype")
    if not prototype then
      return nil
    end

    return compat.try("prototype max health", function()
      return prototype.get_max_health(quality_name)
    end)
  end

  format_range_for_quality = nil

  function format_range(entity)
    return format_range_for_quality(entity, get_entity_quality_name(entity))
  end

  get_range_for_quality = function(entity, quality_name)
    local attack_parameters = get_attack_parameters(entity)
    if not attack_parameters.range then
      return nil
    end

    local quality = safe_read(prototypes.quality, quality_name)
    if not quality then
      return attack_parameters.range
    end

    return attack_parameters.range * get_quality_multiplier(quality, "range_multiplier")
  end

  format_range_for_quality = function(entity, quality_name)
    return format_number(get_range_for_quality(entity, quality_name), 1)
  end

  function target_prior_damage(event, damage)
    return get_damage_accounting_service().target_prior_damage(event, damage)
  end

  function get_or_create_target_damage(event, damage, create)
    return get_damage_accounting_service().get_or_create_target_damage(event, damage, create)
  end

  function record_damage_contribution(event, turret, damage)
    get_damage_accounting_service().record_damage_contribution(event, turret, damage)
  end

  function resolve_kill_turret(entry, killing_turret)
    return get_damage_accounting_service().resolve_kill_turret(entry, killing_turret)
  end

  function award_kill_credit(target, killing_turret)
    return get_damage_accounting_service().award_kill_credit(target, killing_turret)
  end

  function award_visible_kill(turret)
    get_damage_accounting_service().award_visible_kill(turret)
  end

  function cleanup_target_damage()
    get_damage_accounting_service().cleanup_target_damage()
  end

  function cleanup_pending_bound_mining()
    ensure_storage()

    local cutoff = game.tick - (60 * 10)
    for key, entry in pairs(storage.turret_xp.pending_bound_mined or {}) do
      if not entry or (entry.tick or 0) < cutoff then
        local entity = entry and entry.entity
        if entry and (not entity or not entity.valid) and entry.profile and entry.turret then
          local surface = game.get_surface(entry.surface_index)
          if surface and entry.position then
            spill_stack_definition_at(surface, entry.position, make_bound_turret_item_stack(entry.profile, entry.turret))
          end
          local chip_id = entry.profile and entry.profile.chip_id
          if chip_id then
            storage.turret_xp.chips[chip_id] = nil
          end
          if entry.key then
            storage.turret_xp.turrets[entry.key] = nil
          end
        end
        storage.turret_xp.pending_bound_mined[key] = nil
      end
    end
  end
end
