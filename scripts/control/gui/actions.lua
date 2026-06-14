local gui_actions_module = {}

function gui_actions_module.new(deps)
  local actions = deps.actions
  local get_player = deps.get_player
  local handle_core_slot_click = deps.handle_core_slot_click
  local install_core = deps.install_core
  local extract_core = deps.extract_core
  local reinstall_last_extracted_core = deps.reinstall_last_extracted_core
  local install_core_from_inventory = deps.install_core_from_inventory
  local install_core_from_platform = deps.install_core_from_platform
  local send_core_to_platform = deps.send_core_to_platform
  local set_bound_turret = deps.set_bound_turret
  local set_core_picker_sort = deps.set_core_picker_sort
  local set_core_picker_filter = deps.set_core_picker_filter
  local get_remembered_turret = deps.get_remembered_turret
  local refresh_open_turret = deps.refresh_open_turret
  local update_name_render = deps.update_name_render

  local click_dispatch = {
    ["core-slot"] = function(player, event)
      handle_core_slot_click(player, event)
    end,
    ["install-core"] = function(player)
      install_core(player)
    end,
    ["extract-core"] = function(player)
      extract_core(player)
    end,
    ["reinstall-last-core"] = function(player)
      reinstall_last_extracted_core(player)
    end,
    ["inventory-install-core"] = function(player, event, tags)
      install_core_from_inventory(player, tags.slot)
    end,
    ["platform-install-core"] = function(player, event, tags)
      install_core_from_platform(player, tags.slot)
    end,
    ["platform-send-core"] = function(player)
      send_core_to_platform(player)
    end,
    ["set-core-sort"] = function(player, event, tags)
      set_core_picker_sort(player, tags.sort)
      refresh_open_turret(player, get_remembered_turret(player))
    end,
    ["bind-turret"] = function(player)
      set_bound_turret(player, true)
    end,
    ["unbind-turret"] = function(player)
      set_bound_turret(player, false)
    end,
    ["open-label-color-picker"] = function(player)
      actions.open_label_color_picker(player)
    end,
    ["close-label-color-picker"] = function(player)
      actions.close_label_color_picker(player)
    end,
    ["set-label-color-preset"] = function(player, event, tags)
      actions.set_label_color_preset(player, tags.preset)
    end,
    ["cycle-label-color"] = function(player)
      actions.cycle_label_color(player)
    end,
    ["dev-create-core"] = function(player)
      actions.dev_create_core(player)
    end,
    ["allocate-base"] = function(player, event, tags)
      actions.allocate_base_upgrade(player, tags.upgrade, event.shift and 10 or 1)
    end,
    ["deallocate-base"] = function(player, event, tags)
      actions.deallocate_base_upgrade(player, tags.upgrade, event.shift and 10 or 1)
    end,
    ["reset-base-upgrades"] = function(player)
      actions.reset_base_upgrades(player)
    end,
    ["choose-specialization"] = function(player, event, tags)
      actions.choose_specialization(player, tags.specialization)
    end,
    ["reset-specialization"] = function(player)
      actions.reset_specialization(player)
    end,
    ["choose-sub-specialization"] = function(player, event, tags)
      actions.choose_sub_specialization(player, tags.sub_specialization)
    end,
    ["reset-sub-specialization"] = function(player)
      actions.reset_sub_specialization(player)
    end,
    ["allocate-augment"] = function(player, event, tags)
      actions.allocate_augment(player, tags.augment, event.shift and 10 or 1)
    end,
    ["deallocate-augment"] = function(player, event, tags)
      actions.deallocate_augment(player, tags.augment, event.shift and 10 or 1)
    end,
    ["reset-augments"] = function(player)
      actions.reset_augments(player)
    end,
    ["reset-evolution"] = function(player)
      actions.reset_evolution(player)
    end,
    ["reset-element-slot"] = function(player, event, tags)
      actions.reset_element_slot(player, tags.slot)
    end,
    ["start-element"] = function(player, event, tags)
      actions.pick_element(player, tags.slot, tags.element)
    end,
    ["dev-complete-element-rank"] = function(player)
      actions.dev_complete_next_element_rank(player)
    end,
    ["dev-level"] = function(player, event, tags)
      actions.add_dev_levels(player, tags.levels)
    end,
    ["dev-reset-core"] = function(player)
      actions.dev_reset_core(player)
    end,
  }

  local function player_from_event(event)
    if not event or not event.player_index then
      return nil
    end

    return get_player(event.player_index)
  end

  local function event_element(event)
    local element = event and event.element or nil
    if not element or not element.valid then
      return nil
    end

    return element
  end

  local function element_tags(element)
    return element and element.tags or {}
  end

  local service = {}

  function service.dispatch_click_action(player, event, tags)
    tags = tags or {}
    local action = tags.turret_xp_action
    local handler = action and click_dispatch[action] or nil
    if not handler then
      return false
    end

    handler(player, event or {}, tags)
    return true
  end

  function service.dispatch_checked_state_action(player, event, tags)
    tags = tags or {}
    local element = event and event.element or nil
    local action = tags.turret_xp_action

    if action == "toggle-core-label" then
      actions.set_core_label_visibility(player, element and element.state == true)
      return true
    end

    if action == "toggle-label-level" then
      actions.opened_turret_action(player, function(entity, state)
        state.show_label_level = element and element.state == true
        update_name_render(entity, state)
      end)
      return true
    end

    if action == "set-core-filter" then
      set_core_picker_filter(player, tags.filter, element and element.state == true)
      refresh_open_turret(player, get_remembered_turret(player))
      return true
    end

    return false
  end

  function service.dispatch_value_changed_action(player, event, tags)
    tags = tags or {}
    if tags.turret_xp_action ~= "set-label-color" then
      return false
    end

    local element = event and event.element or {}
    actions.set_label_color_channel(player, tags.channel, element.slider_value or element.value)
    return true
  end

  function service.dispatch_text_changed_action(player, event)
    local element = event and event.element or nil
    if not element then
      return false
    end

    actions.update_core_name_from_textfield(player, element)
    return true
  end

  function service.on_gui_click(event)
    local element = event_element(event)
    if not element then
      return false
    end

    local player = player_from_event(event)
    if not player then
      return false
    end

    return service.dispatch_click_action(player, event, element_tags(element))
  end

  function service.on_gui_checked_state_changed(event)
    local element = event_element(event)
    if not element then
      return false
    end

    local player = player_from_event(event)
    if not player then
      return false
    end

    return service.dispatch_checked_state_action(player, event, element_tags(element))
  end

  function service.on_gui_value_changed(event)
    local element = event_element(event)
    if not element then
      return false
    end

    local player = player_from_event(event)
    if not player then
      return false
    end

    return service.dispatch_value_changed_action(player, event, element_tags(element))
  end

  function service.on_gui_text_changed(event)
    local element = event_element(event)
    if not element then
      return false
    end

    local player = player_from_event(event)
    if not player then
      return false
    end

    return service.dispatch_text_changed_action(player, event)
  end

  return service
end

return gui_actions_module
