local support = require("support")

local progression_definitions = require("scripts.control.progression_definitions")
local stats_math = require("scripts.control.stats_math")

local assert_near = support.assert_near

local tests = {}

local function ensure_evolution_state(state)
  state.evolution = state.evolution or {}
  local evolution = state.evolution
  evolution.base = evolution.base or {}
  evolution.augments = evolution.augments or {}
  evolution.elements = evolution.elements or {}
  evolution.element_mastery = evolution.element_mastery or {}
  return evolution
end

local function get_base_rank(state, upgrade_id)
  return ensure_evolution_state(state).base[upgrade_id] or 0
end

local function get_augment_rank(state, augment_id)
  return ensure_evolution_state(state).augments[augment_id] or 0
end

local function new_service()
  return stats_math.new({
    SPECIALIZATION_BY_ID = progression_definitions.specialization_by_id,
    SUB_SPECIALIZATION_BY_ID = progression_definitions.sub_specialization_by_id,
    ensure_evolution_state = ensure_evolution_state,
    get_augment_rank = get_augment_rank,
    get_base_rank = get_base_rank,
    REPAIR_MAX_HEALTH_FRACTION_PER_RANK = progression_definitions.repair_max_health_fraction_per_rank,
    AMMO_PRODUCTIVITY_PER_RANK = progression_definitions.ammo_productivity_per_rank,
    SHIELD_ON_HIT_FRACTION_PER_RANK = progression_definitions.shield_on_hit_fraction_per_rank,
    RESISTANCE_MAX = progression_definitions.resistance_max,
    RESISTANCE_PER_RANK = progression_definitions.resistance_per_rank,
  })
end

function tests.run_stats_math_formula_test()
  local service = new_service()
  local state = {
    evolution = {
      specialization = "sniper",
      sub_specialization = "sniper_deadeye",
      base = {
        ammo_regen = 25,
        crit_chance = 20,
        crit_damage = 10,
        resistance = 10,
      },
      augments = {
        double_shot = 3,
        luck = 2,
        repair = 5,
        siphon = 4,
      },
    },
  }

  assert_near(service.get_specialization_multiplier(state, "damage_multiplier"), 2.8 * 1.10, 0.0001, "damage multiplier math changed")
  assert_near(service.get_crit_chance_fraction(state), (0.05 + 0.10) * 1.10, 0.0001, "crit chance math changed")
  assert_near(service.get_crit_damage_fraction(state), (0.50 + 0.10) * 1.8 * 1.25, 0.0001, "crit damage math changed")
  assert_near(service.get_double_shot_chance(state), 0.12 * 1.10, 0.0001, "double-shot chance math changed")
  assert_near(service.get_damage_resistance_fraction(state), 10 * 0.0025, 0.0001, "resistance math changed")
  assert_near(service.get_shield_on_hit_fraction(state), 4 * 0.04, 0.0001, "shield-on-hit math changed")
  assert_near(service.get_repair_base_per_second_for_health(state, 800), 5 * 0.01 * 800, 0.0001, "repair base math changed")
  assert_near(service.apply_luck_to_chance(state, 2), 0.95, 0.0001, "luck chance cap changed")
end

function tests.run_ammo_productivity_math_test()
  local service = new_service()
  local state = {
    evolution = {
      specialization = "machine_gun",
      base = {
        ammo_regen = 30,
      },
      augments = {},
    },
  }

  assert_near(service.get_ammo_productivity_fraction(state), 0.30 * 2.0, 0.0001, "ammo productivity multiplier math changed")
  assert_near(service.get_effective_ammo_productivity_fraction(state), 0.60 / 1.60, 0.0001, "effective productivity math changed")
  assert_near(service.get_ammo_recovery_per_minute(state), (0.60 / 1.60) * 100, 0.0001, "ammo recovery display math changed")
end

return tests
