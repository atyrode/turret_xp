local support = require("support")

local assert_true = support.assert_true
local assert_eq = support.assert_eq
local assert_gt = support.assert_gt
local assert_near = support.assert_near
local create_turret = support.create_turret
local find_turret_near = support.find_turret_near
local require_turret_near = support.require_turret_near
local call = support.call

local tests = {}
function tests.run_combat_budget_samples_test(surface)
  local sample = call("combat_budget_samples", surface)
  assert_true(sample ~= nil, "combat budget sample did not return")
  assert_eq(
    sample.descriptors.elements.fire.direct_damage_multiplier,
    0.10,
    "Fire descriptor did not expose the current direct damage multiplier"
  )
  assert_eq(
    sample.descriptors.elements.electric.arc_damage_multiplier,
    0.25,
    "Electric descriptor did not expose the current arc damage multiplier"
  )
  assert_eq(
    sample.descriptors.combos.stormfire.damage_multiplier,
    0.15,
    "Stormfire descriptor did not expose the current combo damage multiplier"
  )
  assert_eq(sample.accepted_lines, sample.limits.render_lines_per_surface_tick, "render line budget did not cap accepted visual lines")
  assert_eq(sample.skipped.render_lines, 2, "render line budget did not track skipped visual lines")
  assert_eq(sample.accepted_status_ticks, sample.limits.status_effect_ticks_per_tick, "status tick budget did not cap accepted status work")
  assert_eq(sample.skipped.status_effect_ticks, 2, "status tick budget did not track skipped status work")
end

function tests.run_damage_accounting_test(surface)
  local first_turret = create_turret(surface, { 42, 0 }, 0)
  local second_turret = create_turret(surface, { 44, 0 }, 0)
  call("install_core", first_turret, {
    custom_name = "Partial Credit A",
  })
  call("install_core", second_turret, {
    custom_name = "Partial Credit B",
  })

  local target = surface.create_entity({
    name = "small-biter",
    position = { 46, 0 },
    force = "enemy",
    raise_built = false,
  })
  assert_true(target and target.valid, "failed to create damage accounting target")

  local max_health = target.health or 15
  local recorded = call("record_damage_contribution", target, first_turret, 4, max_health - 4)
  assert_eq(recorded.target_entry_count, 1, "first damage contribution did not create target accounting")
  recorded = call("record_damage_contribution", target, second_turret, 6, max_health - 10)
  assert_eq(recorded.target_entry_count, 1, "second damage contribution created duplicate target accounting")

  local awarded = call("award_recorded_kill_credit", target)
  assert_eq(awarded.credited_unit_number, second_turret.unit_number, "kill credit did not pick the highest-damage contributor")
  assert_eq(awarded.target_entry_count, 0, "target damage accounting was not cleared after kill credit award")

  local first_summary = call("get_state", first_turret)
  local second_summary = call("get_state", second_turret)
  assert_near(first_summary.kill_credit, 0.4, 0.0001, "first contributor did not receive proportional kill credit")
  assert_near(second_summary.kill_credit, 0.6, 0.0001, "second contributor did not receive proportional kill credit")
  assert_eq(first_summary.kills, 0, "lower-damage contributor incorrectly received the visible kill")
  assert_eq(second_summary.kills, 1, "highest-damage contributor did not receive the visible kill")

  pcall(function()
    target.destroy()
  end)
end

function tests.setup_combat_test(surface)
  local turret = create_turret(surface, { -20, 0 }, 100)
  turret.destructible = false
  call("install_core", turret, {
    custom_name = "Combat",
    level = 1,
  })

  for index = 1, 5 do
    local biter = surface.create_entity({
      name = "small-biter",
      position = { -6 + index, 6 + (index * 0.5) },
      force = "enemy",
    })
    assert_true(biter and biter.valid, "failed to create combat test biter")
    biter.health = 1
  end

  storage.turret_xp_headless_tests.combat_position = { x = -20, y = 0 }
end

function tests.setup_status_damage_test(surface)
  local turret = create_turret(surface, { -30, 0 }, 10)
  local summary = call("install_core", turret, { level = 20 })
  assert_true(summary ~= nil, "failed to install core for status damage test")
  summary = call("set_evolution", turret, {
    specialization = "brawler",
  })
  assert_true(summary ~= nil, "failed to configure status damage test evolution")
  turret = require_turret_near(surface, { x = -30, y = 0 }, "status damage turret not found")
  turret.health = math.max(1, turret.health - 120)

  local biter = surface.create_entity({
    name = "big-biter",
    position = { -25, 0 },
    force = "enemy",
  })
  assert_true(biter and biter.valid, "failed to create status damage target")
  biter.health = 1000

  summary = call("schedule_status_damage", turret, biter, 80, "poison", 4 * 60, 60)
  assert_true(summary.status_effect_count > 0, "status damage did not register an active effect")
  storage.turret_xp_headless_tests.status_position = { x = -30, y = 0 }
  storage.turret_xp_headless_tests.status_start_health = turret.health
end

function tests.check_combat_test(surface)
  local position = storage.turret_xp_headless_tests.combat_position
  local turret = find_turret_near(surface, position)
  assert_true(turret ~= nil, "combat test turret disappeared")
  local summary = call("get_state", turret)
  assert_true(summary ~= nil, "combat test turret lost its core")
  assert_gt(summary.damage, 0, "combat damage was not tracked")
  assert_gt(summary.total_xp, 0, "combat XP did not increase")
  assert_gt(summary.kills, 0, "combat kills were not tracked")
end

function tests.check_status_damage_test(surface)
  local position = storage.turret_xp_headless_tests.status_position
  local turret = find_turret_near(surface, position)
  assert_true(turret ~= nil, "status damage test turret disappeared")
  local summary = call("get_state", turret)
  assert_true(summary ~= nil, "status damage test turret lost its core")
  assert_gt(summary.damage, 0, "delayed status damage was not tracked as turret damage")
  assert_gt(summary.xp_damage, 0, "delayed status damage did not grant damage XP")
  assert_gt(turret.health, storage.turret_xp_headless_tests.status_start_health, "lifesteal did not apply to delayed status damage")
end

return tests
