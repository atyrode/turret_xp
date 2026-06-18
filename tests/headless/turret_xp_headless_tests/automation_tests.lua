local support = require("support")

local assert_true = support.assert_true
local assert_eq = support.assert_eq
local assert_ge = support.assert_ge
local assert_le = support.assert_le
local create_turret = support.create_turret
local require_turret_near = support.require_turret_near
local call = support.call

local tests = {}

local VETERAN_CORE = "turret-xp-veteran-core"

local function xy(x, y)
  return {
    x = x,
    y = y,
  }
end

local function refresh_turret(surface, position)
  position = position.x and position or xy(position[1], position[2])
  return require_turret_near(surface, position, "expected turret near " .. serpent.line(position))
end

local function cleanup_turret(turret)
  if turret and turret.valid then
    call("cleanup_entity", turret)
    turret.destroy({ raise_destroy = false })
  end
end

local function table_sum(values)
  local total = 0
  for _, value in pairs(values or {}) do
    total = total + math.max(0, math.floor(tonumber(value) or 0))
  end
  return total
end

local function unspent_label_for_profile(profile)
  local evolution = profile and profile.evolution or {}
  local core = evolution.available_core_points or 0
  local augments = evolution.available_augment_points or 0
  if core <= 0 and augments <= 0 then
    return nil
  end
  if augments > 0 then
    return "Core +" .. core .. " / Aug +" .. augments
  end
  return "Core +" .. core
end

function tests.run_label_display_policy_test(surface)
  local name_only = call("label_text_sample", {
    custom_name = "Alpha",
    level = 12,
    show_name_label = true,
    show_label_level = false,
  })
  assert_eq(name_only.text, "Alpha", "name-only label text should not imply level visibility")

  local level_only = call("label_text_sample", {
    custom_name = "Alpha",
    level = 12,
    show_name_label = false,
    show_label_level = true,
  })
  assert_eq(level_only.text, "Lvl 12", "level-only label text should not require a custom name")

  local name_and_level = call("label_text_sample", {
    custom_name = "Alpha",
    level = 12,
    show_name_label = true,
    show_label_level = true,
  })
  assert_eq(name_and_level.text, "Alpha (Lvl 12)", "name plus level should keep the compact legacy label shape")

  local unspent_level = call("target_required_level", {
    augments = {
      repair = 2,
    },
  })
  local unspent_only = call("label_text_sample", {
    level = unspent_level,
    show_unspent_label = true,
  })
  assert_eq(unspent_only.text, unspent_label_for_profile(unspent_only.profile), "unspent-only label should summarize both point pools")

  local combined = call("label_text_sample", {
    custom_name = "Alpha",
    level = unspent_level,
    show_name_label = true,
    show_label_level = true,
    show_unspent_label = true,
  })
  assert_eq(
    combined.text,
    "Alpha - Lvl " .. unspent_level .. " - " .. unspent_label_for_profile(combined.profile),
    "three-part labels should remain deterministic and readable"
  )

  local no_visible_points = call("label_text_sample", {
    level = 0,
    show_unspent_label = true,
  })
  assert_eq(no_visible_points.text, nil, "unspent label should not render a zero-point marker")

  local legacy_hidden_name = call("deserialize_profile_snapshot", {
    custom_name = "Legacy",
    label_display_schema = 1,
    show_name_label = false,
    show_label_level = true,
    level = 7,
  })
  assert_eq(legacy_hidden_name.show_label_level, false, "legacy hidden labels should not migrate into level-only labels")
  assert_eq(legacy_hidden_name.label_text, nil, "legacy hidden labels should stay hidden after migration")
  assert_eq(legacy_hidden_name.label_display_schema, 2, "legacy labels should be stamped with the current display schema")

  local legacy_visible_name = call("deserialize_profile_snapshot", {
    custom_name = "Legacy",
    label_display_schema = 1,
    show_name_label = true,
    level = 7,
  })
  assert_eq(legacy_visible_name.show_label_level, true, "legacy visible labels should keep showing the level suffix")
  assert_eq(legacy_visible_name.label_text, "Legacy (Lvl 0)", "legacy visible labels should keep the old name-plus-level shape")

  local turret = create_turret(surface, { 12, 0 }, 10)
  local summary = call("install_core", turret, {
    level = 5,
    show_label_level = true,
  })
  assert_true(summary ~= nil, "failed to install a core for render label testing")
  assert_eq(summary.label_text, "Lvl 5", "installed level-only label should render without a custom name")
  assert_true(summary.name_render_valid, "installed level-only label should create a render object")

  summary = call("set_profile", turret, {
    show_label_level = false,
  })
  assert_eq(summary.label_text, nil, "disabling the last visible label part should clear label text")
  assert_eq(summary.name_render_valid, false, "disabling the last visible label part should destroy the render object")
  cleanup_turret(turret)
end

