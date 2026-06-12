local support = require("support")

local IFACE = support.IFACE
local TEST_PREFIX = support.TEST_PREFIX
local assert_true = support.assert_true
local assert_eq = support.assert_eq
local assert_gt = support.assert_gt
local assert_ge = support.assert_ge
local assert_near = support.assert_near
local list_count = support.list_count
local assert_contains = support.assert_contains
local get_surface = support.get_surface
local clear_test_area = support.clear_test_area
local inventory_count = support.inventory_count
local ground_item_count = support.ground_item_count
local find_ground_stack = support.find_ground_stack
local find_stack = support.find_stack
local create_turret = support.create_turret
local find_turret_near = support.find_turret_near
local require_turret_near = support.require_turret_near
local call = support.call

local function run_layout_constants_test()
  local layout = call("layout")
  assert_true(type(layout) == "table", "layout constants were not exposed to the headless suite")
  assert_eq(
    layout.left_column_width + layout.evolution_column_width + layout.column_spacing,
    layout.panel_width,
    "panel width must derive from the column model"
  )
  assert_eq(layout.evolution_scroll_width, layout.evolution_column_width, "Evolution scroll pane should own the full right-column viewport")
  assert_eq(
    layout.evolution_content_width,
    layout.evolution_scroll_width - 28,
    "Evolution content width must reserve the default scrollbar lane"
  )
  assert_eq(
    layout.evolution_section_width,
    layout.evolution_content_width - (layout.evolution_section_margin * 2),
    "Evolution section width must reserve visible side margins"
  )
  assert_eq(layout.evolution_inner_width, layout.evolution_section_width - 16, "Evolution inner rows must derive from section width")
  assert_eq(layout.evolution_card_inner_width, layout.evolution_inner_width - 28, "Element-card child rows must account for card padding")
  assert_true(layout.evolution_inner_width < layout.evolution_scroll_width, "Evolution rows must stay inside the scroll viewport")
  assert_true(layout.evolution_detail_width < layout.evolution_inner_width, "Evolution text details must stay capped inside inner rows")
end

local function run_gui_support_samples_test()
  local samples = call("gui_support_samples")
  assert_eq(samples.percent, "12.5%", "GUI percent formatting changed")
  assert_eq(samples.color, "0.58,0.82,0.38", "GUI rich color conversion changed")
  assert_eq(samples.rich_number, "[color=0.58,0.82,0.38]+5[/color]", "GUI rich number formatting changed")
  assert_eq(
    samples.rich_stat,
    "Damage [color=0.58,0.82,0.38]+5[/color] [color=0.58,0.82,0.38]x1.2[/color]",
    "GUI rich stat token formatting changed"
  )
end

local function run_compat_samples_test(surface)
  local turret = create_turret(surface, { -8, 0 }, 0)
  local samples = call("compat_samples", turret)
  assert_eq(samples.nil_read_fallback, "fallback", "compat safe_read fallback changed")
  assert_eq(samples.entity_quality, "normal", "compat quality read changed")
  assert_eq(samples.inventory_valid, true, "compat inventory read did not return the turret ammo inventory")
  assert_eq(samples.platform_inventory_present, false, "non-platform turret unexpectedly exposed a platform inventory")
  assert_eq(samples.base_prototype_exists, true, "compat prototype existence check missed the base turret")
  assert_eq(samples.missing_prototype_exists, false, "compat prototype existence check accepted a missing prototype")
  assert_eq(samples.diagnostics_enabled, true, "headless tests should run with compatibility diagnostics enabled")
end

local function run_combat_budget_samples_test(surface)
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

local function run_prototype_budget_test()
  local budget = call("prototype_budget")
  assert_true(type(budget) == "table", "prototype budget was not exposed to the headless suite")
  assert_eq(budget.hidden_turret_variants, 12, "hidden turret variant budget changed")
  assert_eq(budget.bound_preview_items, 12, "bound preview item budget changed")
  assert_eq(budget.bound_preview_placeholders, 12, "bound preview placeholder budget changed")
  assert_eq(budget.label_panels, 222, "label display-panel budget changed")
  assert_eq(budget.tracked_hidden_variant_total, 258, "tracked hidden prototype budget changed")
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

local function run_place_result_regression_test()
  local placement = call("placement_prototypes")
  assert_eq(placement.gun_turret_place_result, "gun-turret", "vanilla gun turret item no longer places the vanilla gun turret")
  assert_eq(
    placement.bound_turret_place_result,
    "turret-xp-bound-gun-turret-placeholder",
    "bound veteran turret item still points at the vanilla gun turret"
  )
  assert_true(placement.placeholder_exists, "bound veteran turret placeholder prototype does not exist")
  assert_eq(
    placement.sniper_bound_item,
    "turret-xp-bound-gun-turret-sniper",
    "sniper bound preview item was not generated"
  )
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

local function run_profile_label_test(surface)
  local turret = create_turret(surface, { 0, 0 }, 10)
  local summary = call("install_core", turret, {
    custom_name = "Alpha",
    show_name_label = true,
    label_color = { 1, 0.86, 0.46 },
    label_color_preset = "gold",
  })

  assert_true(summary ~= nil, "install_core returned no profile summary")
  assert_eq(summary.custom_name, "Alpha", "core custom name did not persist")
  assert_eq(summary.show_name_label, true, "show label flag did not persist")
  assert_eq(summary.label_color_preset, "gold", "preset label color did not persist")
  assert_true(summary.label_entity_valid or summary.name_render_valid, "enabled label did not create a label object")

  summary = call("set_profile", turret, {
    label_color = { 0.12, 0.34, 0.56 },
    label_color_preset = "custom",
  })
  assert_eq(summary.label_color_preset, "custom", "RGB label edit did not mark the profile as custom")
  assert_true(summary.label_entity_valid, "custom RGB label did not keep using a display-panel label entity")
  assert_eq(summary.name_render_valid, false, "custom RGB label fell back to rendering text")
end

local function run_evolution_body_test(surface)
  local turret = create_turret(surface, { 8, 0 }, 20)
  call("install_core", turret, { level = 40 })

  local summary = call("set_evolution", turret, {
    specialization = "sniper",
    base = {
      damage = 2,
      repair = 1,
      crit_chance = 4,
      crit_damage = 3,
    },
  })

  assert_eq(summary.evolution.specialization, "sniper", "specialization did not persist")
  assert_eq(summary.evolution.augments.range, nil, "retired range augment rank should not persist")
  assert_eq(summary.entity_name, "turret-xp-gun-turret-sniper", "specialization did not swap to the expected turret body")
  assert_gt(summary.attack_range, 35, "sniper range multiplier did not affect real attack range")
