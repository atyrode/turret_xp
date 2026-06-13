local M = {}

require("scripts.control.config")(M)
require("scripts.control.storage")(M)

local compat = require("scripts.control.compat")
M.compat = compat.new({
  diagnostics_enabled = function()
    return M.compat_diagnostics_enabled()
  end,
})
M.safe_read = function(object, property, fallback, context)
  return M.compat.safe_read(object, property, fallback, context)
end

require("scripts.control.progression")(M)
require("scripts.control.profiles")(M)
require("scripts.control.turret_bodies")(M)
require("scripts.control.gui_base")(M)

local feeder = require("scripts.control.feeder")
M.feeder = feeder.new({
  compat = M.compat,
  inventory_defines = defines.inventory,
  safe_read = M.safe_read,
  ensure_storage = function()
    return M.ensure_storage()
  end,
  storage_root = function()
    return storage and storage.turret_xp or nil
  end,
  ensure_evolution_state = function(state)
    return M.ensure_evolution_state(state)
  end,
  get_unique_active_element_ids = function(state)
    return M.get_unique_active_element_ids(state)
  end,
  get_element_remaining_requirement = function(state, element_id)
    return M.get_element_remaining_requirement(state, element_id)
  end,
  is_gun_turret = function(entity)
    return M.is_gun_turret(entity)
  end,
  item_prototypes = function()
    return prototypes.item
  end,
  feeder_name = M.FEEDER_NAME,
  feeder_inserter_radius = M.FEEDER_INSERTER_RADIUS,
  feeder_input_buffer_slots = M.FEEDER_INPUT_BUFFER_SLOTS,
})

local stats = require("scripts.control.stats")
M.stats = stats.new({
  target_damage_ttl = M.TARGET_DAMAGE_TTL,
  ensure_storage = function()
    return M.ensure_storage()
  end,
  storage_root = function()
    return storage and storage.turret_xp or nil
  end,
  game_tick = function()
    return game.tick
  end,
  safe_read = M.safe_read,
  entity_tracking_key = M.entity_tracking_key,
  turret_key = M.turret_key,
  is_gun_turret = M.is_gun_turret,
  get_turret_state = M.get_turret_state,
  combat = M.combat,
  add_profile_kill_credit = M.add_profile_kill_credit,
  sync_turret_progression = M.sync_turret_progression,
  update_name_render = M.update_name_render,
  ensure_evolution_state = M.ensure_evolution_state,
  get_specialized_turret_name = M.get_specialized_turret_name,
  feeder = M.feeder,
  inventory_defines = defines.inventory,
  item_prototypes = function()
    return prototypes.item
  end,
  entity_prototypes = function()
    return prototypes.entity
  end,
  quality_prototypes = function()
    return prototypes.quality
  end,
  compat = M.compat,
  COLOR = M.COLOR,
  SPECIALIZATION_BY_ID = M.SPECIALIZATION_BY_ID,
  SUB_SPECIALIZATION_BY_ID = M.SUB_SPECIALIZATION_BY_ID,
  get_augment_rank = M.get_augment_rank,
  get_base_rank = M.get_base_rank,
  REPAIR_MAX_HEALTH_FRACTION_PER_RANK = M.REPAIR_MAX_HEALTH_FRACTION_PER_RANK,
  AMMO_PRODUCTIVITY_PER_RANK = M.AMMO_PRODUCTIVITY_PER_RANK,
  SHIELD_ON_HIT_FRACTION_PER_RANK = M.SHIELD_ON_HIT_FRACTION_PER_RANK,
  RESISTANCE_MAX = M.RESISTANCE_MAX,
  RESISTANCE_PER_RANK = M.RESISTANCE_PER_RANK,
  BASE_TURRET_NAME = M.BASE_TURRET_NAME,
})
for name, stat in pairs(M.stats) do
  M[name] = stat
end

require("scripts.control.gui_panels")(M)
require("scripts.control.core_slot")(M)

