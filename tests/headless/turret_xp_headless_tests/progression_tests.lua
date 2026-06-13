local support = require("support")

local assert_true = support.assert_true
local assert_eq = support.assert_eq
local assert_gt = support.assert_gt
local assert_near = support.assert_near
local list_count = support.list_count
local create_turret = support.create_turret
local require_turret_near = support.require_turret_near
local call = support.call

local tests = {}
function tests.run_evolution_body_test(surface)
  local turret = create_turret(surface, { 8, 0 }, 20)
  call("install_core", turret, { level = 40 })

  local summary = call("set_evolution", turret, {
    specialization = "sniper",
    base = {
      damage = 2,
      crit_chance = 4,
      crit_damage = 3,
    },
    augments = {
      repair = 1,
    },
  })

  assert_eq(summary.evolution.specialization, "sniper", "specialization did not persist")
  assert_eq(summary.evolution.augments.range, nil, "retired range augment rank should not persist")
  assert_eq(summary.entity_name, "turret-xp-gun-turret-sniper", "specialization did not swap to the expected turret body")
  assert_gt(summary.attack_range, 35, "sniper range multiplier did not affect real attack range")
end

function tests.run_specialization_secondary_multiplier_test(surface)
  local turret = create_turret(surface, { 14, 8 }, 20)
  local summary = call("install_core", turret, { level = 80 })
  assert_true(summary ~= nil, "failed to install core for specialization multiplier test")
  local base_cooldown = summary.attack_cooldown
  local base_damage_modifier = summary.attack_damage_modifier

  summary = call("set_evolution", turret, {
    specialization = "sniper",
    base = {
      crit_damage = 10,
    },
  })
  assert_near(summary.derived.crit_damage_fraction, 1.08, 0.0001, "sniper crit damage multiplier did not affect derived crit damage")

  turret = require_turret_near(surface, { x = 14, y = 8 }, "specialization multiplier turret not found after sniper body swap")
  summary = call("set_evolution", turret, {
    specialization = "sniper",
    sub_specialization = "sniper_deadeye",
    base = {
      crit_damage = 10,
    },
  })
  assert_eq(summary.evolution.sub_specialization, "sniper_deadeye", "sub-specialization did not persist")
  assert_eq(summary.entity_name, "turret-xp-gun-turret-sniper-deadeye", "sub-specialization did not swap to the expected turret body")
  assert_near(summary.derived.crit_chance_fraction, 0.10, 0.0001, "Deadeye crit chance bonus did not affect derived crit chance")
  assert_near(summary.derived.crit_damage_fraction, 1.35, 0.0001, "Deadeye crit damage multiplier did not combine with Sniper")
  assert_near(
    summary.attack_damage_modifier,
    base_damage_modifier * 2.8 * 1.10,
    0.0001,
    "Deadeye damage multiplier did not affect real turret damage modifier"
  )

  turret = require_turret_near(surface, { x = 14, y = 8 }, "sub-specialization turret not found after Deadeye body swap")
  summary = call("set_evolution", turret, {
    specialization = "sniper",
    sub_specialization = "sniper_overwatch",
  })
  assert_eq(summary.entity_name, "turret-xp-gun-turret-sniper-overwatch", "sub-specialization body name was not generated")
  assert_gt(summary.attack_range, 40, "Overwatch range multiplier did not affect real attack range")

  turret = require_turret_near(surface, { x = 14, y = 8 }, "sub-specialization turret not found after Overwatch body swap")
  summary = call("set_evolution", turret, {
    specialization = "machine_gun",
    sub_specialization = "sniper_deadeye",
  })
  assert_eq(summary.evolution.sub_specialization, nil, "invalid sub-specialization parent was not cleared")

  turret = require_turret_near(surface, { x = 14, y = 8 }, "specialization multiplier turret not found after sniper body swap")
  summary = call("set_evolution", turret, {
    specialization = "machine_gun",
    base = {
      ammo_regen = 3,
    },
  })
  assert_near(
    summary.derived.ammo_productivity_fraction,
    0.06,
    0.0001,
    "machine gun ammo productivity multiplier did not affect derived ammo productivity"
  )
  assert_near(
    summary.derived.effective_ammo_productivity_fraction,
    0.06 / 1.06,
    0.0001,
    "machine gun ammo productivity multiplier did not affect effective diminishing-return productivity"
  )

  turret = require_turret_near(surface, { x = 14, y = 8 }, "specialization multiplier turret not found after machine gun body swap")
  summary = call("set_evolution", turret, {
    specialization = "bulwark",
    augments = {
      repair = 2,
    },
  })
  assert_near(
    summary.derived.repair_per_second,
    summary.max_health * 0.01 * 2 * 2.5,
    0.0001,
    "bulwark regeneration multiplier did not affect max-health-based repair"
  )
  assert_gt(summary.derived.repair_per_second, 1, "max-health-based regeneration should be stronger than the old flat value on Bulwark")

  turret = require_turret_near(surface, { x = 14, y = 8 }, "specialization multiplier turret not found after bulwark body swap")
  summary = call("set_evolution", turret, {
    specialization = "brawler",
  })
  assert_near(summary.derived.lifesteal_rate, 0.10, 0.0001, "brawler did not expose its innate lifesteal")
  assert_near(summary.attack_cooldown, base_cooldown * 2, 0.0001, "brawler cooldown multiplier did not reduce fire rate to x0.5")
  assert_near(summary.attack_damage_modifier, base_damage_modifier * 3, 0.0001, "brawler damage multiplier did not reduce to x3")