end

local function run_specialization_secondary_multiplier_test(surface)
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
  assert_near(summary.derived.crit_chance_fraction, 0.08, 0.0001, "Deadeye crit chance bonus did not affect derived crit chance")
  assert_near(summary.derived.crit_damage_fraction, 1.35, 0.0001, "Deadeye crit damage multiplier did not combine with Sniper")
  assert_near(
    summary.attack_damage_modifier,
    base_damage_modifier * 2.8 * 1.08,
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
    summary.derived.ammo_recovery_per_minute,
    6,
    0.0001,
    "machine gun ammo recovery multiplier did not affect derived ammo recovery"
  )

  turret = require_turret_near(surface, { x = 14, y = 8 }, "specialization multiplier turret not found after machine gun body swap")
  summary = call("set_evolution", turret, {
    specialization = "bulwark",
    base = {
      repair = 2,
    },
  })
  assert_near(
    summary.derived.repair_per_second,
    summary.max_health * 0.001 * 2 * 2.5,
    0.0001,
    "bulwark regeneration multiplier did not affect max-health-based repair"
  )
  assert_gt(summary.derived.repair_per_second, 1, "max-health-based regeneration should be stronger than the old flat value on Bulwark")

  turret = require_turret_near(surface, { x = 14, y = 8 }, "specialization multiplier turret not found after bulwark body swap")
  summary = call("set_evolution", turret, {
    specialization = "brawler",
    base = {
      siphon = 4,
    },
  })
  assert_near(summary.derived.lifesteal_rate, 0.04, 0.0001, "brawler lifesteal multiplier did not affect derived lifesteal")
  assert_near(summary.attack_cooldown, base_cooldown * 2, 0.0001, "brawler cooldown multiplier did not reduce fire rate to x0.5")
  assert_near(summary.attack_damage_modifier, base_damage_modifier * 3, 0.0001, "brawler damage multiplier did not reduce to x3")
end

local function run_resistance_test(surface)
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

local function run_modded_base_range_variant_test(surface)
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

local function run_turret_ammo_range_compat_test()
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

local function run_level_zero_points_test(surface)
  local turret = create_turret(surface, { 10, -12 }, 10)
  local summary = call("install_core", turret, {})
  assert_eq(summary.level, 0, "new Veteran Cores should start at level 0")
  assert_eq(summary.evolution.available_core_points, 0, "level 0 core should have zero available core points")

  summary = call("set_profile", turret, { level = 10 })
  assert_eq(summary.level, 10, "test setup did not create a level 10 core")
  assert_eq(summary.evolution.available_core_points, 10, "level 10 core should have ten available core points")
end

local function run_shield_test(surface)
  local turret_position = { x = 42, y = 0 }
  local turret = create_turret(surface, turret_position, 10)
  local summary = call("install_core", turret, { level = 25 })
  assert_true(summary ~= nil, "failed to install core for shield test")

  summary = call("set_evolution", turret, {
    base = {
      shield = 4,
      repair = 1,
    },
  })
  assert_eq(summary.entity_name, "gun-turret", "shield rank should not swap to a health variant")
  assert_eq(summary.max_health, 400, "shield rank should not increase real max health")
  assert_eq(summary.evolution.base.shield, 4, "shield rank did not persist in base upgrade state")
  assert_eq(summary.derived.shield_capacity, 200, "shield capacity did not scale with rank")
  assert_eq(summary.shield, 200, "new shield ranks should refill shield")

  turret = require_turret_near(surface, turret_position, "shield test turret not found")
  local before_health = turret.health
  local applied = turret.damage(120, game.forces.enemy, "physical")
  assert_true(applied and applied > 0, "shield test did not apply incoming damage")
  summary = call("get_state", turret)
  assert_eq(summary.shield, 80, "shield did not absorb incoming damage before HP")
  assert_near(turret.health, before_health, 0.05, "shielded damage should not reduce HP while shield remains")
  assert_true(summary.shield_bar_valid, "shield damage did not create the in-world shield bar")
  assert_true(summary.shield_bar_fill_valid, "partially filled shield should render a shield fill")
  assert_true(summary.health_bar_valid, "shield damage did not create the paired in-world HP bar")
  assert_true(summary.health_bar_fill_valid, "full HP should render an HP fill above the shield bar")

  applied = turret.damage(100, game.forces.enemy, "physical")
  assert_true(applied and applied > 0, "shield spillover test did not apply incoming damage")
  summary = call("get_state", turret)
  assert_eq(summary.shield, 0, "shield should be empty after absorbing remaining capacity")
  assert_near(turret.health, before_health - 20, 0.05, "only damage beyond shield should reach HP")
  assert_true(summary.shield_bar_valid, "empty shield should keep its in-world bar visible during recharge delay")
  assert_eq(summary.shield_bar_fill_valid, false, "empty shield should not render a filled shield segment")
  assert_true(summary.health_bar_valid, "empty shield should keep the paired HP bar visible during recharge delay")
  assert_true(summary.health_bar_fill_valid, "damaged turret should keep rendering remaining HP above the shield bar")

  call("apply_passive", 5)
  summary = call("get_state", turret)
  assert_eq(summary.shield, 0, "shield should not recharge before its delay")
  call("age_shield_damage", turret, 60 * 6)
  call("apply_passive", 1)
  summary = call("get_state", turret)
  assert_gt(summary.shield, 0, "shield did not start recharging after its delay")
end

local function run_ammo_regen_test(surface)
  local turret_position = { x = 44, y = 0 }
  local turret = create_turret(surface, turret_position, 1)
  local summary = call("install_core", turret, { level = 80 })
  assert_true(summary ~= nil, "failed to install core for ammo regen test")

  summary = call("set_evolution", turret, {
    base = {
      ammo_regen = 60,
    },
  })
  assert_eq(summary.evolution.base.ammo_regen, 60, "ammo regen rank did not persist in evolution state")

  call("apply_passive", 1)
  summary = call("get_state", turret)
  assert_true(summary.last_ammo ~= nil and summary.last_ammo.name == "firearm-magazine", "ammo regen did not remember loaded ammo")

  local inventory = turret.get_inventory(defines.inventory.turret_ammo)
  assert_true(inventory ~= nil and inventory.valid, "ammo regen test turret had no ammo inventory")
  inventory.remove({ name = "firearm-magazine", count = inventory.get_item_count("firearm-magazine") })
  assert_eq(inventory.get_item_count("firearm-magazine"), 0, "ammo regen test failed to empty turret ammo")

  call("apply_passive", 1)
  summary = call("get_state", turret)
  assert_gt(summary.turret_ammo["firearm-magazine"] or 0, 0, "ammo regen did not recover remembered ammo into an empty turret")
