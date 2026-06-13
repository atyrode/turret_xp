local support = require("support")

local assert_near = support.assert_near
local call = support.call

local tests = {}

function tests.run_stats_math_formula_test()
  local values = call("stats_formula_samples", {
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
  }, 800)

  assert_near(values.damage_multiplier, 2.8 * 1.10, 0.0001, "damage multiplier math changed")
  assert_near(values.crit_chance_fraction, (0.05 + 0.10) * 1.10, 0.0001, "crit chance math changed")
  assert_near(values.crit_damage_fraction, (0.50 + 0.10) * 1.8 * 1.25, 0.0001, "crit damage math changed")
  assert_near(values.double_shot_chance, 0.12 * 1.10, 0.0001, "double-shot chance math changed")
  assert_near(values.damage_resistance_fraction, 10 * 0.0025, 0.0001, "resistance math changed")
  assert_near(values.shield_on_hit_fraction, 4 * 0.04, 0.0001, "shield-on-hit math changed")
  assert_near(values.repair_base_per_second, 5 * 0.01 * 800, 0.0001, "repair base math changed")
  assert_near(values.capped_luck_chance, 0.95, 0.0001, "luck chance cap changed")
end

function tests.run_ammo_productivity_math_test()
  local values = call("stats_formula_samples", {
    evolution = {
      specialization = "machine_gun",
      base = {
        ammo_regen = 30,
      },
      augments = {},
    },
  })

  assert_near(values.ammo_productivity_fraction, 0.30 * 2.0, 0.0001, "ammo productivity multiplier math changed")
  assert_near(values.effective_ammo_productivity_fraction, 0.60 / 1.60, 0.0001, "effective productivity math changed")
  assert_near(values.ammo_recovery_per_minute, (0.60 / 1.60) * 100, 0.0001, "ammo recovery display math changed")
end

return tests