end

function tests.run_resistance_test(surface)
  local turret_position = { x = 16, y = 12 }
  local turret = create_turret(surface, turret_position, 10)
  local summary = call("install_core", turret, { level = 80 })
  assert_true(summary ~= nil, "failed to install core for resistance test")

  summary = call("set_evolution", turret, {
    base = {
      resistance = 40,
    },
  })
  assert_near(summary.derived.damage_resistance_fraction, 0.10, 0.0001, "resistance rank did not produce expected mitigation")

  turret = require_turret_near(surface, turret_position, "resistance test turret not found")
  local before = turret.health
  local applied = turret.damage(100, game.forces.enemy, "physical")
  assert_true(applied and applied > 0, "resistance test did not apply incoming damage")
  assert_near(turret.health, before - (applied * 0.90), 0.05, "resistance did not refund expected non-lethal damage")

  summary = call("set_evolution", turret, {
    base = {
      resistance = 400,
    },
  })
  assert_eq(summary.evolution.base.resistance, 240, "resistance rank did not cap at max rank")
  assert_near(summary.derived.damage_resistance_fraction, 0.60, 0.0001, "resistance cap did not produce expected mitigation")
end

function tests.run_level_zero_points_test(surface)
  local turret = create_turret(surface, { 10, -12 }, 10)
  local summary = call("install_core", turret, {})
  assert_eq(summary.level, 0, "new Veteran Cores should start at level 0")
  assert_eq(summary.evolution.available_core_points, 0, "level 0 core should have zero available core points")

  summary = call("set_profile", turret, { level = 10 })
  assert_eq(summary.level, 10, "test setup did not create a level 10 core")
  assert_eq(summary.evolution.available_core_points, 10, "level 10 core should have ten available core points")
end