function tests.run_build_mode_planning_test(surface)
  local gates = call("progression_gates")
  local turret = create_turret(surface, { 14, 0 }, 10)
  local summary = call("install_core", turret, {
    level = 0,
  })
  assert_true(summary ~= nil, "failed to install a core for build-mode planning")

  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "enter-build-mode",
  })
  assert_eq(summary.build_mode, true, "entering Build mode should mark the profile for preview")
  assert_eq(summary.automation_enabled, false, "entering Build mode should not enable Auto by itself")

  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "allocate-base",
    upgrade = "damage",
  })
  assert_eq(summary.evolution.base.damage, 0, "Build mode point planning must not spend live ranks")
  assert_eq(summary.automation_target.base.damage, 1, "Build mode should record planned core ranks")
  assert_eq(summary.automation_target.level, 1, "planned core rank should recalculate required level")

  summary = call("dispatch_checked_action", turret, {
    turret_xp_action = "toggle-base-forever",
    upgrade = "shield",
  }, true)
  assert_eq(summary.automation_target.base_infinite.shield, true, "loop checkbox should mark a core upgrade as forever")
  assert_eq(summary.automation_target_model.open_ended, true, "forever targets should make the build open-ended")

  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "choose-specialization",
    specialization = "sniper",
  })
  assert_eq(summary.evolution.specialization, nil, "Build mode should not pick the live specialization before level gates")
  assert_eq(summary.automation_target.specialization, "sniper", "Build mode should plan specialization choices")
  assert_ge(summary.automation_target.level, gates.specialization, "planned specialization should raise required build level")

  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "start-element",
    element = "explosive",
    slot = 1,
  })
  assert_eq(summary.evolution.elements[1], nil, "Build mode should not pick live elements before level gates")
  assert_eq(summary.automation_target.elements[1], "explosive", "Build mode should plan the first element")

  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "allocate-augment",
    augment = "veteran_training",
  })
  assert_eq(summary.evolution.augments.veteran_training, 0, "Build mode should not spend live augment ranks")
  assert_eq(summary.automation_target.augments.veteran_training, 1, "Build mode should plan augment ranks")
  assert_ge(summary.automation_target.level, gates.augments, "planned augment rank should raise required build level")

  local gui = call("installed_gui_contract", turret)
  assert_eq(gui.build_controls_type, "frame", "Build mode should use the expanded planning frame")
  assert_eq(gui.has_auto_checkbox, false, "Build mode should hide the Follow build checkbox")
  assert_eq(gui.has_build_level_summary, true, "Build mode should show the planned required level")
  assert_eq(gui.has_build_core_summary, true, "Build mode should show planned core point budget")
  assert_eq(gui.has_build_augment_summary, true, "Build mode should show planned augment point budget")
  assert_eq(gui.has_build_core_forever_summary, false, "Build mode should not duplicate loop priorities in summary rows")
  assert_eq(gui.has_build_augment_forever_summary, false, "Build mode should not duplicate augment loops in summary rows")
  assert_eq(gui.has_damage_forever_checkbox, true, "Build mode should show loop checkboxes on upgrade rows")
  assert_eq(gui.damage_forever_caption[1], "turret-xp.build-forever-toggle-label", "loop checkbox should have a readable label")
  assert_eq(
    gui.damage_forever_tooltip[1],
    "turret-xp.build-forever-toggle-tooltip",
    "loop checkbox should explain the post-build repeating behavior"
  )
  summary = call("dispatch_checked_action", turret, {
    turret_xp_action = "toggle-build-auto",
  }, true)
  assert_eq(summary.automation_enabled, false, "Follow build should not enable while Build mode is active")

  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "exit-build-mode",
  })
  assert_eq(summary.build_mode, false, "exiting Build mode should restore the live view")
  summary = call("dispatch_checked_action", turret, {
    turret_xp_action = "toggle-build-auto",
  }, true)
  assert_eq(summary.automation_enabled, true, "Follow build should enable when a build path exists")
  local planned_damage = summary.automation_target.base.damage

  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "allocate-base",
    upgrade = "damage",
  })
  assert_eq(summary.automation_target.base.damage, planned_damage, "Follow build should lock live Evolution controls")
  gui = call("installed_gui_contract", turret)
  assert_eq(gui.build_controls_type, "flow", "live mode should keep Build controls as a compact inline row")
  assert_eq(gui.has_auto_checkbox, true, "live mode should show the Follow build checkbox")
  assert_eq(gui.auto_state, true, "live Follow build checkbox should reflect enabled Auto")
  assert_eq(gui.has_build_level_summary, false, "live mode should hide build detail summary rows")
  assert_eq(gui.allocate_damage_enabled, false, "Follow build should disable manual Evolution buttons")
  assert_eq(
    gui.allocate_damage_tooltip[1],
    "turret-xp.follow-build-locked-tooltip",
    "Follow build locked buttons should explain why they are disabled"
  )
  assert_eq(gui.has_damage_forever_checkbox, false, "live mode should not show loop checkboxes")

  summary = call("dispatch_checked_action", turret, {
    turret_xp_action = "toggle-build-auto",
  }, false)
  assert_eq(summary.automation_enabled, false, "Follow build should be manually disableable before editing")
  gui = call("installed_gui_contract", turret)
  assert_eq(gui.build_controls_type, "flow", "unticked Follow build should keep compact live Build controls")
  assert_eq(gui.has_build_level_summary, false, "unticked Follow build should still keep live mode compact")
  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "enter-build-mode",
  })
  assert_eq(summary.build_mode, true, "editing the saved build should require Build mode")
  gui = call("installed_gui_contract", turret)
  assert_eq(gui.build_controls_type, "frame", "re-entered Build mode should use the planning frame again")
  assert_eq(gui.has_auto_checkbox, false, "Follow build should stay hidden after re-entering Build mode")
  assert_eq(gui.allocate_damage_enabled, true, "unticking Follow build should allow saved build edits after re-entering Build mode")
  assert_eq(gui.has_build_level_summary, true, "Build mode should restore build details after Follow build was unticked")
  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "allocate-base",
    upgrade = "damage",
  })
  assert_eq(summary.automation_target.base.damage, planned_damage + 1, "Build mode should allow build edits again")

  summary = call("set_profile", turret, {
    level = 5,
  })
  assert_eq(summary.level, 5, "test setup should raise the core enough to apply planned core ranks")
  summary = call("dispatch_click_action", turret, {
    turret_xp_action = "exit-build-mode",
  })
  assert_eq(summary.build_mode, false, "Follow build should start from live mode")
  summary = call("dispatch_checked_action", turret, {
    turret_xp_action = "toggle-build-auto",
  }, true)
  assert_eq(summary.automation_enabled, true, "open-ended forever targets should keep Auto enabled")
  assert_ge(summary.evolution.base.damage or 0, 1, "Follow build should spend toward finite planned ranks")
  assert_ge(summary.evolution.base.shield or 0, 1, "Follow build should spend toward loop priorities")

  local recalc_turret = create_turret(surface, { 16, 0 }, 10)
  summary = call("install_core", recalc_turret, {
    level = 1,
  })
  assert_true(summary ~= nil, "failed to install recalculation test core")
  call("dispatch_click_action", recalc_turret, {
    turret_xp_action = "enter-build-mode",
  })
  call("dispatch_click_action", recalc_turret, {
    turret_xp_action = "allocate-base",
    upgrade = "damage",
  })
  call("dispatch_click_action", recalc_turret, {
    turret_xp_action = "exit-build-mode",
  })
  summary = call("dispatch_click_action", recalc_turret, {
    turret_xp_action = "allocate-base",
    upgrade = "shield",
  })
  assert_eq(summary.evolution.base.shield, 1, "manual off-path spending should still apply while Follow build is off")
  assert_eq(summary.automation_target.base.damage, 1, "manual off-path spending should not rewrite the saved target")
  assert_eq(summary.automation_target.level, 2, "manual off-path spending should recalculate required target level")
  summary = call("dispatch_checked_action", recalc_turret, {
    turret_xp_action = "toggle-build-auto",
  }, true)
  assert_eq(summary.automation_enabled, true, "off-path spending should not prevent resuming Follow build")
  assert_eq(summary.evolution.base.damage or 0, 0, "Follow build should wait when off-path spending consumed points")
  summary = call("set_profile", recalc_turret, {
    level = 2,
  })
  assert_eq(summary.automation_target.level, 2, "raising level should keep the recalculated required target")
  summary = call("apply_build_target", recalc_turret)
  assert_eq(summary.evolution.base.damage, 1, "Follow build should compensate after off-path spending unlocks enough level")
  assert_eq(summary.automation_enabled, false, "finite recalculated build should disable after it is satisfied")

  local priority_turret = create_turret(surface, { 18, 0 }, 10)
  summary = call("install_core", priority_turret, {
    level = 0,
  })
  assert_true(summary ~= nil, "failed to install finite-before-loop test core")
  call("dispatch_click_action", priority_turret, {
    turret_xp_action = "enter-build-mode",
  })
  call("dispatch_click_action", priority_turret, {
    turret_xp_action = "allocate-base",
    upgrade = "damage",
  })
  call("dispatch_click_action", priority_turret, {
    turret_xp_action = "allocate-base",
    upgrade = "damage",
  })
  call("dispatch_checked_action", priority_turret, {
    turret_xp_action = "toggle-base-forever",
    upgrade = "shield",
  }, true)
  call("dispatch_click_action", priority_turret, {
    turret_xp_action = "exit-build-mode",
  })
  call("set_profile", priority_turret, {
    level = 2,
  })
  summary = call("dispatch_checked_action", priority_turret, {
    turret_xp_action = "toggle-build-auto",
  }, true)
  assert_eq(summary.evolution.base.damage, 2, "Follow build should satisfy finite ranks before loop targets")
  assert_eq(summary.evolution.base.shield or 0, 0, "Follow build should not loop before finite ranks are satisfied")
  summary = call("set_profile", priority_turret, {
    level = 3,
  })
  assert_eq(summary.level, 3, "test setup should add a leftover point for loop spending")
  summary = call("apply_build_target", priority_turret)
  assert_eq(summary.evolution.base.shield, 1, "Follow build should spend leftover points toward loop targets")

  local ctrl_turret = create_turret(surface, { 22, 0 }, 10)
  summary = call("install_core", ctrl_turret, {
    level = gates.augments + 10,
  })
  assert_true(summary ~= nil, "failed to install ctrl-click planning test core")
  call("dispatch_click_action", ctrl_turret, {
    turret_xp_action = "enter-build-mode",
  })
  call("dispatch_click_action", ctrl_turret, {
    turret_xp_action = "choose-specialization",
    specialization = "sniper",
  })
  summary = call("dispatch_click_action", ctrl_turret, {
    turret_xp_action = "allocate-base",
    upgrade = "damage",
  }, {
    control = true,
  })
  assert_eq(
    summary.automation_target.base.damage,
    gates.augments + 10,
    "Build mode Ctrl-click should fill core ranks up to the current build-level budget"
  )
  summary = call("dispatch_click_action", ctrl_turret, {
    turret_xp_action = "allocate-augment",
    augment = "repair",
  }, {
    control = true,
  })
  assert_eq(summary.automation_target.augments.repair, 2, "Build mode Ctrl-click should fill available augment points")

  local finite_turret = create_turret(surface, { 20, 0 }, 10)
  summary = call("install_core", finite_turret, {
    level = 0,
  })
  assert_true(summary ~= nil, "failed to install finite build test core")
  call("dispatch_click_action", finite_turret, {
    turret_xp_action = "enter-build-mode",
  })
  call("dispatch_click_action", finite_turret, {
    turret_xp_action = "allocate-base",
    upgrade = "damage",
  })
  call("dispatch_click_action", finite_turret, {
    turret_xp_action = "exit-build-mode",
  })
  call("dispatch_checked_action", finite_turret, {
    turret_xp_action = "toggle-build-auto",
  }, true)
  summary = call("set_profile", finite_turret, {
    level = 1,
  })
  assert_eq(summary.automation_enabled, true, "finite build should keep Auto on until the target can be applied")
  summary = call("apply_build_target", finite_turret)
  assert_eq(summary.evolution.base.damage, 1, "Auto should spend the finite planned rank")
  assert_eq(summary.automation_enabled, false, "Auto should untick itself once a finite build path is satisfied")
  gui = call("installed_gui_contract", finite_turret)
  assert_eq(gui.has_auto_checkbox, false, "satisfied finite builds should hide the Follow build checkbox again")

  cleanup_turret(turret)
  cleanup_turret(recalc_turret)
  cleanup_turret(priority_turret)
  cleanup_turret(ctrl_turret)
  cleanup_turret(finite_turret)
