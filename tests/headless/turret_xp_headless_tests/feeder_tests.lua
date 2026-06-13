local support = require("support")

local assert_true = support.assert_true
local assert_eq = support.assert_eq
local assert_gt = support.assert_gt
local assert_contains = support.assert_contains
local create_turret = support.create_turret
local call = support.call

local tests = {}
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

function tests.run_feeder_material_progress_test(surface)
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

function tests.run_feeder_contract_test(surface)
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
  local refresh_stats = call("feeder_refresh_stats")
  assert_true((refresh_stats.scanned or 0) >= 1, "feeder refresh did not record scanned inserters")
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
  refresh_stats = call("feeder_refresh_stats")
  assert_true((refresh_stats.pointed_to_feeder or 0) >= 1, "feeder refresh did not record feeder-targeted inserters")
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

function tests.run_dual_element_feeder_test(surface)
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

return tests