function tests.run_shield_test(surface)
  local turret_position = { x = 42, y = 0 }
  local turret = create_turret(surface, turret_position, 10)
  local summary = call("install_core", turret, { level = 25 })
  assert_true(summary ~= nil, "failed to install core for shield test")

  summary = call("set_evolution", turret, {
    base = {
      shield = 4,
    },
  })
  assert_eq(summary.entity_name, "gun-turret", "shield rank should not swap to a health variant")
  assert_eq(summary.max_health, 400, "shield rank should not increase real max health")
  assert_eq(summary.evolution.base.shield, 4, "shield rank did not persist in base upgrade state")
  assert_eq(summary.derived.shield_capacity, 40, "shield capacity did not scale with rank")
  assert_eq(summary.shield, 0, "new shield ranks should not refill current shield")

  call("age_shield_damage", turret, 60 * 6)
  call("apply_shield_recharge", 5)
  summary = call("get_state", turret)
  assert_near(summary.shield, 0.5, 0.001, "shield should recharge in small fractional ticks")

  call("apply_shield_recharge", 60 * 10)
  summary = call("get_state", turret)
  assert_eq(summary.shield, 40, "shield did not recharge to the new capacity")

  turret = require_turret_near(surface, turret_position, "shield test turret not found")
  local before_health = turret.health
  local applied = turret.damage(24, game.forces.enemy, "physical")
  assert_true(applied and applied > 0, "shield test did not apply incoming damage")
  summary = call("get_state", turret)
  assert_eq(summary.shield, 16, "shield did not absorb incoming damage before HP")
  assert_near(turret.health, before_health, 0.05, "shielded damage should not reduce HP while shield remains")
  assert_true(summary.shield_bar_valid, "shield damage did not create the in-world shield bar")
  assert_true(summary.shield_bar_fill_valid, "partially filled shield should render a shield fill")
  assert_eq(summary.shield_bar_segment_count, 9, "shield bar should render as nine pips")
  assert_eq(summary.shield_bar_filled_segments, 4, "40% shield should display four whole shield pips")

  applied = turret.damage(20, game.forces.enemy, "physical")
  assert_true(applied and applied > 0, "shield spillover test did not apply incoming damage")
  summary = call("get_state", turret)
  assert_eq(summary.shield, 0, "shield should be empty after absorbing remaining capacity")
  assert_near(turret.health, before_health - 4, 0.05, "only damage beyond shield should reach HP")
  assert_true(summary.shield_bar_valid, "empty shield should keep its in-world bar visible during recharge delay")
  assert_eq(summary.shield_bar_fill_valid, false, "empty shield should not render a filled shield segment")
  assert_eq(summary.shield_bar_segment_count, 9, "empty shield should keep the nine-pip shield bar visible")
  assert_eq(summary.shield_bar_filled_segments, 0, "empty shield should display zero filled shield pips")

  call("age_shield_damage", turret, 60 * 6)
  applied = turret.damage(1, game.forces.enemy, "physical")
  assert_true(applied and applied > 0, "empty-shield hit did not apply incoming damage")
  call("apply_shield_recharge", 60)
  summary = call("get_state", turret)
  assert_eq(summary.shield, 0, "shield should not recharge while the turret is still being hit")

  call("age_shield_damage", turret, 60 * 6)
  call("apply_shield_recharge", 5)
  summary = call("get_state", turret)
  assert_gt(summary.shield, 0, "shield did not start recharging after its delay")

  summary = call("set_evolution", turret, {
    base = {
      shield = 6,
    },
  })
  assert_eq(summary.derived.shield_capacity, 60, "shield capacity did not increase after respec")
  assert_near(summary.shield, 0.5, 0.001, "increasing shield capacity should keep current shield value")

  summary = call("set_profile", turret, { shield = 25 })
  assert_eq(summary.shield, 25, "test setup did not set current shield under increased capacity")
  summary = call("set_evolution", turret, {
    base = {
      shield = 2,
    },
  })
  assert_eq(summary.derived.shield_capacity, 20, "shield capacity did not decrease after respec")
  assert_eq(summary.shield, 20, "decreasing shield capacity should clamp current shield to the new maximum")
end

