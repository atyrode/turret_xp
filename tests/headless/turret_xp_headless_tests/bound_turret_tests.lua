local support = require("support")

local assert_true = support.assert_true
local assert_eq = support.assert_eq
local assert_gt = support.assert_gt
local inventory_count = support.inventory_count
local ground_item_count = support.ground_item_count
local find_ground_stack = support.find_ground_stack
local find_stack = support.find_stack
local create_turret = support.create_turret
local require_turret_near = support.require_turret_near
local call = support.call

local tests = {}
function tests.run_bound_turret_test(surface)
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
  assert_eq(preview_stack.name, preview_item_name, "bound turret stack did not use the matching specialization preview item")

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

function tests.run_bound_turret_mining_ammo_conservation_test(surface)
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

return tests
