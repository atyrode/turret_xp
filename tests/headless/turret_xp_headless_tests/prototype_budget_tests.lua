local support = require("support")

local TEST_PREFIX = support.TEST_PREFIX
local assert_true = support.assert_true
local assert_eq = support.assert_eq
local assert_gt = support.assert_gt
local assert_ge = support.assert_ge
local assert_near = support.assert_near
local create_turret = support.create_turret
local call = support.call

local tests = {}
function tests.run_prototype_budget_test()
  local budget = call("prototype_budget")
  assert_true(type(budget) == "table", "prototype budget was not exposed to the headless suite")
  assert_eq(budget.hidden_turret_variants, 12, "hidden turret variant budget changed")
  assert_eq(budget.bound_preview_items, 12, "bound preview item budget changed")
  assert_eq(budget.bound_preview_placeholders, 12, "bound preview placeholder budget changed")
  assert_eq(budget.label_panels, 0, "retired label display-panel prototypes were generated")
  assert_eq(budget.tracked_hidden_variant_total, 36, "tracked hidden prototype budget changed")
  log(
    TEST_PREFIX
      .. "prototype budget: hidden_turret_variants="
      .. tostring(budget.hidden_turret_variants)
      .. ", bound_preview_items="
      .. tostring(budget.bound_preview_items)
      .. ", bound_preview_placeholders="
      .. tostring(budget.bound_preview_placeholders)
      .. ", label_panels="
      .. tostring(budget.label_panels)
      .. ", tracked_hidden_variant_total="
      .. tostring(budget.tracked_hidden_variant_total)
  )
end

function tests.run_place_result_regression_test()
  local placement = call("placement_prototypes")
  assert_eq(placement.gun_turret_place_result, "gun-turret", "vanilla gun turret item no longer places the vanilla gun turret")
  assert_eq(
    placement.bound_turret_place_result,
    "turret-xp-bound-gun-turret-placeholder",
    "bound veteran turret item still points at the vanilla gun turret"
  )
  assert_true(placement.placeholder_exists, "bound veteran turret placeholder prototype does not exist")
  assert_eq(placement.sniper_bound_item, "turret-xp-bound-gun-turret-sniper", "sniper bound preview item was not generated")
  assert_eq(
    placement.sniper_bound_place_result,
    "turret-xp-bound-gun-turret-placeholder-sniper",
    "sniper bound preview item points at the wrong placeholder"
  )
  assert_gt(
    placement.sniper_bound_preview_range,
    placement.base_bound_preview_range,
    "sniper bound preview range did not exceed the base bound preview range"
  )
  assert_eq(placement.range_3_body_name, "gun-turret", "range ranks should no longer create a hidden body")
  assert_true(placement.range_3_body_exists, "range-rank fallback should be the vanilla gun turret")
  assert_eq(placement.health_2_body_name, "gun-turret", "health ranks should no longer create a hidden body")
  assert_true(placement.health_2_body_exists, "health-rank fallback should be the vanilla gun turret")
  assert_eq(placement.sniper_deadeye_body_name, "turret-xp-gun-turret-sniper-deadeye", "shared sub-specialization body name changed")
  assert_true(placement.sniper_deadeye_body_exists, "shared sub-specialization body prototype was not generated")
  assert_eq(
    placement.sniper_overwatch_range_3_body_name,
    "turret-xp-gun-turret-sniper-overwatch",
    "shared sub-specialization body name changed"
  )
  assert_true(placement.sniper_overwatch_range_3_body_exists, "shared sub-specialization body prototype was not generated")
  assert_eq(
    placement.invalid_sub_body_name,
    "turret-xp-gun-turret-machine_gun",
    "invalid sub-specialization should fall back to the parent specialization body"
  )
  assert_eq(
    placement.sniper_deadeye_bound_item,
    "turret-xp-bound-gun-turret-sniper-deadeye",
    "shared sub-specialization bound item name changed"
  )
  assert_eq(
    placement.sniper_deadeye_bound_place_result,
    "turret-xp-bound-gun-turret-placeholder-sniper-deadeye",
    "shared sub-specialization bound item points at the wrong placeholder"
  )
end

function tests.run_modded_base_range_variant_test(surface)
  local turret = create_turret(surface, { 12, -8 }, 20)
  local summary = call("install_core", turret, { level = 40 })
  assert_eq(summary.attack_range, 25, "headless data-updates range patch did not affect the base gun turret")

  summary = call("set_evolution", turret, {
    augments = {
      range = 1,
    },
  })
  assert_eq(summary.evolution.augments.range, nil, "retired range augment should be removed during normalization")
  assert_eq(summary.entity_name, "gun-turret", "retired range rank should not create a range variant")
  assert_eq(summary.attack_range, 25, "retired range rank should not change attack range")
end

function tests.run_turret_ammo_range_compat_test()
  local compat = call("ammo_range_compat", "firearm-magazine")
  assert_true(compat ~= nil, "ammo range compatibility summary is unavailable")
  assert_gt(compat.max_turret_xp_range, 30, "test fixture did not generate Turret XP ranges above the K2-style ammo cap")
  assert_true(compat.player and compat.player[1], "player ammo projectile range was not reported")
  assert_true(compat.turret and compat.turret[1], "turret ammo projectile range was not reported")
  assert_near(compat.player[1].max_range, 30, 0.0001, "non-turret ammo projectile range should keep the K2-style cap")
  assert_gt(compat.turret[1].max_range, 30, "turret ammo projectile range was not raised above the K2-style cap")
  assert_ge(
    compat.turret[1].minimum_effective_range,
    compat.max_turret_xp_range,
    "turret ammo projectile range should cover the highest generated Turret XP range even with range deviation"
  )
end

return tests