function tests.run_ammo_productivity_test(surface)
  local turret_position = { x = 44, y = 0 }
  local turret = create_turret(surface, turret_position, 10)
  local summary = call("install_core", turret, { level = 80 })
  assert_true(summary ~= nil, "failed to install core for ammo productivity test")

  summary = call("set_evolution", turret, {
    base = {
      ammo_regen = 25,
    },
  })
  assert_eq(summary.evolution.base.ammo_regen, 25, "ammo productivity rank did not persist in evolution state")
  assert_near(summary.derived.ammo_productivity_fraction, 0.25, 0.0001, "ammo productivity did not derive expected percent")
  assert_near(
    summary.derived.effective_ammo_productivity_fraction,
    0.2,
    0.0001,
    "ammo productivity did not derive expected effective percent"
  )

  local inventory = turret.get_inventory(defines.inventory.turret_ammo)
  assert_true(inventory ~= nil and inventory.valid, "ammo productivity test turret had no ammo inventory")
  local ammo_stack = inventory[1]
  assert_true(ammo_stack and ammo_stack.valid_for_read, "ammo productivity test setup did not expose a loaded magazine")
  call("remember_loaded_ammo", turret)
  local expected_count = ammo_stack.count
  local expected_magazine_ammo = ammo_stack.ammo
  assert_eq(expected_count, 10, "ammo productivity test setup did not load expected magazine stack count")
  assert_eq(expected_magazine_ammo, 10, "ammo productivity test setup did not start with a full magazine")

  for shot = 1, 4 do
    ammo_stack.drain_ammo(1)
    expected_magazine_ammo = expected_magazine_ammo - 1
    summary = call("apply_ammo_productivity", turret)
    assert_near(summary.ammo_productivity_progress, shot * 0.2, 0.0001, "ammo productivity progress did not advance per spent round")
    assert_eq(ammo_stack.count, expected_count, "ammo productivity changed the loaded magazine stack count before the bar filled")
    assert_eq(ammo_stack.ammo, expected_magazine_ammo, "ammo productivity restored magazine ammo before the bar filled")
  end

  ammo_stack.drain_ammo(1)
  expected_magazine_ammo = expected_magazine_ammo - 1
  summary = call("apply_ammo_productivity", turret)
  expected_magazine_ammo = expected_magazine_ammo + 1
  assert_near(summary.ammo_productivity_progress, 0, 0.0001, "ammo productivity did not consume a full bar")
  assert_eq(ammo_stack.count, expected_count, "ammo productivity should not create or remove magazine items")
  assert_eq(ammo_stack.ammo, expected_magazine_ammo, "ammo productivity did not restore one bullet inside the current magazine at 100%")

  summary = call("set_evolution", turret, {
    base = {
      ammo_regen = 200,
    },
  })
  assert_near(summary.derived.ammo_productivity_fraction, 2, 0.0001, "ammo productivity should keep its uncapped derived percent")
  assert_near(
    summary.derived.effective_ammo_productivity_fraction,
    2 / 3,
    0.0001,
    "over-100 ammo productivity should use diminishing returns"
  )
  call("set_profile", turret, { ammo_productivity_progress = 0 })
  ammo_stack.ammo = 10
  call("remember_loaded_ammo", turret)
  ammo_stack.drain_ammo(1)
  summary = call("apply_ammo_productivity", turret)
  assert_near(summary.ammo_productivity_progress, 2 / 3, 0.0001, "over-100 ammo productivity should not refill every shot")
  assert_eq(ammo_stack.count, expected_count, "over-100 ammo productivity should not create magazine items")
  assert_eq(ammo_stack.ammo, 9, "over-100 ammo productivity should still spend ammo sometimes")

  ammo_stack.drain_ammo(1)
  summary = call("apply_ammo_productivity", turret)
  assert_near(
    summary.ammo_productivity_progress,
    1 / 3,
    0.0001,
    "over-100 ammo productivity should keep fractional progress after a refill"
  )
  assert_eq(ammo_stack.ammo, 9, "over-100 ammo productivity should refill only one magazine ammo after two shots")

  ammo_stack.drain_ammo(1)
  summary = call("apply_ammo_productivity", turret)
  assert_near(summary.ammo_productivity_progress, 0, 0.0001, "over-100 ammo productivity should consume exact full bars")
  assert_eq(ammo_stack.ammo, 9, "over-100 ammo productivity should still have net ammo cost over repeated shots")