end

function tests.run_core_request_lifecycle_test(surface)
  local turret = create_turret(surface, { 18, 0 }, 10)
  local status = call("set_core_request", turret, true)
  assert_eq(status.enabled, true, "empty turret should accept a Veteran Core request")
  assert_eq(status.host_request_core, true, "empty turret should persist the request flag")
  assert_true(status.requester_valid, "empty turret request should create a hidden logistic requester")
  assert_ge(status.active_count, 1, "hidden requester should be tracked for bounded refresh processing")

  local inserted = call("insert_requested_core", turret, {
    custom_name = "Delivered",
    level = 7,
    show_name_label = true,
  })
  assert_eq(inserted.inserted, 1, "test core should insert into the hidden requester")
  assert_eq(inserted.status.delivered_count, 1, "hidden requester should retain the delivered core until refresh")

  local refresh = call("process_core_requests", 64)
  assert_eq(refresh.installed, 1, "request refresh should install one delivered Veteran Core")
  assert_eq(refresh.active, 0, "delivered requester should be unregistered after installation")
  local summary = call("get_state", turret)
  assert_true(summary ~= nil, "delivered Veteran Core should be installed on the turret")
  assert_eq(summary.custom_name, "Delivered", "delivered Veteran Core should keep its profile name")
  assert_eq(summary.level, 7, "delivered Veteran Core should keep its profile level")
  assert_eq(summary.show_name_label, true, "delivered Veteran Core should keep its label settings")
  status = call("core_request_status", turret)
  assert_eq(status.enabled, false, "installed turret should not keep requesting another Veteran Core")
  assert_eq(status.requester_valid, false, "installed turret should not keep the hidden requester alive")
  cleanup_turret(turret)

  local cancelled_turret = create_turret(surface, { 20, 0 }, 10)
  status = call("set_core_request", cancelled_turret, true)
  assert_true(status.requester_valid, "cancel test setup should create a requester")
  local active_before_cancel = status.active_count
  status = call("set_core_request", cancelled_turret, false)
  assert_eq(status.enabled, false, "cancelled turret should clear the request flag")
  assert_eq(status.requester_valid, false, "cancelled turret should destroy its requester")
  assert_le(status.active_count, active_before_cancel - 1, "cancelled requester should be removed from refresh tracking")
  cleanup_turret(cancelled_turret)

  local removed_turret = create_turret(surface, { 22, 0 }, 10)
  status = call("set_core_request", removed_turret, true)
  assert_true(status.requester_valid, "remove test setup should create a requester")
  call("insert_requested_core", removed_turret, {
    custom_name = "Spill",
    level = 4,
  })
  call("cleanup_entity", removed_turret)
  status = call("core_request_status", removed_turret)
  assert_eq(status.requester_valid, false, "removing an empty requested turret should destroy its requester")
  assert_eq(status.host_request_core, false, "removing an empty requested turret should clear host request state")
  assert_ge(
    support.ground_item_count(surface, xy(22, 0), VETERAN_CORE, 2),
    1,
    "removing a requested turret should spill delivered cores instead of deleting them"
  )
  cleanup_turret(removed_turret)
