local damage_accounting = require("scripts.control.damage_accounting")
local stats_formatter = require("scripts.control.stats_formatter")
local stats_inspection = require("scripts.control.stats_inspection")
local stats_math = require("scripts.control.stats_math")

local stats_module = {}

local function copy_exports(target, source, names)
  for _, name in ipairs(names) do
    target[name] = source[name]
  end
end

function stats_module.new(deps)
  local service = {}
  local formatter = stats_formatter.new({
    COLOR = deps.COLOR,
  })
  local math_service = stats_math.new({
    SPECIALIZATION_BY_ID = deps.SPECIALIZATION_BY_ID,
    SUB_SPECIALIZATION_BY_ID = deps.SUB_SPECIALIZATION_BY_ID,
    ensure_evolution_state = deps.ensure_evolution_state,
    get_augment_rank = deps.get_augment_rank,
    get_base_rank = deps.get_base_rank,
    REPAIR_MAX_HEALTH_FRACTION_PER_RANK = deps.REPAIR_MAX_HEALTH_FRACTION_PER_RANK,
    AMMO_PRODUCTIVITY_PER_RANK = deps.AMMO_PRODUCTIVITY_PER_RANK,
    SHIELD_ON_HIT_FRACTION_PER_RANK = deps.SHIELD_ON_HIT_FRACTION_PER_RANK,
    RESISTANCE_MAX = deps.RESISTANCE_MAX,
    RESISTANCE_PER_RANK = deps.RESISTANCE_PER_RANK,
  })
  local inspection = stats_inspection.new({
    safe_read = deps.safe_read,
    ensure_evolution_state = deps.ensure_evolution_state,
    get_specialized_turret_name = deps.get_specialized_turret_name,
    feeder = deps.feeder,
    inventory_defines = deps.inventory_defines,
    item_prototypes = deps.item_prototypes,
    entity_prototypes = deps.entity_prototypes,
    quality_prototypes = deps.quality_prototypes,
    compat = deps.compat,
    BASE_TURRET_NAME = deps.BASE_TURRET_NAME,
  })

  local damage_accounting_service = nil

  local function get_damage_accounting_service()
    if not damage_accounting_service then
      damage_accounting_service = damage_accounting.new({
        target_damage_ttl = deps.target_damage_ttl,
        ensure_storage = deps.ensure_storage,
        storage_root = deps.storage_root,
        game_tick = deps.game_tick,
        safe_read = deps.safe_read,
        entity_tracking_key = deps.entity_tracking_key,
        turret_key = deps.turret_key,
        is_gun_turret = deps.is_gun_turret,
        get_turret_state = deps.get_turret_state,
        get_entity_xp_context = function(entity)
          return deps.combat.get_entity_xp_context(entity)
        end,
        add_profile_kill_credit = deps.add_profile_kill_credit,
        sync_turret_progression = deps.sync_turret_progression,
        update_name_render = deps.update_name_render,
      })
    end

    return damage_accounting_service
  end

  copy_exports(service, inspection, {
    "as_array",
    "sum_damage_effects",
    "find_damage_type_in_effects",
    "sum_trigger_deliveries",
    "find_damage_type_in_deliveries",
    "sum_trigger_items",
    "find_damage_type_in_trigger_items",
    "get_effective_turret_prototype",
    "get_attack_parameters",
    "get_loaded_ammo_snapshot",
    "get_loaded_ammo",
    "get_ammo_type",
    "get_ammo_category_name",
    "get_entity_quality_name",
    "get_quality_prototypes",
    "get_quality_localised_name",
    "get_quality_multiplier",
    "make_quality_tooltip",
    "get_shooting_speed_values",
    "get_damage_values",
    "get_range_for_quality",
    "get_max_health_for_quality",
  })

  copy_exports(service, formatter, {
    "format_number",
    "format_colored_bonus",
    "format_base_plus_bonus",
    "format_colored_multiplier",
    "append_multiplier",
    "format_stat_formula",
    "format_estimated_dps_formula",
    "with_info_marker",
    "with_quality_marker",
  })

  copy_exports(service, math_service, {
    "get_specialization",
    "get_sub_specialization",
    "get_specialization_multiplier",
    "get_sub_specialization_flat_bonus",
    "get_repair_base_per_second_for_health",
    "get_repair_per_second_for_health",
    "get_ammo_productivity_fraction",
    "get_effective_ammo_productivity_fraction",
    "get_ammo_recovery_per_minute",
    "get_shield_on_hit_fraction",
    "get_lifesteal_rate",
    "get_damage_resistance_fraction",
    "get_crit_damage_multiplier",
    "get_crit_damage_fraction",
    "get_crit_chance_fraction",
    "get_double_shot_chance",
    "get_crit_damage_formula_values",
    "get_luck_multiplier",
    "apply_luck_to_chance",
  })

  function service.get_repair_reference_health(state, entity)
    local source = entity
    if not deps.is_gun_turret(source) and state then
      source = state.entity
    end

    local max_health = deps.safe_read(source, "max_health")
    if max_health and max_health > 0 then
      return max_health
    end

    return 400
  end

  function service.get_repair_base_per_second(state, entity)
    return math_service.get_repair_base_per_second_for_health(state, service.get_repair_reference_health(state, entity))
  end

  function service.get_repair_per_second(state, entity)
    return math_service.get_repair_per_second_for_health(state, service.get_repair_reference_health(state, entity))
  end

  function service.format_shots_per_second(entity, ammo_name, state)
    local base_speed, bonus_speed = inspection.get_shooting_speed_values(entity, ammo_name, state)
    return formatter.format_base_plus_bonus(base_speed, bonus_speed, "/s", 2)
  end

  function service.format_damage_per_shot(entity, ammo_name, state)
    local base_damage, bonus_damage, damage_type = inspection.get_damage_values(entity, ammo_name, state)
    local formatted = formatter.format_base_plus_bonus(base_damage, bonus_damage, "", 1)
    if damage_type and formatted ~= "-" then
      return { "turret-xp.damage-value-with-type", formatted, { "damage-type-name." .. damage_type } }
    end

    return formatted
  end

  function service.get_final_damage_per_shot(entity, ammo_name, state)
    local base_damage, bonus_damage = inspection.get_damage_values(entity, ammo_name, state)
    if not base_damage then
      return nil
    end

    return base_damage + (bonus_damage or 0)
  end

  function service.get_final_shots_per_second(entity, ammo_name, state)
    local base_speed, bonus_speed = inspection.get_shooting_speed_values(entity, ammo_name, state)
    if not base_speed then
      return nil
    end

    return base_speed + (bonus_speed or 0)
  end

  function service.get_shooting_speed_formula_values(entity, state, ammo_name)
    local base_speed, bonus_speed = inspection.get_shooting_speed_values(entity, ammo_name, state)
    if not base_speed then
      return nil
    end

    local multiplier = 1 / math_service.get_specialization_multiplier(state, "cooldown_multiplier")
    return {
      base = base_speed / multiplier,
      additive = (bonus_speed or 0) / multiplier,
      multiplier = multiplier,
      total = base_speed + (bonus_speed or 0),
    }
  end

  function service.get_damage_formula_values(entity, state, ammo_name)
    local base_damage, bonus_damage, damage_type = inspection.get_damage_values(entity, ammo_name, state)
    if not base_damage then
      return nil
    end

    local multiplier = math_service.get_specialization_multiplier(state, "damage_multiplier")
    local core_additive = deps.get_base_rank(state, "damage") * 0.5
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

  function service.get_expected_damage_per_shot(entity, state, ammo_name)
    local values = service.get_damage_formula_values(entity, state, ammo_name)
    if not values then
      return nil
    end

    local shot_damage = values.total
    local crit_chance = math_service.get_crit_chance_fraction(state)
    local crit_extra = shot_damage * crit_chance * math_service.get_crit_damage_fraction(state)
    local double_extra = shot_damage * math_service.get_double_shot_chance(state)
    local bounce_extra = shot_damage * 0.35 * math_service.apply_luck_to_chance(state, deps.get_augment_rank(state, "bounce") * 0.05)

    return {
      base = shot_damage,
      expected_bonus = crit_extra + double_extra + bounce_extra,
      total = shot_damage + crit_extra + double_extra + bounce_extra,
    }
  end

  function service.get_estimated_dps_values(entity, ammo_name, state)
    local expected = service.get_expected_damage_per_shot(entity, state, ammo_name)
    local speed = service.get_final_shots_per_second(entity, ammo_name, state)
    if not expected or not speed then
      return nil
    end

    local damage = expected.total
    return {
      expected = expected,
      speed = speed,
      total = damage * speed,
    }
  end

  function service.format_estimated_dps(entity, ammo_name, state)
    local values = service.get_estimated_dps_values(entity, ammo_name, state)
    if not values then
      return "-"
    end

    return formatter.format_number(values.total, 1) .. "/s"
  end

  function service.get_range_formula_values(entity, state, quality_name)
    local total = inspection.get_range_for_quality(entity, quality_name, state)
    if not total then
      return nil
    end

    local multiplier = math_service.get_specialization_multiplier(state, "range_multiplier")
    local base_range = inspection.get_base_turret_range_for_quality(quality_name)

    if not base_range then
      base_range = total / multiplier
    end

    return {
      base = base_range,
      additive = 0,
      multiplier = multiplier,
      total = total,
    }
  end

  function service.get_health_formula_values(entity, state, quality_name, max_health)
    if not max_health then
      return nil
    end

    local multiplier = math_service.get_specialization_multiplier(state, "health_multiplier")
    local base_health = inspection.get_base_turret_max_health(quality_name)

    local total = max_health
    if base_health then
      total = math.floor((base_health * multiplier) + 0.5)
    end

    return {
      base = base_health or (max_health / multiplier),
      additive = 0,
      multiplier = multiplier,
      total = total,
    }
  end

  function service.format_range(entity, state)
    return service.format_range_for_quality(entity, inspection.get_entity_quality_name(entity), state)
  end

  function service.format_range_for_quality(entity, quality_name, state)
    return formatter.format_number(inspection.get_range_for_quality(entity, quality_name, state), 1)
  end

  function service.target_prior_damage(event, damage)
    return get_damage_accounting_service().target_prior_damage(event, damage)
  end

  function service.get_or_create_target_damage(event, damage, create)
    return get_damage_accounting_service().get_or_create_target_damage(event, damage, create)
  end

  function service.record_damage_contribution(event, turret, damage)
    get_damage_accounting_service().record_damage_contribution(event, turret, damage)
  end

  function service.resolve_kill_turret(entry, killing_turret)
    return get_damage_accounting_service().resolve_kill_turret(entry, killing_turret)
  end

  function service.award_kill_credit(target, killing_turret)
    return get_damage_accounting_service().award_kill_credit(target, killing_turret)
  end

  function service.award_visible_kill(turret)
    get_damage_accounting_service().award_visible_kill(turret)
  end

  function service.cleanup_target_damage()
    get_damage_accounting_service().cleanup_target_damage()
  end

  return service
end

return stats_module
