local support = require("support")

local assert_true = support.assert_true
local assert_eq = support.assert_eq
local assert_ge = support.assert_ge
local assert_le = support.assert_le
local assert_contains = support.assert_contains
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

  local unspent_only = call("label_text_sample", {
    level = 40,
    show_unspent_label = true,
  })
  assert_eq(unspent_only.text, "Core +40 / Aug +2", "unspent-only label should summarize both point pools")

  local combined = call("label_text_sample", {
    custom_name = "Alpha",
    level = 40,
    show_name_label = true,
    show_label_level = true,
    show_unspent_label = true,
  })
  assert_eq(combined.text, "Alpha - Lvl 40 - Core +40 / Aug +2", "three-part labels should remain deterministic and readable")

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

function tests.run_automation_preset_test(surface)
  local presets = call("automation_presets")
  assert_contains(presets, "manual", "automation preset list should include Manual")
  assert_contains(presets, "balanced", "automation preset list should include Balanced")
  assert_contains(presets, "sniper", "automation preset list should include Sniper")
  assert_contains(presets, "machine_gun", "automation preset list should include Machine gun")
  assert_contains(presets, "bulwark", "automation preset list should include Bulwark")
  assert_contains(presets, "brawler", "automation preset list should include Brawler")

  local turret = create_turret(surface, { 14, 0 }, 10)
  local summary = call("install_core", turret, {
    level = 50,
  })
  assert_true(summary ~= nil, "failed to install a core for automation preset testing")

  local apply_summary = call("apply_automation", turret, "sniper", true, true)
  assert_true(apply_summary ~= nil, "automation apply did not return a summary")
  turret = refresh_turret(surface, { 14, 0 })
  summary = call("get_state", turret)
  assert_eq(summary.automation_preset, "sniper", "automation preset should persist on the profile")
  assert_eq(summary.automation_enabled, true, "automation enabled flag should persist on the profile")
  assert_eq(summary.automation_conflict, false, "first automation pass should not report a conflict")
  assert_eq(summary.evolution.specialization, "sniper", "sniper preset should pick the sniper specialization")
  assert_eq(summary.evolution.sub_specialization, "sniper_deadeye", "sniper preset should pick its sub-specialization")
  assert_eq(summary.evolution.elements[1], "explosive", "sniper preset should choose the first configured element")
  assert_eq(summary.evolution.elements[2], "fire", "sniper preset should choose the second configured element")
  assert_eq(summary.evolution.available_core_points, 0, "automation should spend all currently available base points")
  assert_eq(summary.evolution.available_augment_points, 0, "automation should spend all currently available augment points")
  assert_ge(summary.evolution.base.damage or 0, 1, "sniper preset should invest in damage")
  assert_ge(summary.evolution.augments.luck or 0, 1, "sniper preset should invest in luck first")
  assert_ge(summary.evolution.augments.veteran_training or 0, 1, "sniper preset should invest in veteran training second")

  local conflict_turret = create_turret(surface, { 16, 0 }, 10)
  summary = call("install_core", conflict_turret, {
    level = 40,
  })
  assert_true(summary ~= nil, "failed to install a core for automation conflict testing")
  summary = call("set_evolution", conflict_turret, {
    specialization = "bulwark",
  })
  assert_eq(summary.evolution.specialization, "bulwark", "test setup failed to choose the conflicting specialization")

  conflict_turret = refresh_turret(surface, { 16, 0 })
  apply_summary = call("apply_automation", conflict_turret, "sniper", true, true)
  assert_true(apply_summary ~= nil, "conflicting automation apply did not return a summary")
  conflict_turret = refresh_turret(surface, { 16, 0 })
  summary = call("get_state", conflict_turret)
  assert_eq(summary.evolution.specialization, "bulwark", "automation must not overwrite a manual specialization")
  assert_eq(summary.automation_conflict, true, "automation should surface a conflict when it preserves manual choices")
  assert_eq(summary.evolution.available_core_points, 0, "automation should still spend non-conflicting base points")
  cleanup_turret(turret)
  cleanup_turret(conflict_turret)
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