end

local function feed_one(entity, item_name)
  local inserted = call("insert_feeder", entity, { name = item_name, count = 1 }).inserted
  assert_eq(inserted, 1, "failed to insert one " .. item_name .. " into the hidden feeder")
  return call("route_feeder", entity)
end

local function feed_element_until_rank(entity, item_name, element_id, target_rank, max_cycles)
  local summary = call("get_state", entity)
  for _ = 1, max_cycles or 100 do
    local mastery = summary.evolution.element_mastery[element_id] or {}
    if (mastery.rank or 0) >= target_rank then
      return summary
    end
    call("insert_feeder", entity, { name = item_name, count = 1000 })
    summary = call("route_feeder", entity)
  end
  return summary
end

local function run_legacy_migration_test()
  local skills = call("normalize_profile_snapshot", {
    skills = {
      ballistics = 2,
      kill_chain = 3,
      targeting_data = 4,
      field_repairs = 1,
    },
    evolution = {},
  })
  assert_eq(skills.evolution.base.damage, 2, "legacy Ballistics skill did not migrate into Damage")
  assert_eq(skills.evolution.base.xp, 7, "legacy XP skills did not migrate into Veteran Training")
  assert_eq(skills.evolution.base.repair, 1, "legacy Field Repairs skill did not migrate into Regeneration")
  assert_eq(skills.evolution.migrated_legacy_skills, true, "legacy skill migration was not marked complete")

  local skills_again = call("normalize_profile_snapshot", {
    skills = {
      ballistics = 2,
      kill_chain = 3,
      targeting_data = 4,
      field_repairs = 1,
    },
    evolution = {
      base = skills.evolution.base,
      migrated_legacy_skills = true,
    },
  })
  assert_eq(skills_again.evolution.base.damage, 2, "legacy skill migration was not idempotent for Damage")
  assert_eq(skills_again.evolution.base.xp, 7, "legacy skill migration was not idempotent for Veteran Training")
  assert_eq(skills_again.evolution.base.repair, 1, "legacy skill migration was not idempotent for Regeneration")

  local tagged = call("deserialize_profile_snapshot", {
    schema = 1,
    level = 50,
    evolution = {
      augments = {
        piercing = 4,
        longshot = 3,
        range = 2,
        max_health = 5,
      },
      elements = {
        first = "fire",
        second = "explosive",
      },
      element_mastery = {
        fire = {
          rank = 2,
          delivered = 12,
          fuel = 99,
          burn_remaining = 30,
        },
        explosive = {
          rank = 1,
          delivered = 8,
          fuel = 4,
        },
      },
    },
  })
  assert_eq(tagged.evolution.elements[1], "fire", "legacy first element tag did not migrate to slot 1")
  assert_eq(tagged.evolution.elements[2], "explosive", "legacy second element tag did not migrate to slot 2")
  assert_eq(tagged.evolution.augments.range, nil, "retired Range augment was not removed")
  assert_eq(tagged.evolution.augments.max_health, nil, "retired Max HP augment was not removed")
  assert_eq(tagged.evolution.augments.piercing, nil, "retired Piercing augment was not removed")
  assert_eq(tagged.evolution.augments.longshot, nil, "retired Longshot augment was not removed")
  assert_eq(tagged.evolution.element_mastery.fire.rank, 2, "legacy Fire mastery rank was not preserved")
  assert_eq(tagged.evolution.element_mastery.fire.delivered, 12, "legacy Fire delivered material was not preserved")
  assert_eq(tagged.evolution.element_mastery.fire.fuel, nil, "legacy Fire fuel buffer was not removed")
  assert_eq(tagged.evolution.element_mastery.fire.burn_remaining, nil, "legacy Fire burn state was not removed")

  local free_pick = call("normalize_profile_snapshot", {
    evolution = {
      element_project = {
        slot = 1,
        element = "fire",
        target_rank = 1,
        delivered = {},
        requirements = {},
      },
    },
  })
  assert_eq(free_pick.evolution.elements[1], "fire", "legacy free element project did not assign the element")
  assert_eq(free_pick.evolution.element_mastery.fire.rank, 1, "legacy free element project did not grant free rank")
  assert_eq(free_pick.evolution.element_project, nil, "legacy free element project was not removed")

  local renamed_materials = call("normalize_profile_snapshot", {
    evolution = {
      elements = { "electric" },
      element_mastery = {
        electric = {
          rank = 1,
          delivered = 4,
        },
      },
      element_project = {
        slot = 1,
        element = "electric",
        target_rank = 2,
        requirements = {
          { name = "copper-cable", count = 100 },
          { name = "iron-plate", count = 100 },
        },
        delivered = {
          ["copper-cable"] = 7,
          ["iron-plate"] = 5,
        },
      },
    },
  })
  assert_eq(renamed_materials.evolution.element_project, nil, "legacy renamed-resource project was not removed")
  assert_eq(renamed_materials.evolution.element_mastery.electric.rank, 1, "partial legacy project unexpectedly ranked Electric")
  assert_eq(
    renamed_materials.evolution.element_mastery.electric.delivered,
    16,
    "legacy renamed resources did not migrate into delivered progress"
  )

  local completed_project = call("normalize_profile_snapshot", {
    evolution = {
      elements = { "explosive" },
      element_mastery = {
        explosive = {
          rank = 1,
          delivered = 0,
        },
      },
      element_project = {
        slot = 1,
        element = "explosive",
        target_rank = 2,
        requirements = {
          { name = "grenade", count = 500 },
        },
        delivered = {
          grenade = 500,
        },
      },
    },
  })
  assert_eq(completed_project.evolution.element_project, nil, "completed legacy project was not removed")
  assert_eq(completed_project.evolution.element_mastery.explosive.rank, 2, "completed legacy project did not advance rank")
  assert_eq(
    completed_project.evolution.element_mastery.explosive.delivered,
    0,
    "completed legacy project did not consume delivered materials"
  )

  local invalid_project = call("normalize_profile_snapshot", {
    evolution = {
      element_project = true,
    },
  })
  assert_eq(invalid_project.evolution.element_project, nil, "invalid legacy project value was not removed")
