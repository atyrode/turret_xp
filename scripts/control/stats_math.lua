local stats_math = {}

function stats_math.new(deps)
  local service = {}
  local SPECIALIZATION_BY_ID = deps.SPECIALIZATION_BY_ID
  local SUB_SPECIALIZATION_BY_ID = deps.SUB_SPECIALIZATION_BY_ID
  local ensure_evolution_state = deps.ensure_evolution_state
  local get_augment_rank = deps.get_augment_rank
  local get_base_rank = deps.get_base_rank
  local REPAIR_MAX_HEALTH_FRACTION_PER_RANK = deps.REPAIR_MAX_HEALTH_FRACTION_PER_RANK
  local AMMO_PRODUCTIVITY_PER_RANK = deps.AMMO_PRODUCTIVITY_PER_RANK
  local SHIELD_ON_HIT_FRACTION_PER_RANK = deps.SHIELD_ON_HIT_FRACTION_PER_RANK
  local RESISTANCE_MAX = deps.RESISTANCE_MAX
  local RESISTANCE_PER_RANK = deps.RESISTANCE_PER_RANK

  function service.get_specialization(state)
    if not state then
      return nil
    end

    local specialization_id = ensure_evolution_state(state).specialization
    return specialization_id and SPECIALIZATION_BY_ID[specialization_id] or nil
  end

  function service.get_sub_specialization(state)
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

  function service.get_specialization_multiplier(state, field)
    local specialization = service.get_specialization(state)
    if not field then
      return 1
    end

    local multiplier = specialization and (tonumber(specialization[field]) or 1) or 1
    local sub_specialization = service.get_sub_specialization(state)
    if sub_specialization then
      multiplier = multiplier * (tonumber(sub_specialization[field]) or 1)
    end

    return multiplier
  end

  function service.get_sub_specialization_flat_bonus(state, field)
    local sub_specialization = service.get_sub_specialization(state)
    return sub_specialization and (tonumber(sub_specialization[field]) or 0) or 0
  end

  function service.get_repair_base_per_second_for_health(state, reference_health)
    return get_augment_rank(state, "repair") * REPAIR_MAX_HEALTH_FRACTION_PER_RANK * reference_health
  end

  function service.get_repair_per_second_for_health(state, reference_health)
    return service.get_repair_base_per_second_for_health(state, reference_health)
      * service.get_specialization_multiplier(state, "repair_multiplier")
  end

  function service.get_ammo_productivity_fraction(state)
    return get_base_rank(state, "ammo_regen")
      * AMMO_PRODUCTIVITY_PER_RANK
      * service.get_specialization_multiplier(state, "ammo_recovery_multiplier")
  end

  function service.get_effective_ammo_productivity_fraction(state)
    local raw = math.max(0, service.get_ammo_productivity_fraction(state))
    if raw <= 0 then
      return 0
    end

    return raw / (raw + 1)
  end

  function service.get_ammo_recovery_per_minute(state)
    return service.get_effective_ammo_productivity_fraction(state) * 100
  end

  function service.get_shield_on_hit_fraction(state)
    return get_augment_rank(state, "siphon") * SHIELD_ON_HIT_FRACTION_PER_RANK
  end

  function service.get_lifesteal_rate(state)
    local specialization = service.get_specialization(state)
    return specialization and (tonumber(specialization.lifesteal_fraction) or 0) or 0
  end

  function service.get_damage_resistance_fraction(state)
    return math.min(
      RESISTANCE_MAX,
      (get_base_rank(state, "resistance") * RESISTANCE_PER_RANK) + service.get_sub_specialization_flat_bonus(state, "resistance_flat")
    )
  end

  function service.get_crit_damage_multiplier(state)
    return service.get_specialization_multiplier(state, "crit_damage_multiplier")
  end

  function service.get_crit_damage_fraction(state)
    return (0.50 + (get_base_rank(state, "crit_damage") * 0.01)) * service.get_crit_damage_multiplier(state)
  end

  function service.get_crit_chance_fraction(state)
    return service.apply_luck_to_chance(
      state,
      (get_base_rank(state, "crit_chance") * 0.0025) + service.get_sub_specialization_flat_bonus(state, "crit_chance_flat")
    )
  end

  function service.get_double_shot_chance(state)
    return service.apply_luck_to_chance(
      state,
      (get_augment_rank(state, "double_shot") * 0.04) + service.get_sub_specialization_flat_bonus(state, "double_shot_chance_flat")
    )
  end

  function service.get_crit_damage_formula_values(state)
    return {
      base = 50,
      additive = get_base_rank(state, "crit_damage"),
      multiplier = service.get_crit_damage_multiplier(state),
      total = service.get_crit_damage_fraction(state) * 100,
    }
  end

  function service.get_luck_multiplier(state)
    return 1 + (get_augment_rank(state, "luck") * 0.05)
  end

  function service.apply_luck_to_chance(state, chance)
    return math.min(0.95, math.max(0, (chance or 0) * service.get_luck_multiplier(state)))
  end

  return service
end

return stats_math