end

function tests.run_empty_turret_gui_open_test(surface)
  local turret = create_turret(surface, { 18, 8 }, 10)
  local summary = call("open_gui_contract", turret)
  assert_true(summary.opened, "opening a pristine empty turret GUI should not crash")
  assert_true(summary.key ~= nil, "pristine vanilla turret core panel should receive a stable refresh key")
  assert_eq(summary.core_slot_enabled, true, "pristine empty turret should keep the core slot manually fillable")
  assert_eq(summary.core_slot_toggled, false, "pristine empty turret should not show the requested-core tint")
  assert_eq(summary.has_inventory_picker, true, "pristine empty turret should show the core picker")
  assert_eq(summary.has_core_request_checkbox, false, "pristine empty turret should not show a request checkbox")
  cleanup_turret(turret)
end

function tests.run_core_request_pressure_test(surface)
  local turrets = {}
  for index = 1, 80 do
    local row = math.floor((index - 1) / 10)
    local column = (index - 1) % 10
    local turret = create_turret(surface, {
      x = 24 + (column * 2),
      y = row * 2,
    }, 10)
    turrets[#turrets + 1] = turret
    local status = call("set_core_request", turret, true)
    assert_true(status.requester_valid, "pressure request " .. index .. " failed to create a requester")
  end

  local refresh = call("process_core_requests", 10)
  assert_eq(refresh.processed, 10, "core requester refresh should honor the configured per-tick processing cap")
  assert_eq(refresh.installed, 0, "empty requesters should not install cores")
  assert_ge(refresh.active, 80, "requesters should remain tracked while waiting for delivery")

  for _, turret in ipairs(turrets) do
    call("cleanup_entity", turret)
    if turret.valid then
      turret.destroy({ raise_destroy = false })
    end
  end
  local status = call("core_request_status", turrets[1])
  assert_eq(status.active_count, 0, "pressure test cleanup should remove every tracked requester")
end

function tests.run_target_build_policy_test(surface)
  local gates = call("progression_gates")
  local source_build = {
    base = {
      damage = 8,
      shield = 4,
      ammo_regen = 3,
    },
    augments = {
      repair = 2,
      veteran_training = 1,
    },
    elements = {
      "explosive",
      "fire",
    },
    element_mastery = {
      explosive = { rank = 3 },
      fire = { rank = 2 },
    },
    specialization = "sniper",
    sub_specialization = "sniper_deadeye",
  }
  local expected_target_level = call("target_required_level", source_build)
  local source_position = { 12, 12 }
  local source = create_turret(surface, source_position, 10)
  local summary = call("install_core", source, {
    custom_name = "Source Build",
    level = expected_target_level,
    show_label_level = true,
  })
  assert_true(summary ~= nil, "failed to install source core for target build testing")
  summary = call("set_evolution", source, source_build)
  assert_eq(summary.evolution.specialization, "sniper", "test setup should give the source a specialization")
  source = refresh_turret(surface, source_position)

  local policy = call("policy_from_entity", source)
  assert_eq(policy.request_core, true, "copied target build should request a fresh core for empty destinations")
  assert_eq(policy.custom_name, nil, "copied target build must not clone the source custom name")
  assert_eq(policy.level, nil, "copied target build must not clone source level as destination XP")
  assert_true(type(policy.automation_target) == "table", "copied policy should include an explicit target build")
  assert_eq(policy.automation_enabled, true, "copied target build should enable future auto-follow")
  assert_eq(policy.automation_target.level, expected_target_level, "target build should record the recalculated required build level")
  assert_eq(policy.automation_target.base.damage, 8, "target build should record source Damage rank")
  assert_eq(policy.automation_target.base.shield, 4, "target build should record source Shield rank")
  assert_eq(policy.automation_target.augments.repair, 2, "target build should record source augment ranks")
  assert_eq(policy.automation_target.specialization, "sniper", "target build should record source specialization")
  assert_eq(policy.automation_target.sub_specialization, "sniper_deadeye", "target build should record source sub-specialization")
  assert_eq(policy.automation_target.elements[1], "explosive", "target build should record source first element")
  assert_eq(policy.automation_target.elements[2], "fire", "target build should record source second element")
  assert_eq(policy.automation_target.element_mastery.explosive.rank, 3, "target build should record element rank goals")

  local blueprint = call("blueprint_setup_event_policy", source)
  local blueprint_policy = blueprint.tags[1] and blueprint.tags[1].turret_xp_policy or nil
  assert_eq(blueprint.written, 1, "blueprint setup event should write one Turret XP policy from lazy mapping")
  assert_true(type(blueprint_policy) == "table", "blueprint setup event should write a readable policy tag")
  assert_eq(blueprint_policy.request_core, true, "blueprint setup event should request a fresh core for empty copies")
  assert_eq(blueprint_policy.custom_name, nil, "blueprint setup event must not clone the source custom name")
  assert_eq(blueprint_policy.level, nil, "blueprint setup event must not clone source level as destination XP")
  assert_eq(
    blueprint_policy.automation_target.level,
    expected_target_level,
    "blueprint setup event should preserve the recalculated target level"
  )
  assert_eq(blueprint_policy.automation_target.specialization, "sniper", "blueprint setup event should preserve target specialization")

  local direct_blueprint = call("blueprint_setup_event_policy", source, true)
  assert_eq(direct_blueprint.written, 1, "blueprint setup event should still accept a direct table mapping")

  local destination_position = { 14, 12 }
  local destination = create_turret(surface, destination_position, 10)
  local pasted = call("paste_policy", source, destination)
  assert_eq(pasted.applied, true, "target policy should paste to an empty destination turret")
  assert_eq(pasted.request.enabled, true, "target policy should request a core on the empty destination")
  assert_eq(pasted.request.has_pending_policy, true, "target policy should wait on the destination until a core is delivered")
  local gui = call("open_gui_contract", destination)
  assert_true(gui.opened, "empty pasted target build GUI should open without crashing")
  assert_eq(gui.core_status_caption[1], "turret-xp.core-requested", "empty pasted target build should show a requested core slot")
  assert_eq(gui.core_slot_enabled, true, "requested copied-build core slot should still accept manual placement")
  assert_eq(gui.core_slot_sprite, "item/turret-xp-veteran-core", "requested copied-build core slot should show a ghost core")
  assert_eq(gui.core_slot_toggled, true, "requested copied-build core slot should keep the blue requested tint")
  assert_eq(
    gui.core_slot_style,
    "turret_xp_pending_core_slot_button",
    "requested copied-build core slot should use the pending request style"
  )
  assert_eq(gui.has_core_request_checkbox, false, "empty pasted target build should not show a request checkbox")
  assert_eq(gui.has_inventory_picker, false, "empty pasted target build should not show the core picker")

  local pre_specialization_level = math.max(0, (gates.specialization or 0) - 1)
  call("insert_requested_core", destination, {
    custom_name = "Fresh Copy",
    level = pre_specialization_level,
  })
  local refresh = call("process_core_requests", 64)
  assert_eq(refresh.installed, 1, "target policy destination should install a delivered core")
  destination = refresh_turret(surface, destination_position)
  summary = call("get_state", destination)
  assert_eq(summary.custom_name, "Fresh Copy", "target policy must preserve delivered core identity")
  assert_eq(summary.level, pre_specialization_level, "target policy must preserve delivered core level")
  assert_eq(summary.build_mode, false, "delivered copied builds should start in live mode")
  assert_eq(summary.automation_enabled, true, "delivered core should follow the copied target")
  assert_true(type(summary.automation_target) == "table", "delivered core should store the copied target")
  assert_eq(summary.automation_target.level, expected_target_level, "delivered core should retain the copied required target level")
  if pre_specialization_level < gates.specialization then
    assert_eq(summary.evolution.specialization, nil, "pre-gate core should not receive the specialization early")
  else
    assert_eq(summary.evolution.specialization, "sniper", "gate-zero specialization should apply immediately")
  end
  assert_le(summary.evolution.base.damage or 0, policy.automation_target.base.damage, "target follower must not overrun Damage")
  assert_le(summary.evolution.base.shield or 0, policy.automation_target.base.shield, "target follower must not overrun Shield")
  assert_le(
    summary.evolution.base.ammo_regen or 0,
    policy.automation_target.base.ammo_regen,
    "target follower must not overrun Ammo Productivity"
  )
  assert_eq(
    table_sum(summary.evolution.base),
    math.min(pre_specialization_level, table_sum(policy.automation_target.base)),
    "pre-gate target follower should spend available core points toward copied target ranks"
  )

  summary = call("set_profile", destination, {
    level = expected_target_level,
  })
  assert_eq(summary.level, expected_target_level, "test level update should raise the delivered core")
  local apply_summary = call("apply_build_target", destination)
  assert_true(apply_summary ~= nil, "target follower should apply after gaining levels")
  destination = refresh_turret(surface, destination_position)
  summary = call("get_state", destination)
  assert_eq(summary.evolution.specialization, "sniper", "target follower should choose specialization when the gate unlocks")
  assert_eq(
    summary.evolution.sub_specialization,
    "sniper_deadeye",
    "target follower should choose sub-specialization when the gate unlocks"
  )
  assert_eq(summary.evolution.elements[1], "explosive", "target follower should choose the first copied element")
  assert_eq(summary.evolution.elements[2], "fire", "target follower should choose the second copied element")
  assert_eq(summary.evolution.base.damage, 8, "target follower should reach target Damage rank")
  assert_eq(summary.evolution.base.shield, 4, "target follower should reach target Shield rank")
  assert_eq(summary.evolution.base.ammo_regen, 3, "target follower should reach target Ammo Productivity rank")
  assert_eq(summary.evolution.augments.repair, 2, "target follower should reach target Regeneration rank")
  assert_eq(summary.evolution.augments.veteran_training, 1, "target follower should reach target Veteran Training rank")
  assert_ge(summary.evolution.available_core_points, 1, "target follower should stop spending once target core ranks are reached")
  assert_eq(summary.automation_enabled, false, "finite target follower should untick Auto after satisfying the copied build")
  assert_true(summary.automation_target_model ~= nil, "target follower should expose a GUI-ready target model")

  local manual_destination_position = { 18, 12 }
  local manual_destination = create_turret(surface, manual_destination_position, 10)
  pasted = call("paste_policy", source, manual_destination)
  assert_eq(pasted.applied, true, "target policy should paste to a manually filled empty destination")
  assert_eq(pasted.request.enabled, true, "manual fill destination should create the pending copied-core request")
  local manual = call("dispatch_core_slot_cursor_install", manual_destination, {
    custom_name = "Manual Copy",
    level = pre_specialization_level,
  })
  assert_eq(manual.cursor_has_stack, false, "manual core placement should consume the carried Veteran Core")
  assert_eq(manual.request.enabled, false, "manual core placement should clear the pending logistic request")
  assert_eq(manual.request.has_pending_policy, false, "manual core placement should consume the pending copied policy")
  manual_destination = refresh_turret(surface, manual_destination_position)
  summary = call("get_state", manual_destination)
  assert_eq(summary.custom_name, "Manual Copy", "manual pending-slot install must preserve the carried core identity")
  assert_eq(summary.build_mode, false, "manual pending-slot install should start in live mode")
  assert_eq(summary.automation_enabled, true, "manual pending-slot install should keep following the copied target")
  assert_eq(summary.automation_target.level, expected_target_level, "manual pending-slot install should keep the copied target")

  local conflict_turret = create_turret(surface, { 20, 12 }, 10)
  summary = call("install_core", conflict_turret, {
    level = expected_target_level,
  })
  assert_true(summary ~= nil, "failed to install conflict test core")
  summary = call("set_evolution", conflict_turret, {
    specialization = "bulwark",
  })
  assert_eq(summary.evolution.specialization, "bulwark", "conflict setup should choose a manual specialization")
  conflict_turret = refresh_turret(surface, { 20, 12 })
  local applied = call("apply_policy", conflict_turret, policy)
  assert_eq(applied.applied, true, "target policy should apply to installed cores")
  summary = call("get_state", conflict_turret)
  assert_eq(summary.evolution.specialization, "bulwark", "target build must not overwrite conflicting manual specialization")
  assert_eq(summary.automation_conflict, true, "target build should surface conflicting manual choices")

  cleanup_turret(source)
  cleanup_turret(destination)
  cleanup_turret(manual_destination)
  cleanup_turret(conflict_turret)
end

function tests.run_copy_policy_test(surface)
  local copied_build = {
    base = {
      damage = 6,
      ammo_regen = 4,
    },
    augments = {
      double_shot = 1,
    },
    specialization = "machine_gun",
    sub_specialization = "machine_sustained",
  }
  local copied_build_level = call("target_required_level", copied_build)
  local source_position = { 12, 4 }
  local source = create_turret(surface, source_position, 10)
  local summary = call("install_core", source, {
    custom_name = "Source",
    level = copied_build_level,
    show_name_label = true,
    show_label_level = true,
    show_unspent_label = true,
    label_color = { 0.12, 0.34, 0.56 },
    label_color_preset = "custom",
    bound_turret = true,
  })
  assert_true(summary ~= nil, "failed to install a source core for policy copy testing")
  summary = call("set_evolution", source, copied_build)
  assert_eq(summary.evolution.specialization, "machine_gun", "test setup should give the source an explicit build")
  assert_eq(summary.bound_turret, true, "test setup should keep the source bound")
  source = refresh_turret(surface, source_position)

  local policy = call("policy_from_entity", source)
  assert_eq(policy.request_core, true, "policy copied from an installed turret should request a core for empty copies")
  assert_eq(policy.automation_enabled, true, "policy should include automation enabled state")
  assert_eq(policy.bound_turret, true, "policy should include bound turret state")
  assert_eq(policy.automation_target.specialization, "machine_gun", "policy should include the copied specialization target")
  assert_eq(policy.automation_target.base.damage, 6, "policy should include copied core rank targets")
  assert_eq(policy.show_name_label, true, "policy should include name-label visibility")
  assert_eq(policy.show_label_level, true, "policy should include level-label visibility")
  assert_eq(policy.show_unspent_label, true, "policy should include unspent-label visibility")
  assert_eq(policy.level, nil, "copy policy must not clone source XP level")
  assert_eq(policy.xp, nil, "copy policy must not clone source XP")
  assert_eq(policy.custom_name, nil, "copy policy must not clone source custom name")

  local destination_position = { 14, 4 }
  local destination = create_turret(surface, destination_position, 10)
  local pasted = call("paste_policy", source, destination)
  assert_eq(pasted.applied, true, "copy/paste policy should apply to an empty destination turret")
  assert_eq(pasted.request.enabled, true, "empty destination should start requesting a Veteran Core")
  assert_eq(pasted.request.has_pending_policy, true, "empty destination should retain policy until a core is delivered")
  call("insert_requested_core", destination, {
    custom_name = "Delivered Copy",
    level = copied_build_level,
  })
  local refresh = call("process_core_requests", 64)
  assert_eq(refresh.installed, 1, "pending policy destination should install the delivered core")
  destination = refresh_turret(surface, destination_position)
  summary = call("get_state", destination)
  assert_eq(summary.custom_name, "Delivered Copy", "policy installation should not overwrite the delivered core name")
  assert_eq(summary.show_name_label, true, "pending policy should apply name-label visibility to the delivered core")
  assert_eq(summary.show_label_level, true, "pending policy should apply level-label visibility to the delivered core")
  assert_eq(summary.show_unspent_label, true, "pending policy should apply unspent-label visibility to the delivered core")
  assert_eq(summary.bound_turret, true, "pending policy should apply copied bound state to the delivered core")
  assert_eq(summary.automation_enabled, false, "satisfied finite copied build should untick Auto after delivery")
  assert_eq(summary.evolution.specialization, "machine_gun", "pending policy should apply copied build specialization")
  assert_eq(summary.evolution.sub_specialization, "machine_sustained", "pending policy should apply copied build sub-specialization")
  assert_eq(summary.evolution.base.damage, 6, "pending policy should spend copied core rank targets")
  assert_eq(summary.evolution.base.ammo_regen, 4, "pending policy should spend every copied core rank target")

  local installed_destination = create_turret(surface, { 16, 4 }, 10)
  summary = call("install_core", installed_destination, {
    level = 2,
  })
  assert_true(summary ~= nil, "failed to install destination core for direct policy testing")
  local applied = call("apply_policy", installed_destination, {
    show_name_label = true,
    show_label_level = true,
    bound_turret = true,
    label_color = { 0.9, 0.1, 0.1 },
    label_color_preset = "custom",
  })
  assert_eq(applied.applied, true, "label-only policy should apply to an installed turret")
  assert_true(applied.state.name_render_valid, "label-only policy should refresh the installed turret render object")
  assert_eq(applied.state.label_text, "Lvl 2", "label-only policy should update installed turret label text")
  assert_eq(applied.state.bound_turret, true, "policy should apply copied bound state to installed turrets")
  cleanup_turret(source)
  cleanup_turret(destination)
  cleanup_turret(installed_destination)
end

function tests.run_gui_dispatch_contract_test(surface)
  local unspent_level = call("target_required_level", {
    augments = {
      repair = 2,
    },
  })
  local apply_turret = create_turret(surface, { 18, 4 }, 10)
  local summary = call("install_core", apply_turret, {
    level = unspent_level,
  })
  assert_true(summary ~= nil, "failed to install a core for automation GUI dispatch testing")

  summary = call("dispatch_toggle_label_unspent", apply_turret, true)
  assert_eq(summary.show_unspent_label, true, "GUI unspent-label toggle should update the profile")
  assert_eq(summary.label_text, unspent_label_for_profile(summary), "GUI unspent-label toggle should refresh label text")

  summary = call("dispatch_click_action", apply_turret, {
    turret_xp_action = "enter-build-mode",
  })
  assert_eq(summary.build_mode, true, "GUI Enter button should enter Build mode")
  summary = call("dispatch_click_action", apply_turret, {
    turret_xp_action = "allocate-base",
    upgrade = "damage",
  })
  assert_eq(summary.automation_target.base.damage, 1, "GUI rank button should edit the build path in Build mode")
  summary = call("dispatch_click_action", apply_turret, {
    turret_xp_action = "exit-build-mode",
  })
  assert_eq(summary.build_mode, false, "GUI Exit button should leave Build mode before Follow build starts")
  summary = call("dispatch_checked_action", apply_turret, {
    turret_xp_action = "toggle-build-auto",
  }, true)
  assert_eq(summary.evolution.base.damage, 1, "GUI Auto checkbox should apply the planned finite rank")
  assert_eq(summary.automation_enabled, false, "GUI Auto checkbox should untick after satisfying a finite build path")
  cleanup_turret(apply_turret)

  local auto_position = { 20, 4 }
  local auto_turret = create_turret(surface, auto_position, 10)
  summary = call("install_core", auto_turret, {
    level = unspent_level,
  })
  assert_true(summary ~= nil, "failed to install a core for automation Auto GUI dispatch testing")
  call("dispatch_click_action", auto_turret, {
    turret_xp_action = "enter-build-mode",
  })
  call("dispatch_checked_action", auto_turret, {
    turret_xp_action = "toggle-base-forever",
    upgrade = "shield",
  }, true)
  call("dispatch_click_action", auto_turret, {
    turret_xp_action = "exit-build-mode",
  })
  local auto_summary = call("dispatch_checked_action", auto_turret, {
    turret_xp_action = "toggle-build-auto",
  }, true)
  assert_true(auto_summary ~= nil, "GUI Auto checkbox dispatch did not return a summary")
  auto_turret = refresh_turret(surface, auto_position)
  summary = call("get_state", auto_turret)
  assert_eq(summary.automation_enabled, true, "GUI Auto checkbox should stay enabled for open-ended builds")
  assert_eq(summary.automation_target.base_infinite.shield, true, "GUI loop checkbox should preserve forever targets")
  assert_ge(summary.evolution.base.shield or 0, 1, "GUI Auto checkbox should spend toward forever targets")
  cleanup_turret(auto_turret)
end

return tests