end

local function create_source_chest(surface, position, item_name)
  local chest = surface.create_entity({
    name = "wooden-chest",
    position = position,
    force = "player",
    raise_built = false,
  })
  assert_true(chest and chest.valid, "failed to create source chest for feeder inserter test")
  local inserted = chest.insert({
    name = item_name,
    count = 10,
  })
  assert_gt(inserted, 0, "failed to fill source chest for feeder inserter test")
  return chest
end

local function destroy_entity(entity)
  if entity and entity.valid then
    pcall(function()
      entity.destroy({ raise_destroy = false })
    end)
  end
end

local function cleanup_test_turret(turret)
  if turret and turret.valid then
    call("cleanup_entity", turret)
    destroy_entity(turret)
  end
end

local function run_feeder_material_progress_test(surface)
  local turret = create_turret(surface, { 16, 0 }, 10)
  local summary = call("install_core", turret, { level = 20 })
  assert_true(summary ~= nil, "failed to install core for feeder test")

  summary = call("pick_element", turret, 1, "explosive")
  assert_eq(summary.evolution.elements[1], "explosive", "free explosive pick did not select the first element")
  assert_eq(summary.evolution.element_mastery.explosive.rank, 1, "free explosive pick did not start at rank 1")
  assert_eq(summary.evolution.element_project, nil, "free element pick should not keep legacy material project state")
  assert_eq(summary.feeder.valid, true, "selected element did not create the hidden feeder for passive progress")
  assert_eq(summary.feeder.needs_input, true, "selected element did not request its next-rank material")
  assert_contains(summary.feeder.allowed_items, "grenade", "explosive passive progress did not request grenades")

  local ammo_before = summary.turret_ammo["firearm-magazine"] or 0
  summary = feed_one(turret, "firearm-magazine")
  assert_gt(
    summary.turret_ammo["firearm-magazine"] or 0,
    ammo_before,
    "ammo inserted into open hidden feeder was not forwarded to turret ammo inventory"
  )

  summary = call("insert_feeder", turret, { name = "sulfur", count = 1 })
  assert_eq(summary.inserted, 1, "passive element feeder did not expose a test slot for an unexpected material")
  summary = call("route_feeder", turret)
  assert_eq(summary.feeder.counts.sulfur or 0, 0, "unexpected material remained in the hidden feeder and would block element progress")
  assert_eq(summary.evolution.element_mastery.explosive.delivered or 0, 0, "unexpected material advanced explosive progress")

  summary = call("insert_feeder", turret, { name = "grenade", count = 25 })
  assert_eq(summary.inserted, 25, "passive element feeder did not accept a buffered material stack")
  assert_eq(summary.feeder.counts.grenade, 25, "passive element feeder did not retain buffered materials before routing")
  summary = call("route_feeder", turret)
  assert_eq(summary.evolution.element_mastery.explosive.delivered, 25, "buffered materials were not routed into passive element progress")

  for _ = 1, 475 do
    summary = feed_one(turret, "grenade")
  end

  assert_eq(summary.evolution.elements[1], "explosive", "passive progress did not keep explosive selected after required feed")
  assert_eq(summary.evolution.element_mastery.explosive.rank, 2, "completed passive progress did not increase mastery to rank 2")
  assert_true(summary.evolution.element_project == nil, "passive element progress should not create legacy projects")
  assert_eq(summary.feeder.needs_input, true, "feeder should continue requesting the next passive element rank")
  assert_contains(summary.feeder.allowed_items, "grenade", "feeder did not continue requesting explosive material after rank up")
end

local function run_feeder_contract_test(surface)
  local turret_position = { x = 28, y = 12 }
  local turret = create_turret(surface, turret_position, 10)
  local summary = call("install_core", turret, { level = 20 })
  assert_true(summary ~= nil, "failed to install core for feeder contract test")
  assert_eq(summary.feeder.valid, false, "a core with no selected element should not create an invisible feeder")
  assert_eq(summary.feeder.needs_input, false, "a core with no selected element should not need material input")

  summary = call("pick_element", turret, 1, "fire")
  assert_eq(summary.feeder.valid, true, "selected element did not create the invisible feeder")
  assert_eq(summary.feeder.needs_input, true, "selected element did not request passive material input")
  assert_contains(summary.feeder.allowed_items, "sulfur", "fire passive progress did not request sulfur")

  local feeder_unit = summary.feeder.unit_number
  assert_eq(call("feeder_owner", feeder_unit), summary.chip_id, "feeder ownership table did not point at the installed core")

  local inserter = surface.create_entity({
    name = "inserter",
    position = { turret_position.x, turret_position.y + 1 },
    direction = defines.direction.south,
    force = "player",
    raise_built = false,
  })
  assert_true(inserter and inserter.valid, "failed to create inserter for feeder contract test")
  local pickup_position = inserter.pickup_position

  call("update_feeder_inserters", turret)
  local inserter_state = call("inserter_state", inserter)
  assert_eq(inserter_state.managed, false, "empty-source inserter should not be managed by the invisible feeder")
  assert_eq(inserter_state.filters[1], nil, "empty-source inserter should not receive a material filter")

  local source_chest = create_source_chest(surface, pickup_position, "sulfur")
  local probe = call("feeder_inserter_probe", turret, inserter)
  assert_true(
    probe.points_at_turret,
    "source-ready inserter did not point at the turret/feeder tile: "
      .. serpent.line(probe)
      .. " "
      .. serpent.line(call("inserter_state", inserter))
  )
  assert_true(probe.has_source_item, "source-ready inserter source did not expose an allowed material: " .. serpent.line(probe))
  call("update_feeder_inserters", turret)
  inserter_state = call("inserter_state", inserter)
  assert_eq(inserter_state.managed, true, "source-ready material inserter was not marked managed")
  assert_eq(inserter_state.filters[1], "sulfur", "source-ready material inserter did not receive its available material filter")
  assert_eq(inserter_state.drop_target_unit_number, feeder_unit, "source-ready material inserter was not pointed at the hidden feeder")

  local off_target_inserter = surface.create_entity({
    name = "inserter",
    position = { turret_position.x + 3, turret_position.y + 1 },
    direction = defines.direction.south,
    force = "player",
    raise_built = false,
  })
  assert_true(off_target_inserter and off_target_inserter.valid, "failed to create off-target inserter")
  local off_target_chest = create_source_chest(surface, off_target_inserter.pickup_position, "sulfur")
  local off_target_probe = call("feeder_inserter_probe", turret, off_target_inserter)
  assert_true(
    off_target_probe.points_at_turret ~= true,
    "source-ready inserter that does not target the turret was incorrectly eligible: " .. serpent.line(off_target_probe)
  )
  assert_true(
    off_target_probe.has_source_item,
    "off-target inserter fixture did not expose source material: " .. serpent.line(off_target_probe)
  )
  local stale_managed = call("manage_inserter_filters", turret, off_target_inserter)
  assert_true(stale_managed and stale_managed.applied, "failed to seed stale off-target managed inserter state")
  local stale_state = call("inserter_state", off_target_inserter)
  assert_eq(stale_state.managed, true, "stale off-target fixture was not captured as managed")
  assert_eq(stale_state.filters[1], "sulfur", "stale off-target fixture did not receive its seeded material filter")
  call("update_feeder_inserters", turret)
  local off_target_state = call("inserter_state", off_target_inserter)
  assert_eq(off_target_state.managed, false, "off-target inserter should be restored by the invisible feeder update")
  assert_eq(off_target_state.filters[1], nil, "off-target inserter should not receive a material filter")
  assert_true(off_target_state.drop_target_unit_number ~= feeder_unit, "off-target inserter should not be pointed at the hidden feeder")

  summary = call("reset_evolution_section", turret, "element-slot", 1)
  assert_eq(summary.feeder.valid, false, "resetting the only element should destroy the invisible feeder")
  assert_eq(summary.feeder.needs_input, false, "resetting the only element should clear material input need")
  assert_eq(call("feeder_owner", feeder_unit), nil, "destroyed feeder unit was still mapped to a core")

  inserter_state = call("inserter_state", inserter)
  assert_eq(inserter_state.managed, false, "inserter remained managed after material input ended")
  assert_eq(inserter_state.filters[1], nil, "inserter filter was not restored after material input ended")
  assert_eq(inserter_state.drop_target_unit_number, summary.unit_number, "inserter was not restored to the turret after feeder teardown")

  destroy_entity(source_chest)
  destroy_entity(off_target_chest)
  destroy_entity(inserter)
  destroy_entity(off_target_inserter)
  cleanup_test_turret(turret)