end

function tests.run_targeted_reset_test(surface)
  local turret_position = { x = 36, y = 8 }
  local turret = create_turret(surface, turret_position, 10)
  local summary = call("install_core", turret, { level = 50 })
  assert_true(summary ~= nil, "failed to install core for targeted reset test")

  summary = call("set_evolution", turret, {
    base = {
      damage = 3,
      resistance = 4,
    },
    augments = {
      repair = 2,
      luck = 1,
    },
    specialization = "sniper",
    elements = { "fire", "explosive" },
    element_mastery = {
      fire = {
        rank = 2,
        delivered = 0,
        fuel = 3,
        burn_remaining = 0,
      },
      explosive = {
        rank = 2,
        delivered = 0,
        fuel = 4,
        burn_remaining = 0,
      },
    },
  })
  assert_eq(summary.evolution.base.damage, 3, "test setup did not apply base ranks")
  assert_eq(summary.evolution.augments.repair, 2, "test setup did not apply augment regeneration ranks")
  assert_eq(summary.evolution.augments.luck, 1, "test setup did not apply augment ranks")
  assert_eq(summary.evolution.specialization, "sniper", "test setup did not apply specialization")

  turret = require_turret_near(surface, turret_position, "targeted reset turret not found after setup body swap")
  summary = call("reset_evolution_section", turret, "base")
  assert_eq(summary.evolution.base.damage or 0, 0, "base reset did not clear damage ranks")
  assert_eq(summary.evolution.augments.repair, 2, "base reset incorrectly changed regeneration augment ranks")
  assert_eq(summary.evolution.augments.luck, 1, "base reset incorrectly changed augments")
  assert_eq(summary.evolution.specialization, "sniper", "base reset incorrectly changed specialization")

  turret = require_turret_near(surface, turret_position, "targeted reset turret not found after base reset")
  summary = call("reset_evolution_section", turret, "augments")
  assert_eq(summary.evolution.augments.luck or 0, 0, "augment reset did not clear augment ranks")
  assert_eq(summary.evolution.augments.repair or 0, 0, "augment reset did not clear regeneration augment ranks")
  assert_eq(summary.evolution.specialization, "sniper", "augment reset incorrectly changed specialization")
  assert_eq(summary.evolution.elements[1], "fire", "augment reset incorrectly changed first element")

  turret = require_turret_near(surface, turret_position, "targeted reset turret not found after augment reset")
  summary = call("reset_evolution_section", turret, "specialization")
  assert_eq(summary.evolution.specialization, nil, "specialization reset did not clear specialization")
  assert_eq(summary.evolution.elements[1], "fire", "specialization reset incorrectly changed elements")

  turret = require_turret_near(surface, turret_position, "targeted reset turret not found after specialization reset")
  summary = call("reset_evolution_section", turret, "element-slot", 2)
  assert_eq(summary.evolution.elements[1], "fire", "second element reset incorrectly cleared first element")
  assert_eq(summary.evolution.elements[2], nil, "second element reset did not clear slot 2")
  assert_true(summary.evolution.element_mastery.fire ~= nil, "second element reset incorrectly removed first element mastery")
  assert_eq(
    list_count(summary.evolution.unique_elements, "explosive"),
    0,
    "second element reset did not remove explosive from active elements"
  )
  assert_eq(summary.evolution.element_mastery.explosive.rank or 0, 0, "second element reset did not clear explosive mastery rank")
  assert_eq(summary.evolution.element_mastery.explosive.fuel or 0, 0, "second element reset did not clear explosive fuel")

  turret = require_turret_near(surface, turret_position, "targeted reset turret not found after second element reset")
  summary = call("reset_evolution_section", turret, "element-slot", 1)
  assert_eq(summary.evolution.elements[1], nil, "first element reset did not clear slot 1")
  assert_eq(summary.evolution.elements[2], nil, "first element reset did not clear slot 2")
  assert_eq(#summary.evolution.unique_elements, 0, "first element reset did not clear active elements")
  assert_eq(summary.evolution.element_mastery.fire.rank or 0, 0, "first element reset did not clear fire mastery rank")
  assert_eq(summary.evolution.element_mastery.explosive.rank or 0, 0, "first element reset did not clear explosive mastery rank")
end

function tests.run_full_evolution_reset_test(surface)
  local turret_position = { x = 48, y = 8 }
  local turret = create_turret(surface, turret_position, 10)
  local summary = call("install_core", turret, {
    level = 55,
    kills = 12,
    damage = 3456,
    xp = 42,
    total_xp = 12345,
    custom_name = "Reset Keeper",
  })
  assert_true(summary ~= nil, "failed to install core for full evolution reset test")

  summary = call("set_evolution", turret, {
    base = {
      damage = 3,
      resistance = 4,
      crit_chance = 4,
      crit_damage = 5,
    },
    augments = {
      repair = 2,
      luck = 2,
    },
    specialization = "sniper",
    elements = { "fire", "explosive" },
    element_mastery = {
      fire = {
        rank = 3,
        delivered = 12,
        fuel = 5,
        burn_remaining = 30,
      },
      explosive = {
        rank = 2,
        delivered = 8,
        fuel = 4,
        burn_remaining = 20,
      },
    },
    element_project = {
      slot = 2,
      element = "electric",
      delivered = {
        battery = 3,
      },
    },
  })
  assert_eq(summary.evolution.base.damage, 3, "full reset setup did not apply base ranks")
  assert_eq(summary.evolution.augments.luck, 2, "full reset setup did not apply augment ranks")
  assert_eq(summary.evolution.specialization, "sniper", "full reset setup did not apply specialization")

  turret = require_turret_near(surface, turret_position, "full reset turret not found after setup body swap")
  summary = call("reset_evolution", turret)
  assert_eq(summary.level, 55, "full reset should keep core level")
  assert_eq(summary.kills, 12, "full reset should keep kill history")
  assert_eq(summary.damage, 3456, "full reset should keep damage history")
  assert_eq(summary.custom_name, "Reset Keeper", "full reset should keep custom name")
  assert_eq(summary.evolution.base.damage or 0, 0, "full reset did not clear base ranks")
  assert_eq(summary.evolution.base.crit_chance or 0, 0, "full reset did not clear crit ranks")
  assert_eq(summary.evolution.base.resistance or 0, 0, "full reset did not clear resistance ranks")
  assert_eq(summary.evolution.augments.luck or 0, 0, "full reset did not clear augment ranks")
  assert_eq(summary.evolution.specialization, nil, "full reset did not clear specialization")
  assert_eq(summary.evolution.elements[1], nil, "full reset did not clear first element")
  assert_eq(summary.evolution.elements[2], nil, "full reset did not clear second element")
  assert_eq(#summary.evolution.unique_elements, 0, "full reset did not clear active elements")
  assert_eq(summary.evolution.element_project, nil, "full reset did not clear active element project")
  assert_eq(summary.evolution.element_mastery.fire.rank or 0, 0, "full reset did not clear fire mastery")
  assert_eq(summary.evolution.element_mastery.fire.fuel or 0, 0, "full reset did not clear fire fuel")
  assert_eq(summary.evolution.element_mastery.explosive.rank or 0, 0, "full reset did not clear explosive mastery")
  assert_eq(summary.evolution.element_mastery.explosive.fuel or 0, 0, "full reset did not clear explosive fuel")
end

return tests
