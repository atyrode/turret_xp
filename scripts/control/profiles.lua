local label_colors = require("scripts.control.label_colors")
local bound_turret_items = require("scripts.control.bound_turret_items")
local profile_schema = require("scripts.control.profile_schema")
local profile_tags = require("scripts.control.profile_tags")
local profile_inventory = require("scripts.control.profile_inventory")
local profile_labels = require("scripts.control.profile_labels")
local profile_service = require("scripts.control.profile_service")

return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  local function current_feeder()
    return feeder
  end

  local function feeder_is_ammo_item(name)
    local service = current_feeder()
    if not service then
      return true
    end
    return service.is_ammo_item(name)
  end

  local function feeder_get_entity_inventory(entity, inventory)
    local service = current_feeder()
    return service and service.get_entity_inventory(entity, inventory) or nil
  end

  local function feeder_ensure(entity, profile)
    local service = current_feeder()
    if service then
      service.ensure(entity, profile)
    end
  end

  local function feeder_destroy(profile, position, silent)
    local service = current_feeder()
    if service then
      service.destroy(profile, position, silent)
    end
  end

  local schema = profile_schema.new({
    label_colors = label_colors,
    is_ammo_item = feeder_is_ammo_item,
    ensure_xp_counters = ensure_xp_counters,
    ensure_evolution_state = ensure_evolution_state,
    normalize_shield_state = normalize_shield_state,
    sync_turret_progression = sync_turret_progression,
  })
  create_blank_profile = schema.create_blank_profile
  normalize_profile = schema.normalize_profile
  copy_serializable = schema.copy_serializable
  serialize_profile = schema.serialize_profile
  deserialize_profile = schema.deserialize_profile

  local tags = profile_tags.new({
    chip_name = CHIP_NAME,
    profile_tag = PROFILE_TAG,
    compat = compat,
    quality_name = function(object, fallback, context)
      return compat.quality_name(object, fallback, context)
    end,
    normalize_profile = normalize_profile,
    serialize_profile = serialize_profile,
    deserialize_profile = deserialize_profile,
    ensure_evolution_state = ensure_evolution_state,
    get_element_progress = get_element_progress,
    element_by_id = ELEMENT_BY_ID,
    specialization_by_id = SPECIALIZATION_BY_ID,
    sub_specialization_by_id = SUB_SPECIALIZATION_BY_ID,
    base_upgrades = BASE_UPGRADES,
    augments = AUGMENTS,
  })
  read_profile_from_chip_stack = tags.read_profile_from_chip_stack
  profile_format_rank = tags.profile_format_rank
  profile_join = tags.profile_join
  profile_rank_list = tags.profile_rank_list
  profile_element_rank_caption = tags.profile_element_rank_caption
  profile_elements_summary = tags.profile_elements_summary
  profile_specialization_summary = tags.profile_specialization_summary
  profile_build_lines = tags.profile_build_lines
  profile_description_with_build = tags.profile_description_with_build
  profile_description = tags.profile_description
  make_chip_item_stack = tags.make_chip_item_stack

  local inventory_service = profile_inventory.new({
    chip_name = CHIP_NAME,
    compat = compat,
    safe_read = safe_read,
    inventory_defines = defines.inventory,
    is_gun_turret = is_gun_turret,
    get_entity_inventory = feeder_get_entity_inventory,
    make_chip_item_stack = make_chip_item_stack,
    read_profile_from_chip_stack = read_profile_from_chip_stack,
    ensure_evolution_state = ensure_evolution_state,
    specialization_by_id = SPECIALIZATION_BY_ID,
  })
  quality_name_from_stack = inventory_service.quality_name_from_stack
  quality_name_from_entity = inventory_service.quality_name_from_entity
  snapshot_turret_item_state = inventory_service.snapshot_turret_item_state
  clear_turret_ammo_inventory = inventory_service.clear_turret_ammo_inventory
  ammo_snapshot_key = inventory_service.ammo_snapshot_key
  build_desired_turret_ammo_counts = inventory_service.build_desired_turret_ammo_counts
  build_desired_turret_ammo_stacks = inventory_service.build_desired_turret_ammo_stacks
  make_item_stack_definition = inventory_service.make_item_stack_definition
  find_turret_ammo_stack = inventory_service.find_turret_ammo_stack
  reconcile_preloaded_turret_ammo = inventory_service.reconcile_preloaded_turret_ammo
  restore_turret_item_state = inventory_service.restore_turret_item_state
  find_carried_chip_stack = inventory_service.find_carried_chip_stack
  find_best_carried_chip_stack = inventory_service.find_best_carried_chip_stack
  get_core_options_from_inventory = inventory_service.get_core_options_from_inventory
  get_player_core_options = inventory_service.get_player_core_options
  remove_one_chip_stack = inventory_service.remove_one_chip_stack
  insert_chip_item = inventory_service.insert_chip_item
  can_insert_chip_inventory = inventory_service.can_insert_chip_inventory
  get_platform_hub_inventory = inventory_service.get_platform_hub_inventory
  get_platform_core_options = inventory_service.get_platform_core_options
  spill_chip_item = inventory_service.spill_chip_item
  spill_stack_definition = inventory_service.spill_stack_definition
  spill_stack_definition_at = inventory_service.spill_stack_definition_at
  remove_item_from_inventory = inventory_service.remove_item_from_inventory

  local labels = profile_labels.new({
    label_colors = label_colors,
    is_gun_turret = is_gun_turret,
    normalize_profile = normalize_profile,
    normalize_shield_state = normalize_shield_state,
    game_tick = function()
      return game and game.tick or nil
    end,
    rendering_api = function()
      return rendering
    end,
  })
  destroy_name_render = labels.destroy_name_render
  destroy_shield_bar_render = labels.destroy_shield_bar_render
  shield_bar_visible_for_damage = labels.shield_bar_visible_for_damage
  update_shield_bar_render = labels.update_shield_bar_render
  find_matching_label_color_preset = labels.find_matching_label_color_preset
  get_profile_label_text = labels.get_profile_label_text
  update_name_render = labels.update_name_render

  local service = profile_service.new({
    ensure_storage = ensure_storage,
    storage_root = function()
      return storage and storage.turret_xp or nil
    end,
    is_gun_turret = is_gun_turret,
    turret_key = turret_key,
    normalize_profile = normalize_profile,
    destroy_name_render = destroy_name_render,
    destroy_shield_bar_render = destroy_shield_bar_render,
    ensure_feeder = feeder_ensure,
    destroy_feeder = feeder_destroy,
    update_name_render = update_name_render,
    update_shield_bar_render = update_shield_bar_render,
  })
  allocate_chip_id = service.allocate_chip_id
  get_turret_host = service.get_turret_host
  get_installed_profile = service.get_installed_profile
  get_turret_state = service.get_turret_state
  remove_turret_state = service.remove_turret_state
  chip_id_is_installed = service.chip_id_is_installed
  install_profile_on_turret = service.install_profile_on_turret
  detach_profile_from_turret = service.detach_profile_from_turret

  local bound_turret_item_service = nil
  local function get_bound_turret_item_service()
    if not bound_turret_item_service then
      bound_turret_item_service = bound_turret_items.new({
        profile_tag = PROFILE_TAG,
        bound_turret_tag = BOUND_TURRET_TAG,
        base_turret_name = BASE_TURRET_NAME,
        normalize_profile = normalize_profile,
        serialize_profile = serialize_profile,
        deserialize_profile = deserialize_profile,
        copy_serializable = copy_serializable,
        profile_description_with_build = profile_description_with_build,
        quality_name_from_stack = quality_name_from_stack,
        get_bound_turret_item_name = get_bound_turret_item_name,
        is_bound_turret_item_name = is_bound_turret_item_name,
        remove_item_from_inventory = remove_item_from_inventory,
        spill_stack_definition = spill_stack_definition,
        spill_stack_definition_at = spill_stack_definition_at,
        ensure_storage = ensure_storage,
        storage_root = function()
          return storage and storage.turret_xp or nil
        end,
        game_tick = function()
          return game.tick
        end,
        get_surface = function(surface_index)
          return game.get_surface(surface_index)
        end,
      })
    end

    return bound_turret_item_service
  end

  function bound_turret_description(profile)
    return get_bound_turret_item_service().description(profile)
  end

  function make_bound_turret_item_stack(profile, turret_snapshot)
    return get_bound_turret_item_service().make_stack(profile, turret_snapshot)
  end

  function read_bound_turret_stack(stack)
    return get_bound_turret_item_service().read_stack(stack)
  end

  function find_bound_turret_stack_in_inventory(inventory)
    return get_bound_turret_item_service().find_stack_in_inventory(inventory)
  end

  function get_bound_turret_stack_from_build_event(event)
    return get_bound_turret_item_service().stack_from_build_event(event)
  end

  function remove_bound_turret_mining_results(buffer, turret_snapshot)
    get_bound_turret_item_service().remove_mining_results(buffer, turret_snapshot)
  end

  function insert_bound_turret_item(inventory, entity, profile, turret_snapshot)
    return get_bound_turret_item_service().insert_item(inventory, entity, profile, turret_snapshot)
  end

  function cleanup_pending_bound_mining()
    get_bound_turret_item_service().cleanup_pending_mining()
  end

  function pending_bound_key(entity)
    return entity_tracking_key(entity)
  end
end