function tests.run_copy_policy_test(surface)
  local source_position = { 12, 4 }
  local source = create_turret(surface, source_position, 10)
  local summary = call("install_core", source, {
    custom_name = "Source",
    level = 40,
    show_name_label = true,
    show_label_level = true,
    show_unspent_label = true,
    label_color = { 0.12, 0.34, 0.56 },
    label_color_preset = "custom",
  })
  assert_true(summary ~= nil, "failed to install a source core for policy copy testing")
  call("apply_automation", source, "machine_gun", true, true)
  source = refresh_turret(surface, source_position)

  local policy = call("policy_from_entity", source)
  assert_eq(policy.request_core, true, "policy copied from an installed turret should request a core for empty copies")
  assert_eq(policy.automation_preset, "machine_gun", "policy should include automation preset")
  assert_eq(policy.automation_enabled, true, "policy should include automation enabled state")
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
    level = 40,
  })
  local refresh = call("process_core_requests", 64)
  assert_eq(refresh.installed, 1, "pending policy destination should install the delivered core")
  destination = refresh_turret(surface, destination_position)
  summary = call("get_state", destination)
  assert_eq(summary.custom_name, "Delivered Copy", "policy installation should not overwrite the delivered core name")
  assert_eq(summary.show_name_label, true, "pending policy should apply name-label visibility to the delivered core")
  assert_eq(summary.show_label_level, true, "pending policy should apply level-label visibility to the delivered core")
  assert_eq(summary.show_unspent_label, true, "pending policy should apply unspent-label visibility to the delivered core")
  assert_eq(summary.automation_preset, "machine_gun", "pending policy should apply automation preset to the delivered core")
  assert_eq(summary.automation_enabled, true, "pending policy should apply automation enabled state to the delivered core")
  assert_eq(summary.evolution.specialization, "machine_gun", "pending policy should apply automation to the delivered core")
  assert_eq(summary.evolution.sub_specialization, "machine_sustained", "pending policy should choose the preset sub-specialization")
  assert_eq(summary.evolution.available_core_points, 0, "pending policy automation should spend delivered core points")

  local installed_destination = create_turret(surface, { 16, 4 }, 10)
  summary = call("install_core", installed_destination, {
    level = 2,
  })
  assert_true(summary ~= nil, "failed to install destination core for direct policy testing")
  local applied = call("apply_policy", installed_destination, {
    show_name_label = true,
    show_label_level = true,
    label_color = { 0.9, 0.1, 0.1 },
    label_color_preset = "custom",
  })
  assert_eq(applied.applied, true, "label-only policy should apply to an installed turret")
  assert_true(applied.state.name_render_valid, "label-only policy should refresh the installed turret render object")
  assert_eq(applied.state.label_text, "Lvl 2", "label-only policy should update installed turret label text")
  cleanup_turret(source)
  cleanup_turret(destination)
  cleanup_turret(installed_destination)
end

function tests.run_gui_dispatch_contract_test(surface)
  local apply_turret = create_turret(surface, { 18, 4 }, 10)
  local summary = call("install_core", apply_turret, {
    level = 40,
  })
  assert_true(summary ~= nil, "failed to install a core for automation GUI dispatch testing")

  summary = call("dispatch_toggle_label_unspent", apply_turret, true)
  assert_eq(summary.show_unspent_label, true, "GUI unspent-label toggle should update the profile")
  assert_eq(summary.label_text, "Core +40 / Aug +2", "GUI unspent-label toggle should refresh label text")

  summary = call("dispatch_select_automation", apply_turret, "balanced")
  assert_eq(summary.automation_preset, "balanced", "GUI automation dropdown should store the selected preset")
  assert_eq(summary.automation_enabled, false, "choosing a preset should not enable Auto by itself")
  assert_eq(summary.evolution.available_core_points, 40, "choosing a preset without Auto should not spend points")

  summary = call("dispatch_apply_automation", apply_turret)
  assert_eq(summary.automation_preset, "balanced", "GUI Apply should keep the selected preset")
  assert_eq(summary.automation_enabled, false, "GUI Apply should remain a one-shot action when Auto is off")
  assert_eq(summary.evolution.available_core_points, 0, "GUI Apply should spend currently available base points")
  assert_eq(summary.evolution.available_augment_points, 0, "GUI Apply should spend currently available augment points")
  cleanup_turret(apply_turret)

  local auto_position = { 20, 4 }
  local auto_turret = create_turret(surface, auto_position, 10)
  summary = call("install_core", auto_turret, {
    level = 40,
  })
  assert_true(summary ~= nil, "failed to install a core for automation Auto GUI dispatch testing")
  summary = call("dispatch_select_automation", auto_turret, "bulwark")
  assert_eq(summary.automation_preset, "bulwark", "GUI automation dropdown should select Bulwark")
  local auto_summary = call("dispatch_toggle_automation", auto_turret, true)
  assert_true(auto_summary ~= nil, "GUI Auto checkbox dispatch did not return a summary")
  auto_turret = refresh_turret(surface, auto_position)
  summary = call("get_state", auto_turret)
  assert_eq(summary.automation_enabled, true, "GUI Auto checkbox should enable automation for non-manual presets")
  assert_eq(summary.evolution.specialization, "bulwark", "GUI Auto checkbox should apply the selected preset")
  assert_eq(summary.evolution.available_core_points, 0, "GUI Auto checkbox should spend available points immediately")
  cleanup_turret(auto_turret)

  local request_turret = create_turret(surface, { 22, 4 }, 10)
  local status = call("dispatch_toggle_core_request", request_turret, true)
  assert_eq(status.enabled, true, "GUI core-request checkbox should enable requests for empty turrets")
  assert_true(status.requester_valid, "GUI core-request checkbox should create a hidden requester")
  status = call("dispatch_toggle_core_request", request_turret, false)
  assert_eq(status.enabled, false, "GUI core-request checkbox should disable requests")
  assert_eq(status.requester_valid, false, "GUI core-request checkbox should destroy the hidden requester")
  cleanup_turret(request_turret)
end

return tests