local actions = require("scripts.control.actions")
M.actions = actions.new({
  GUI = M.GUI,
  COLOR = M.COLOR,
  LAYOUT = M.LAYOUT,
  GATES = M.GATES,
  BASE_UPGRADE_BY_ID = M.BASE_UPGRADE_BY_ID,
  ELEMENT_BY_ID = M.ELEMENT_BY_ID,
  SPECIALIZATION_BY_ID = M.SPECIALIZATION_BY_ID,
  SUB_SPECIALIZATION_BY_ID = M.SUB_SPECIALIZATION_BY_ID,
  AUGMENT_BY_ID = M.AUGMENT_BY_ID,
  ELEMENT_FREE_RANK = M.ELEMENT_FREE_RANK,
  FEEDER_CONSUME_LIMIT = M.FEEDER_CONSUME_LIMIT,
  feeder = M.feeder,
  combat = M.combat,
  get_open_turret_state = M.get_open_turret_state,
  refresh_open_turret = M.refresh_open_turret,
  create_blank_profile = M.create_blank_profile,
  insert_chip_item = M.insert_chip_item,
  get_remembered_turret = M.get_remembered_turret,
  spill_chip_item = M.spill_chip_item,
  sanitize_core_name = M.sanitize_core_name,
  update_name_render = M.update_name_render,
  get_gui_panel = M.get_gui_panel,
  find_gui_element = M.find_gui_element,
  core_panel_key = M.core_panel_key,
  find_matching_label_color_preset = M.find_matching_label_color_preset,
  set_style = M.set_style,
  evolution_anchor_name = M.evolution_anchor_name,
  get_available_skill_points = M.get_available_skill_points,
  get_available_augment_points = M.get_available_augment_points,
  ensure_evolution_state = M.ensure_evolution_state,
  normalize_shield_state = M.normalize_shield_state,
  update_shield_bar_render = M.update_shield_bar_render,
  destroy_shield_bar_render = M.destroy_shield_bar_render,
  sync_turret_progression = M.sync_turret_progression,
  is_gun_turret = M.is_gun_turret,
  has_level = M.has_level,
  get_unique_active_element_ids = M.get_unique_active_element_ids,
  get_element_remaining_requirement = M.get_element_remaining_requirement,
  add_element_material_progress = M.add_element_material_progress,
  xp_required = M.xp_required,
})
for name, handler in pairs(M.actions) do
  M[name] = handler
end

local gui_actions = require("scripts.control.gui.actions")
M.gui_actions = gui_actions.new({
  actions = M.actions,
  get_player = function(player_index)
    return game.get_player(player_index)
  end,
  handle_core_slot_click = M.handle_core_slot_click,
  install_core = M.install_core,
  extract_core = M.extract_core,
  install_core_from_inventory = M.install_core_from_inventory,
  install_core_from_platform = M.install_core_from_platform,
  send_core_to_platform = M.send_core_to_platform,
  set_bound_turret = M.set_bound_turret,
  set_core_picker_sort = M.set_core_picker_sort,
  set_core_picker_filter = M.set_core_picker_filter,
  get_remembered_turret = M.get_remembered_turret,
  refresh_open_turret = M.refresh_open_turret,
  update_name_render = M.update_name_render,
})
M.dispatch_gui_click_action = M.gui_actions.dispatch_click_action
M.dispatch_gui_checked_state_action = M.gui_actions.dispatch_checked_state_action
M.dispatch_gui_value_changed_action = M.gui_actions.dispatch_value_changed_action
M.dispatch_gui_text_changed_action = M.gui_actions.dispatch_text_changed_action
M.handle_gui_click_event = M.gui_actions.on_gui_click
M.handle_gui_checked_state_changed_event = M.gui_actions.on_gui_checked_state_changed
M.handle_gui_value_changed_event = M.gui_actions.on_gui_value_changed
M.handle_gui_text_changed_event = M.gui_actions.on_gui_text_changed

require("scripts.control.combat_effects")(M)
require("scripts.control.events")(M)
if script.active_mods["turret_xp_headless_tests"] then
  require("scripts.control.remote_test")(M)
end

local command_module = require("scripts.control.commands")
command_module.register({
  command_registry = commands,
  get_player = function(player_index)
    return game.get_player(player_index)
  end,
  is_gun_turret = M.is_gun_turret,
  build_turret_gui = M.build_turret_gui,
  ensure_player_settings = M.ensure_player_settings,
  get_remembered_turret = M.get_remembered_turret,
})

return M