end

local function run_dual_element_feeder_test(surface)
  local turret = create_turret(surface, { 20, 8 }, 10)
  local summary = call("install_core", turret, { level = 55 })
  assert_true(summary ~= nil, "failed to install core for dual-element feeder test")

  summary = call("set_evolution", turret, {
    elements = { "fire", "explosive" },
    element_mastery = {
      fire = {
        rank = 1,
        delivered = 0,
      },
      explosive = {
        rank = 1,
        delivered = 0,
      },
    },
  })

  assert_eq(summary.evolution.elements[1], "fire", "first element did not persist")
  assert_eq(summary.evolution.elements[2], "explosive", "second element did not persist")
  assert_contains(summary.feeder.allowed_items, "sulfur", "fire passive progress did not request sulfur")
  assert_contains(summary.feeder.allowed_items, "grenade", "explosive passive progress did not request grenades")
  assert_eq(summary.feeder.allowed_items[1], "sulfur", "first element material was not prioritized first")

  local inserter = surface.create_entity({
    name = "inserter",
    position = { 20, 11 },
    force = "player",
    raise_built = false,
  })
  assert_true(inserter and inserter.valid, "failed to create inserter for filter regression")
  local managed = call("manage_inserter_filters", turret, inserter)
  assert_true(managed and managed.applied, "managed inserter filter was not applied for passive mixed elements")
  assert_eq(managed.filters[1], "sulfur", "managed inserter did not prioritize sulfur first")
  assert_eq(managed.filters[2], "grenade", "managed inserter did not expose the second element material")

  local source_limited_inserter = surface.create_entity({
    name = "inserter",
    position = { 20, 9 },
    direction = defines.direction.south,
    force = "player",
    raise_built = false,
  })
  assert_true(source_limited_inserter and source_limited_inserter.valid, "failed to create source-limited inserter")
  local source_limited_pickup = source_limited_inserter.pickup_position
  local source_limited_chest = create_source_chest(surface, source_limited_pickup, "grenade")

  managed = call("manage_inserter_filters", turret, source_limited_inserter)
  assert_true(managed and managed.applied, "source-limited inserter filter was not applied")
  assert_eq(managed.filters[1], "grenade", "source-limited inserter did not prioritize the material available at its pickup source")
  assert_contains(managed.filters, "sulfur", "source-limited inserter lost the fallback material filter")
  local restored = call("restore_inserter_filters", source_limited_inserter)
  assert_eq(restored.managed, false, "source-limited inserter remained tracked after explicit filter restore")
  assert_eq(restored.filters[1], nil, "source-limited inserter filter was not restored")
  destroy_entity(source_limited_inserter)
  destroy_entity(source_limited_chest)

  summary = feed_one(turret, "sulfur")
  assert_eq(summary.evolution.element_mastery.fire.delivered, 1, "fire progress did not consume sulfur")
  assert_eq(summary.evolution.element_mastery.explosive.rank, 1, "feeding fire progress changed explosive mastery")

  summary = feed_element_until_rank(turret, "sulfur", "fire", 2, 40)
  assert_eq(summary.evolution.element_mastery.fire.rank, 2, "fire passive progress did not complete rank 2")
  assert_contains(summary.feeder.allowed_items, "grenade", "explosive rank progress did not request grenades")
  managed = call("manage_inserter_filters", turret, inserter)
  assert_contains(managed.filters, "grenade", "managed inserter stopped exposing explosive material")

  summary = feed_one(turret, "grenade")
  assert_eq(summary.evolution.element_mastery.fire.rank, 2, "feeding explosive progress changed fire mastery")
  assert_eq(summary.evolution.element_mastery.explosive.delivered, 1, "explosive progress did not consume grenade")

  summary = call("set_evolution", turret, {
    elements = { "explosive", "explosive" },
    element_mastery = {
      explosive = {
        rank = 1,
        delivered = 0,
      },
    },
    element_project = false,
  })

  assert_eq(summary.evolution.unique_elements[1], "explosive", "duplicate pure element did not report explosive as active")
  assert_eq(#summary.evolution.unique_elements, 1, "duplicate pure element was not summarized as one active element")
  assert_eq(#summary.feeder.allowed_items, 1, "duplicate pure element should request one shared material")
  assert_eq(summary.feeder.allowed_items[1], "grenade", "duplicate pure element did not request the shared explosive material")

  summary = call("set_evolution", turret, {
    elements = { "toxic", nil },
    element_mastery = {
      toxic = {
        rank = 1,
        delivered = 0,
      },
    },
  })
  assert_contains(summary.feeder.allowed_items, "poison-capsule", "toxic passive progress did not request poison capsules")
  call("restore_inserter_filters", inserter)
  destroy_entity(inserter)
end

local function run_targeted_reset_test(surface)
  local turret_position = { x = 36, y = 8 }
  local turret = create_turret(surface, turret_position, 10)
  local summary = call("install_core", turret, { level = 50 })
  assert_true(summary ~= nil, "failed to install core for targeted reset test")

  summary = call("set_evolution", turret, {
    base = {
      damage = 3,
      repair = 2,
      resistance = 4,
    },
    augments = {
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
  assert_eq(summary.evolution.augments.luck, 1, "test setup did not apply augment ranks")
  assert_eq(summary.evolution.specialization, "sniper", "test setup did not apply specialization")

  turret = require_turret_near(surface, turret_position, "targeted reset turret not found after setup body swap")
  summary = call("reset_evolution_section", turret, "base")
  assert_eq(summary.evolution.base.damage or 0, 0, "base reset did not clear damage ranks")
  assert_eq(summary.evolution.augments.luck, 1, "base reset incorrectly changed augments")
  assert_eq(summary.evolution.specialization, "sniper", "base reset incorrectly changed specialization")

  turret = require_turret_near(surface, turret_position, "targeted reset turret not found after base reset")
  summary = call("reset_evolution_section", turret, "augments")
  assert_eq(summary.evolution.augments.luck or 0, 0, "augment reset did not clear augment ranks")
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

local function run_full_evolution_reset_test(surface)
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
      repair = 2,
      resistance = 4,
      crit_chance = 4,
      crit_damage = 5,
    },
    augments = {
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

local function run_damage_accounting_test(surface)
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

local function run_bound_turret_test(surface)
  local turret = create_turret(surface, { 24, 0 }, 7)
  turret.health = 250
  call("install_core", turret, {
    level = 12,
    custom_name = "Bounder",
    show_name_label = true,
  })
  local summary = call("set_bound", turret, true)
  assert_eq(summary.bound_turret, true, "bound flag did not persist")

  local buffer = game.create_inventory(20)
  buffer.insert({ name = "gun-turret", count = 1 })
  buffer.insert({ name = "firearm-magazine", count = 7 })
  local mined = call("mine_bound_turret", turret, buffer)
  assert_true(mined.converted == true, "bound mining helper did not convert mining results")

  assert_eq(inventory_count(buffer, "turret-xp-bound-gun-turret"), 1, "bound turret mining did not return one bound turret item")
  assert_eq(inventory_count(buffer, "gun-turret"), 0, "bound turret mining duplicated the vanilla gun turret item")
  assert_eq(inventory_count(buffer, "turret-xp-veteran-core"), 0, "bound turret mining duplicated the Veteran Core item")

  local bound_stack = find_stack(buffer, "turret-xp-bound-gun-turret")
  assert_true(bound_stack ~= nil, "could not find bound turret item stack")
  local decoded = call("read_bound_turret_stack", bound_stack)
  assert_true(decoded ~= nil, "bound turret item did not preserve readable tags")
  assert_eq(decoded.profile.custom_name, "Bounder", "bound turret item lost core name")
  assert_eq(decoded.profile.bound_turret, true, "bound turret item lost bound flag")
  assert_eq(decoded.profile.level, 12, "bound turret item lost core level")
  assert_eq(#(decoded.turret.ammo or {}), 1, "bound turret item did not snapshot loaded ammo")

  local legacy_inventory = game.create_inventory(1)
  local legacy_definition = call("make_legacy_bound_turret_stack", {
    level = 22,
    custom_name = "Legacy Bound",
  })
  local legacy_copied = pcall(function()
    legacy_inventory[1].set_stack(legacy_definition)
  end)
  assert_true(legacy_copied and legacy_inventory[1].valid_for_read, "failed to create legacy bound turret stack")
  local legacy_decoded = call("read_bound_turret_stack", legacy_inventory[1])
  assert_true(legacy_decoded ~= nil, "legacy bound turret stack did not decode")
  assert_eq(legacy_decoded.profile.custom_name, "Legacy Bound", "legacy bound stack lost profile name")
  assert_eq(legacy_decoded.profile.bound_turret, true, "legacy bound stack did not normalize bound flag")
  assert_eq(legacy_decoded.profile.level, 22, "legacy bound stack lost core level")
  assert_eq(legacy_decoded.turret.quality, "normal", "legacy bound stack did not default turret quality")
  assert_eq(#(legacy_decoded.turret.ammo or {}), 0, "legacy bound stack should decode with an empty ammo snapshot")

  local preview_turret = create_turret(surface, { 26, -4 }, 5)
  call("install_core", preview_turret, { level = 45 })
  call("set_evolution", preview_turret, {
    specialization = "sniper",
  })
  preview_turret = require_turret_near(surface, { x = 26, y = -4 }, "bound preview turret not found after body swap")
  call("set_bound", preview_turret, true)
  local preview_stack = call("make_bound_turret_stack", preview_turret)
  local preview_item_name = "turret-xp-bound-gun-turret-sniper"
  assert_eq(
    preview_stack.name,
    preview_item_name,
    "bound turret stack did not use the matching specialization preview item"
  )

  local preview_buffer = game.create_inventory(1)
  preview_buffer.insert({ name = "iron-plate", count = 1 })
  local preview_ground_before = ground_item_count(surface, { x = 26, y = -4 }, preview_item_name)
  local preview_mined = call("mine_bound_turret", preview_turret, preview_buffer)
  assert_true(preview_mined.converted == true, "specialized bound turret mining did not convert with a full buffer")
  assert_eq(
    inventory_count(preview_buffer, "turret-xp-veteran-core"),
    0,
    "specialized full-buffer mining fell back to a separate Veteran Core"
  )
  assert_gt(
    ground_item_count(surface, { x = 26, y = -4 }, preview_item_name),
    preview_ground_before,
    "specialized full-buffer mining did not spill the preview bound turret item"
  )
  local preview_ground_stack = find_ground_stack(surface, { x = 26, y = -4 }, preview_item_name)
  assert_true(preview_ground_stack ~= nil, "specialized spilled bound turret item was not found on the ground")
  local preview_decoded = call("read_bound_turret_stack", preview_ground_stack)
  assert_eq(preview_decoded.profile.level, 45, "specialized spilled bound turret lost its core level")
  assert_eq(preview_decoded.profile.evolution.specialization, "sniper", "specialized spilled bound turret lost its specialization")
  assert_eq(preview_decoded.profile.evolution.augments.range, nil, "specialized spilled bound turret preserved a retired range rank")

  local consumed_items = game.create_inventory(1)
  local copied = pcall(function()
    consumed_items[1].set_stack(bound_stack)
  end)
  assert_true(copied and consumed_items[1].valid_for_read, "failed to copy bound turret stack into build event inventory")

  local placed = surface.create_entity({
    name = "turret-xp-bound-gun-turret-placeholder",
    position = { 28, 0 },
    force = "player",
    raise_built = false,
  })
  assert_true(placed and placed.valid, "failed to create bound turret placeholder")
  summary = call("install_bound_turret_stack", placed, consumed_items[1])
  assert_true(summary ~= nil, "placed bound turret did not reinstall its Veteran Core profile")
  assert_eq(summary.entity_name, "gun-turret", "bound turret placeholder was not replaced by a real gun turret")
  assert_eq(summary.custom_name, "Bounder", "placed bound turret lost core name")
  assert_eq(summary.bound_turret, true, "placed bound turret lost bound state")
  assert_eq(summary.level, 12, "placed bound turret lost core level")
  assert_gt(summary.turret_ammo["firearm-magazine"] or 0, 0, "placed bound turret did not restore ammo snapshot")

  local fillme_position = { x = 30, y = 0 }
  local fillme_turret = create_turret(surface, fillme_position, 10)
  local spilled_before = ground_item_count(surface, fillme_position, "firearm-magazine")
  summary = call("install_bound_turret_stack", fillme_turret, consumed_items[1])
  assert_true(summary ~= nil, "preloaded bound turret placement did not reinstall its Veteran Core profile")
  assert_eq(summary.turret_ammo["firearm-magazine"] or 0, 7, "preloaded placement ammo changed the bound ammo snapshot")
  assert_eq(
    ground_item_count(surface, fillme_position, "firearm-magazine") - spilled_before,
    10,
    "preloaded placement ammo was not fully refunded before restoring the bound snapshot"
  )

  local partial_fillme_position = { x = 30, y = 2 }
  local partial_fillme_turret = create_turret(surface, partial_fillme_position, 3)
  spilled_before = ground_item_count(surface, partial_fillme_position, "firearm-magazine")
  summary = call("install_bound_turret_stack", partial_fillme_turret, consumed_items[1])
  assert_true(summary ~= nil, "partially preloaded bound turret placement did not reinstall its profile")
  assert_eq(summary.turret_ammo["firearm-magazine"] or 0, 7, "partial preload was counted as saved bound ammo")
  assert_eq(ground_item_count(surface, partial_fillme_position, "firearm-magazine") - spilled_before, 3, "partial preload was not refunded")

  local incompatible_fillme_position = { x = 30, y = 4 }
  local incompatible_fillme_turret = create_turret(surface, incompatible_fillme_position, 0)
  incompatible_fillme_turret.insert({ name = "piercing-rounds-magazine", count = 4 })
  local piercing_before = ground_item_count(surface, incompatible_fillme_position, "piercing-rounds-magazine")
  summary = call("install_bound_turret_stack", incompatible_fillme_turret, consumed_items[1])
  assert_true(summary ~= nil, "incompatibly preloaded bound turret placement did not reinstall its profile")
  assert_eq(summary.turret_ammo["firearm-magazine"] or 0, 7, "incompatible preload blocked saved ammo restoration")
  assert_eq(summary.turret_ammo["piercing-rounds-magazine"] or 0, 0, "incompatible preload remained inside the restored turret")
  assert_eq(
    ground_item_count(surface, incompatible_fillme_position, "piercing-rounds-magazine") - piercing_before,
    4,
    "incompatible preload was not refunded"
  )

  local full_position = { x = 32, y = 0 }
  local full_turret = create_turret(surface, full_position, 5)
  call("install_core", full_turret, {
    level = 18,
    custom_name = "No Space",
  })
  call("set_bound", full_turret, true)
  local full_buffer = game.create_inventory(1)
  full_buffer.insert({ name = "iron-plate", count = 1 })
  local bound_on_ground_before = ground_item_count(surface, full_position, "turret-xp-bound-gun-turret")
  mined = call("mine_bound_turret", full_turret, full_buffer)
  assert_true(mined.converted == true, "bound mining with a full buffer did not complete conversion")
  assert_eq(inventory_count(full_buffer, "turret-xp-bound-gun-turret"), 0, "full buffer unexpectedly accepted the bound turret item")
  assert_eq(inventory_count(full_buffer, "turret-xp-veteran-core"), 0, "full buffer bound mining fell back to a separate Veteran Core")
  assert_gt(
    ground_item_count(surface, full_position, "turret-xp-bound-gun-turret"),
    bound_on_ground_before,
    "full buffer bound mining did not spill the tagged bound turret item"
  )
  local full_ground_stack = find_ground_stack(surface, full_position, "turret-xp-bound-gun-turret")
  assert_true(full_ground_stack ~= nil, "full-buffer spilled bound turret was not found on the ground")
  local full_decoded = call("read_bound_turret_stack", full_ground_stack)
  assert_eq(full_decoded.profile.custom_name, "No Space", "full-buffer spilled bound turret lost its core name")
  assert_eq(full_decoded.profile.bound_turret, true, "full-buffer spilled bound turret lost its bound flag")
  assert_eq(full_decoded.profile.level, 18, "full-buffer spilled bound turret lost its core level")
  assert_eq(#(full_decoded.turret.ammo or {}), 1, "full-buffer spilled bound turret did not preserve ammo in its snapshot")

  pcall(function()
    legacy_inventory.destroy()
  end)
  pcall(function()
    buffer.destroy()
  end)
  pcall(function()
    preview_buffer.destroy()
  end)
  pcall(function()
    consumed_items.destroy()
  end)
  pcall(function()
    full_buffer.destroy()
  end)
end

local function run_bound_turret_mining_ammo_conservation_test(surface)
  local position = { x = 34, y = 0 }
  local turret = create_turret(surface, position, 7)
  call("install_core", turret, {
    level = 8,
    custom_name = "No Dupes",
  })
  call("set_bound", turret, true)

  local buffer = game.create_inventory(20)
  local external_returns = game.create_inventory(20)
  local mined = call("mine_bound_turret_with_vanilla_returns", turret, buffer, external_returns)
  assert_true(mined.converted == true, "bound mining did not convert after simulated vanilla returns")
  assert_eq(inventory_count(buffer, "turret-xp-bound-gun-turret"), 1, "bound mining did not return exactly one bound turret item")
  assert_eq(inventory_count(buffer, "gun-turret"), 0, "bound mining returned a vanilla gun turret alongside the bound turret item")
  assert_eq(
    inventory_count(buffer, "turret-xp-veteran-core"),
    0,
    "bound mining returned a separate Veteran Core alongside the bound turret item"
  )
  assert_eq(inventory_count(external_returns, "firearm-magazine"), 0, "bound mining left ammo for vanilla to return outside the bound item")

  local bound_stack = find_stack(buffer, "turret-xp-bound-gun-turret")
  assert_true(bound_stack ~= nil, "mined bound turret stack was not found")
  local decoded = call("read_bound_turret_stack", bound_stack)
  assert_true(decoded ~= nil, "mined bound turret item lost readable tags")
  assert_eq(decoded.profile.custom_name, "No Dupes", "mined bound turret lost its profile")
  assert_eq(decoded.profile.bound_turret, true, "mined bound turret lost its bound flag")
  assert_eq(#(decoded.turret.ammo or {}), 1, "mined bound turret did not keep ammo in the item snapshot")
  assert_eq(decoded.turret.ammo[1].name, "firearm-magazine", "mined bound turret snapshot used the wrong ammo")
  assert_eq(decoded.turret.ammo[1].count, 7, "mined bound turret snapshot used the wrong ammo count")

  local placed = surface.create_entity({
    name = "turret-xp-bound-gun-turret-placeholder",
    position = { 36, 0 },
    force = "player",
    raise_built = false,
  })
  assert_true(placed and placed.valid, "failed to create placeholder for mined bound turret")
  local summary = call("install_bound_turret_stack", placed, bound_stack)
  assert_true(summary ~= nil, "mined bound turret could not be placed again")
  assert_eq(summary.turret_ammo["firearm-magazine"] or 0, 7, "mined bound turret did not restore its saved ammo on placement")
  assert_eq(
    inventory_count(external_returns, "firearm-magazine"),
    0,
    "placing mined bound turret left duplicated ammo outside the bound item"
  )

  pcall(function()
    buffer.destroy()
  end)
  pcall(function()
    external_returns.destroy()
  end)
end

local function setup_combat_test(surface)
  local turret = create_turret(surface, { -20, 0 }, 100)
  call("install_core", turret, {
    custom_name = "Combat",
    level = 1,
  })

  for index = 1, 5 do
    local biter = surface.create_entity({
      name = "small-biter",
      position = { -10 + index, index - 3 },
      force = "enemy",
    })
    assert_true(biter and biter.valid, "failed to create combat test biter")
    biter.health = 1
  end

  storage.turret_xp_headless_tests.combat_position = { x = -20, y = 0 }
end

local function setup_status_damage_test(surface)
  local turret = create_turret(surface, { -30, 0 }, 10)
  local summary = call("install_core", turret, { level = 20 })
  assert_true(summary ~= nil, "failed to install core for status damage test")
  summary = call("set_evolution", turret, {
    base = {
      siphon = 25,
    },
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

local function check_combat_test(surface)
  local position = storage.turret_xp_headless_tests.combat_position
  local turret = find_turret_near(surface, position)
  assert_true(turret ~= nil, "combat test turret disappeared")
  local summary = call("get_state", turret)
  assert_true(summary ~= nil, "combat test turret lost its core")
  assert_gt(summary.damage, 0, "combat damage was not tracked")
  assert_gt(summary.total_xp, 0, "combat XP did not increase")
  assert_gt(summary.kills, 0, "combat kills were not tracked")
end

local function check_status_damage_test(surface)
  local position = storage.turret_xp_headless_tests.status_position
  local turret = find_turret_near(surface, position)
  assert_true(turret ~= nil, "status damage test turret disappeared")
  local summary = call("get_state", turret)
  assert_true(summary ~= nil, "status damage test turret lost its core")
  assert_gt(summary.damage, 0, "delayed status damage was not tracked as turret damage")
  assert_gt(summary.xp_damage, 0, "delayed status damage did not grant damage XP")
  assert_gt(turret.health, storage.turret_xp_headless_tests.status_start_health, "lifesteal did not apply to delayed status damage")
end

local function run_immediate_tests()
  local surface = get_surface()
  clear_test_area(surface)
  assert_true(remote.interfaces[IFACE] ~= nil, "Turret XP test remote interface is unavailable")

  run_layout_constants_test()
  run_gui_support_samples_test()
  run_compat_samples_test(surface)
  run_combat_budget_samples_test(surface)
  run_legacy_migration_test()
  run_prototype_budget_test()
  run_place_result_regression_test()
  run_profile_label_test(surface)
  run_modded_base_range_variant_test(surface)
  run_turret_ammo_range_compat_test()
  run_level_zero_points_test(surface)
  run_shield_test(surface)
  run_ammo_regen_test(surface)
  run_evolution_body_test(surface)
  run_specialization_secondary_multiplier_test(surface)
  run_resistance_test(surface)
  run_feeder_material_progress_test(surface)
  run_feeder_contract_test(surface)
  run_dual_element_feeder_test(surface)
  run_targeted_reset_test(surface)
  run_full_evolution_reset_test(surface)
  run_damage_accounting_test(surface)
  run_bound_turret_test(surface)
  run_bound_turret_mining_ammo_conservation_test(surface)
  setup_combat_test(surface)
  setup_status_damage_test(surface)
end

return {
  pass_tick = support.PASS_TICK,
  test_prefix = TEST_PREFIX,
  run_immediate_tests = run_immediate_tests,
  check_deferred_tests = function()
    check_combat_test(get_surface())
    check_status_damage_test(get_surface())
  end,
}
