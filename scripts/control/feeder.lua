local feeder_inventory = require("scripts.control.feeder_inventory")
local feeder_inserters = require("scripts.control.feeder_inserters")
local feeder_lifecycle = require("scripts.control.feeder_lifecycle")
local feeder_refresh = require("scripts.control.feeder_refresh")

local feeder_module = {}

local function copy_exports(target, source, names)
  for _, name in ipairs(names) do
    target[name] = source[name]
  end
end

function feeder_module.new(deps)
  local feeder = {}
  local compat = deps.compat
  local inventory_defines = deps.inventory_defines
  local safe_read = deps.safe_read
  local ensure_storage = deps.ensure_storage
  local storage_root = deps.storage_root
  local ensure_evolution_state = deps.ensure_evolution_state
  local get_unique_active_element_ids = deps.get_unique_active_element_ids
  local get_element_remaining_requirement = deps.get_element_remaining_requirement
  local is_gun_turret = deps.is_gun_turret
  local item_prototypes = deps.item_prototypes

  local inventory = feeder_inventory.new({
    compat = compat,
    inventory_defines = inventory_defines,
    safe_read = safe_read,
    ensure_evolution_state = ensure_evolution_state,
    get_unique_active_element_ids = get_unique_active_element_ids,
    get_element_remaining_requirement = get_element_remaining_requirement,
    is_gun_turret = is_gun_turret,
    item_prototypes = item_prototypes,
    input_buffer_slots = deps.feeder_input_buffer_slots,
    ensure_feeder = function(entity, state)
      return feeder.ensure(entity, state)
    end,
    destroy_feeder = function(state, position, spill)
      return feeder.destroy(state, position, spill)
    end,
    update_nearby_inserters = function(turret, state)
      return feeder.update_nearby_inserters(turret, state)
    end,
  })
  copy_exports(feeder, inventory, {
    "get_entity_inventory",
    "get_inventory",
    "spill_stack",
    "spill_inventory_contents",
    "spill_contents",
    "get_allowed_items",
    "allowed_item_names",
    "needs_input",
    "should_exist",
    "set_input_open",
    "get_total_input_slots",
    "get_input_slot_count",
    "inventory_is_empty",
    "remove_items",
    "make_item_stack",
    "is_ammo_item",
    "route_contents",
  })

  local inserters = feeder_inserters.new({
    safe_read = safe_read,
    ensure_storage = ensure_storage,
    storage_root = storage_root,
    is_gun_turret = is_gun_turret,
    get_allowed_items = function(state)
      return feeder.get_allowed_items(state)
    end,
    allowed_item_names = function(state)
      return feeder.allowed_item_names(state)
    end,
  })
  copy_exports(feeder, inserters, {
    "filter_name",
    "get_inserter_filter_slot_count",
    "read_inserter_filters",
    "inserter_filters_match_allowed",
    "set_inserter_drop_target",
    "drop_position_matches_turret",
    "inserter_points_at_turret",
    "transport_line_has_item",
    "entity_has_item",
    "ground_has_item",
    "pickup_area_has_item",
    "inserter_source_has_allowed_item",
    "inserter_source_has_item",
    "prioritize_item_names_for_inserter",
    "capture_managed_inserter",
    "track_managed_inserter",
    "managed_inserter_matches_state",
    "apply_inserter_filters",
    "restore_inserter_filters",
    "restore_managed_inserters_for_state",
  })

  local refresh = feeder_refresh.new({
    safe_read = safe_read,
    ensure_storage = ensure_storage,
    storage_root = storage_root,
    is_gun_turret = is_gun_turret,
    inserter_radius = deps.feeder_inserter_radius,
    inserters = inserters,
    get_allowed_items = function(state)
      return feeder.get_allowed_items(state)
    end,
    needs_input = function(state)
      return feeder.needs_input(state)
    end,
    game_tick = function()
      return game and game.tick or nil
    end,
  })
  feeder.update_nearby_inserters = refresh.update_nearby_inserters
  feeder.get_last_refresh_stats = refresh.get_last_refresh_stats

  local lifecycle = feeder_lifecycle.new({
    feeder_name = deps.feeder_name,
    ensure_storage = ensure_storage,
    storage_root = storage_root,
    is_gun_turret = is_gun_turret,
    get_inventory = feeder.get_inventory,
    spill_contents = feeder.spill_contents,
    set_input_open = feeder.set_input_open,
    get_input_slot_count = feeder.get_input_slot_count,
    inventory_is_empty = feeder.inventory_is_empty,
    needs_input = feeder.needs_input,
    should_exist = feeder.should_exist,
    restore_managed_inserters_for_state = feeder.restore_managed_inserters_for_state,
    update_nearby_inserters = feeder.update_nearby_inserters,
  })
  feeder.destroy = lifecycle.destroy
  feeder.find_position = lifecycle.find_position
  feeder.ensure = lifecycle.ensure

  return feeder
end

return feeder_module
