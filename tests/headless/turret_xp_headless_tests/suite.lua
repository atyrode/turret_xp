local support = require("support")

local bound_turret_tests = require("bound_turret_tests")
local combat_tests = require("combat_tests")
local compat_tests = require("compat_tests")
local feeder_tests = require("feeder_tests")
local gui_support_tests = require("gui_support_tests")
local migration_tests = require("migration_tests")
local progression_tests = require("progression_tests")
local prototype_budget_tests = require("prototype_budget_tests")
local stats_math_tests = require("stats_math_tests")

local function run_immediate_tests()
  local surface = support.get_surface()
  support.clear_test_area(surface)
  support.assert_true(remote.interfaces[support.IFACE] ~= nil, "Turret XP test remote interface is unavailable")

  gui_support_tests.run_layout_constants_test()
  gui_support_tests.run_gui_support_samples_test()
  compat_tests.run_compat_samples_test(surface)
  combat_tests.run_combat_budget_samples_test(surface)
  migration_tests.run_legacy_migration_test()
  stats_math_tests.run_stats_math_formula_test()
  stats_math_tests.run_ammo_productivity_math_test()
  prototype_budget_tests.run_prototype_budget_test()
  prototype_budget_tests.run_place_result_regression_test()
  gui_support_tests.run_profile_label_test(surface)
  gui_support_tests.run_gui_action_dispatch_test(surface)
  gui_support_tests.run_inventory_core_picker_test(surface)
  prototype_budget_tests.run_modded_base_range_variant_test(surface)
  prototype_budget_tests.run_turret_ammo_range_compat_test()
  progression_tests.run_level_zero_points_test(surface)
  progression_tests.run_shield_test(surface)
  progression_tests.run_ammo_productivity_test(surface)
  progression_tests.run_evolution_body_test(surface)
  progression_tests.run_specialization_secondary_multiplier_test(surface)
  progression_tests.run_resistance_test(surface)
  feeder_tests.run_feeder_material_progress_test(surface)
  feeder_tests.run_feeder_contract_test(surface)
  feeder_tests.run_dual_element_feeder_test(surface)
  progression_tests.run_targeted_reset_test(surface)
  progression_tests.run_full_evolution_reset_test(surface)
  combat_tests.run_damage_accounting_test(surface)
  bound_turret_tests.run_bound_turret_test(surface)
  bound_turret_tests.run_bound_turret_mining_ammo_conservation_test(surface)
  combat_tests.setup_combat_test(surface)
  combat_tests.setup_status_damage_test(surface)
end

return {
  pass_tick = support.PASS_TICK,
  test_prefix = support.TEST_PREFIX,
  run_immediate_tests = run_immediate_tests,
  check_deferred_tests = function()
    combat_tests.check_combat_test(support.get_surface())
    combat_tests.check_status_damage_test(support.get_surface())
  end,
}
