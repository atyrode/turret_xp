return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  function make_gui_frame(player)
    local ok, frame = pcall(function()
      return player.gui.relative.add({
        type = "frame",
        name = GUI.panel,
        direction = "vertical",
        caption = { "turret-xp.panel-title" },
        anchor = {
          gui = defines.relative_gui_type.turret_gui,
          position = defines.relative_gui_position.right,
        },
      })
    end)

    if ok and frame then
      return frame
    end

    return player.gui.left.add({
      type = "frame",
      name = GUI.panel,
      direction = "vertical",
      caption = { "turret-xp.panel-title" },
    })
  end

  build_turret_gui = function(player, entity, evolution_anchor)
    destroy_gui(player)

    if not is_gun_turret(entity) then
      forget_open_turret(player)
      return
    end

    remember_open_turret(player, entity)

    local frame = make_gui_frame(player)
    set_style(frame, "maximal_width", LAYOUT.panel_max_width)

    local columns = frame.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(columns, "horizontally_stretchable", true)
    set_style(columns, "vertical_align", "top")
    set_style(columns, "horizontal_spacing", LAYOUT.column_spacing)

    local body = columns.add({
      type = "frame",
      direction = "vertical",
    })
    set_element_style(body, "inside_shallow_frame_with_padding")
    set_style(body, "width", LAYOUT.left_column_width)
    set_style(body, "minimal_width", LAYOUT.left_column_width)
    set_style(body, "maximal_width", LAYOUT.left_column_width)

    add_core_panel(body)
    add_xp_panel(body)
    add_dev_controls_panel(body, player)

    add_stats_panel(body)

    add_evolution_panel(columns)

    update_turret_gui(player, entity, evolution_anchor)
  end

  function refresh_player_gui(player)
    local entity = get_remembered_turret(player)
    if not entity then
      destroy_gui(player)
      forget_open_turret(player)
      return
    end

    if player.opened ~= entity then
      destroy_gui(player)
      forget_open_turret(player)
      return
    end

    local state = get_turret_state(entity)
    if state then
      auto_feed_open_turret(state)
    end

    if not update_turret_gui(player, entity) then
      build_turret_gui(player, entity)
    end
  end

  handlers = {}

  function handlers.on_gui_opened(event)
    local player = game.get_player(event.player_index)
    if not player then
      return
    end

    if is_gun_turret(event.entity) then
      build_turret_gui(player, event.entity)
    else
      destroy_gui(player)
      forget_open_turret(player)
    end
  end

  function handlers.on_gui_closed(event)
    local player = game.get_player(event.player_index)
    if not player then
      return
    end

    local entity = get_remembered_turret(player)
    destroy_gui(player)
    forget_open_turret(player)
    if entity and entity.valid then
      local state = get_turret_state(entity)
      if state then
        combat.sync_turret_body_when_idle(entity, state)
      else
        combat.sync_turret_body_target_when_idle(entity)
      end
    end
  end

  function handlers.on_gui_click(event)
    local element = event.element
    if not element or not element.valid then
      return
    end

    local player = game.get_player(event.player_index)
    if not player then
      return
    end

    local tags = element.tags or {}
    local action = tags.turret_xp_action
    if action == "core-slot" then
      handle_core_slot_click(player, event)
    elseif action == "install-core" then
      install_core(player)
    elseif action == "extract-core" then
      extract_core(player)
    elseif action == "platform-install-core" then
      install_core_from_platform(player, tags.slot)
    elseif action == "platform-send-core" then
      send_core_to_platform(player)
    elseif action == "bind-turret" then
      set_bound_turret(player, true)
    elseif action == "unbind-turret" then
      set_bound_turret(player, false)
    elseif action == "cycle-label-color" then
      local entity, state = get_open_turret_state(player)
      if state then
        local presets = COLOR.label_presets
        local next_index = 1
        local current_preset = find_matching_label_color_preset(state)
        for index, preset in ipairs(presets) do
          if current_preset and preset.id == current_preset.id then
            next_index = (index % #presets) + 1
            break
          end
        end
        state.label_color = {
          presets[next_index].color[1],
          presets[next_index].color[2],
          presets[next_index].color[3],
        }
        state.label_color_preset = presets[next_index].id
        update_name_render(entity, state)
        update_label_color_preview(player, state)
      end
    elseif action == "dev-create-core" then
      dev_create_core(player)
    elseif action == "allocate-base" then
      allocate_base_upgrade(player, tags.upgrade, event.shift and 10 or 1)
    elseif action == "deallocate-base" then
      deallocate_base_upgrade(player, tags.upgrade, event.shift and 10 or 1)
    elseif action == "reset-base-upgrades" then
      reset_base_upgrades(player)
    elseif action == "choose-specialization" then
      choose_specialization(player, tags.specialization)
    elseif action == "reset-specialization" then
      reset_specialization(player)
    elseif action == "choose-sub-specialization" then
      choose_sub_specialization(player, tags.sub_specialization)
    elseif action == "reset-sub-specialization" then
      reset_sub_specialization(player)
    elseif action == "allocate-augment" then
      allocate_augment(player, tags.augment, event.shift and 10 or 1)
    elseif action == "deallocate-augment" then
      deallocate_augment(player, tags.augment, event.shift and 10 or 1)
    elseif action == "reset-augments" then
      reset_augments(player)
    elseif action == "reset-evolution" then
      reset_evolution(player)
    elseif action == "reset-element-slot" then
      reset_element_slot(player, tags.slot)
    elseif action == "start-element" then
      pick_element(player, tags.slot, tags.element)
    elseif action == "dev-complete-element-rank" then
      dev_complete_next_element_rank(player)
    elseif action == "dev-level" then
      add_dev_levels(player, tags.levels)
    elseif action == "dev-reset-core" then
      dev_reset_core(player)
    end
  end

  function handlers.on_gui_checked_state_changed(event)
    local element = event.element
    if not element or not element.valid then
      return
    end

    local tags = element.tags or {}
    local player = game.get_player(event.player_index)
    if not player then
      return
    end

    if tags.turret_xp_action == "toggle-core-label" then
      set_core_label_visibility(player, element.state == true)
    elseif tags.turret_xp_action == "toggle-label-level" then
      local entity, state = get_open_turret_state(player)
      if state then
        state.show_label_level = element.state == true
        update_name_render(entity, state)
        refresh_open_turret(player, entity)
      end
    end
  end

  function handlers.on_gui_value_changed(event)
    local element = event.element
    if not element or not element.valid then
      return
    end

    local tags = element.tags or {}
    if tags.turret_xp_action ~= "set-label-color" then
      return
    end

    local player = game.get_player(event.player_index)
    if not player then
      return
    end

    set_label_color_channel(player, tags.channel, element.slider_value or element.value)
  end

  function handlers.on_gui_text_changed(event)
    local element = event.element
    if not element or not element.valid then
      return
    end

    local player = game.get_player(event.player_index)
    if player then
      update_core_name_from_textfield(player, element)
    end
  end

  function handlers.on_runtime_mod_setting_changed(event)
    if not event.setting or string.sub(event.setting, 1, #MOD_PREFIX) ~= MOD_PREFIX then
      return
    end

    ensure_storage()

    for _, state in pairs(storage.turret_xp.chips) do
      ensure_evolution_state(state)
      sync_turret_progression(state)
    end

    for _, player in pairs(game.players) do
      if player and player.valid and player.connected then
        refresh_player_gui(player)
      end
    end
  end

  function handlers.on_research_finished(event)
    unlock_core_recipes_for_existing_tech()
    combat.sync_force_turret_attack_modifiers(event.research and event.research.force)
  end

  function handlers.on_force_created(event)
    combat.sync_force_turret_attack_modifiers(event.force)
  end

  function install_bound_turret_from_build_event(event)
    local entity = event.entity or event.created_entity
    if not entity or not entity.valid then
      return
    end

    local stack = get_bound_turret_stack_from_build_event(event)
    if not stack then
      return
    end

    local profile, turret_snapshot = read_bound_turret_stack(stack)
    if not profile then
      return
    end

    entity = replace_bound_turret_placeholder(entity, turret_snapshot)
    if not is_gun_turret(entity) then
      return
    end

    local installed = install_profile_on_turret(entity, profile)
    if not installed then
      return
    end

    local synced_entity = combat.sync_turret_body_when_idle(entity, installed)
    restore_turret_item_state(synced_entity or entity, turret_snapshot)
  end

  function handlers.on_built_entity(event)
    install_bound_turret_from_build_event(event)
  end

  function handlers.on_robot_built_entity(event)
    install_bound_turret_from_build_event(event)
  end

  function handlers.on_space_platform_built_entity(event)
    install_bound_turret_from_build_event(event)
  end

  function handlers.on_entity_damaged(event)
    local cause = event.cause
    local damage = event.final_damage_amount or 0
    if damage <= 0 or not event.entity or not event.entity.valid then
      return
    end

    local damage_force = event.force or (cause and cause.valid and cause.force)
    if damage_force and event.entity.force == damage_force then
      return
    end

    record_damage_contribution(event, cause, damage)

    if is_gun_turret(event.entity) then
      get_turret_host(event.entity, false)
      local damaged_state = get_turret_state(event.entity)
      if damaged_state then
        combat.apply_damage_resistance(event, event.entity, damaged_state)
        update_name_render(event.entity, damaged_state)
      end
    end

    if is_gun_turret(cause) then
      local state = get_turret_state(cause)
      if state then
        add_profile_damage(state, damage, cause, event.entity)
        combat.apply_evolution_damage_effects(event, cause, state, damage)
        sync_turret_progression(state)
        update_name_render(cause, state)
      end
    end
  end

  function handlers.on_entity_died(event)
    if is_gun_turret(event.entity) then
      local profile = get_turret_state(event.entity)
      destroy_name_render(profile)
      feeder.destroy(profile, event.entity.position, true)
      remove_turret_state(event.entity, true)
    elseif event.entity and event.entity.valid and event.entity.name == FEEDER_NAME then
      ensure_storage()
      local chip_id = event.entity.unit_number and storage.turret_xp.feeders[event.entity.unit_number] or nil
      if chip_id and storage.turret_xp.chips[chip_id] then
        storage.turret_xp.chips[chip_id].feeder = nil
      end
      if event.entity.unit_number then
        storage.turret_xp.feeders[event.entity.unit_number] = nil
      end
    end

    local cause = event.cause
    local damage_force = event.force or (cause and cause.valid and cause.force)
    if damage_force and event.entity and event.entity.valid and event.entity.force == damage_force then
      return
    end

    local credited_kill_turret = award_kill_credit(event.entity, cause)
    award_visible_kill(credited_kill_turret)
  end

  function remember_bound_turret_mining(entity, profile, turret_snapshot)
    if not is_gun_turret(entity) or not profile then
      return
    end

    local key = pending_bound_key(entity)
    if not key then
      return
    end

    ensure_storage()
    storage.turret_xp.pending_bound_mined[key] = {
      profile = copy_serializable(profile),
      turret = copy_serializable(turret_snapshot or snapshot_turret_item_state(entity)),
      entity = entity,
      surface_index = entity.surface.index,
      position = { x = entity.position.x, y = entity.position.y },
      key = key,
      tick = game.tick,
    }

    -- The bound item snapshot now owns loaded ammo; clear it before vanilla mining
    -- can also return the same ammo to the player or robot buffer.
    clear_turret_ammo_inventory(entity)
  end

  function take_bound_turret_mining(entity)
    local key = pending_bound_key(entity)
    if not key or not storage or not storage.turret_xp then
      return nil
    end

    local pending = storage.turret_xp.pending_bound_mined and storage.turret_xp.pending_bound_mined[key] or nil
    if storage.turret_xp.pending_bound_mined then
      storage.turret_xp.pending_bound_mined[key] = nil
    end

    return pending
  end

  function finish_bound_turret_mining(entity, buffer)
    if not is_gun_turret(entity) then
      return false
    end

    local pending = take_bound_turret_mining(entity)
    if not pending then
      return false
    end

    local raw_profile = get_turret_state(entity) or pending.profile
    if not raw_profile then
      return false
    end

    local profile = normalize_profile(copy_serializable(raw_profile))
    profile.bound_turret = true
    remove_bound_turret_mining_results(buffer, pending.turret)
    local delivered = insert_bound_turret_item(buffer, entity, profile, pending.turret)
    if not delivered then
      local surface = pending.surface_index and game.get_surface(pending.surface_index) or nil
      if surface and pending.position then
        delivered = spill_stack_definition_at(surface, pending.position, make_bound_turret_item_stack(profile, pending.turret))
      end
    end

    if not delivered then
      if pending.key then
        storage.turret_xp.pending_bound_mined[pending.key] = pending
      end
      return false
    end

    detach_profile_from_turret(entity)
    remove_turret_state(entity, false)
    return true
  end

  function handlers.on_turret_removed(event)
    local entity = event.entity
    if not is_gun_turret(entity) then
      return
    end

    local player = event.player_index and game.get_player(event.player_index) or nil
    local state = get_turret_state(entity)
    local turret_snapshot = snapshot_turret_item_state(entity)
    if state and state.bound_turret then
      state.bound_turret = true
      remember_bound_turret_mining(entity, state, turret_snapshot)
      return
    end

    local profile = detach_profile_from_turret(entity)
    if profile then
      local returned = player and insert_chip_item(player, profile)
      if not returned then
        spill_chip_item(entity, profile)
      end
    end

    remove_turret_state(entity, false)
  end

  function handlers.on_turret_mined_entity(event)
    finish_bound_turret_mining(event.entity, event.buffer)
  end

  function handlers.on_space_platform_mined_entity(event)
    local entity = event.entity
    if not is_gun_turret(entity) then
      return
    end

    local state = get_turret_state(entity)
    local turret_snapshot = snapshot_turret_item_state(entity)
    if state and state.bound_turret then
      local profile = normalize_profile(copy_serializable(state))
      profile.bound_turret = true
      remove_bound_turret_mining_results(event.buffer, turret_snapshot)
      if insert_bound_turret_item(event.buffer, entity, profile, turret_snapshot) then
        detach_profile_from_turret(entity)
        remove_turret_state(entity, false)
      end
      return
    end

    local profile = detach_profile_from_turret(entity)
    if profile then
      local inserted = 0
      local buffer = event.buffer
      if buffer and buffer.valid then
        local ok, result = pcall(function()
          return buffer.insert(make_chip_item_stack(profile))
        end)
        if ok and result then
          inserted = result
        end
      end
      if inserted <= 0 then
        spill_chip_item(entity, profile)
      end
    end

    remove_turret_state(entity, false)
  end

  function handlers.on_tick()
    combat.process_pending_visuals()
    combat.process_status_effects()
  end

  function handlers.on_refresh_tick()
    ensure_storage()
    cleanup_target_damage()
    cleanup_pending_bound_mining()
    apply_passive_evolution_effects()

    for player_index in pairs(storage.turret_xp.players) do
      local player = game.get_player(player_index)
      if player and player.valid and player.connected then
        refresh_player_gui(player)
      else
        storage.turret_xp.players[player_index] = nil
      end
    end
  end

  script.on_init(function()
    ensure_storage()
    unlock_core_recipes_for_existing_tech()
    combat.sync_all_turret_attack_modifiers()
  end)
  script.on_configuration_changed(function()
    ensure_storage()
    unlock_core_recipes_for_existing_tech()
    combat.sync_all_turret_attack_modifiers()
    combat.destroy_existing_visual_entities()
    storage.turret_xp.status_effects = {}
    storage.turret_xp.targets = {}
    for _, state in pairs(storage.turret_xp.chips) do
      ensure_evolution_state(state)
      sync_turret_progression(state)
      destroy_name_render(state)
      if is_gun_turret(state.entity) then
        update_name_render(state.entity, state)
      end
    end
    for _, player in pairs(game.players) do
      destroy_gui(player)
      forget_open_turret(player)
    end
  end)

  script.on_event(defines.events.on_gui_opened, handlers.on_gui_opened)
  script.on_event(defines.events.on_gui_closed, handlers.on_gui_closed)
  script.on_event(defines.events.on_gui_click, handlers.on_gui_click)
  script.on_event(defines.events.on_gui_checked_state_changed, handlers.on_gui_checked_state_changed)
  script.on_event(defines.events.on_gui_value_changed, handlers.on_gui_value_changed)
  script.on_event(defines.events.on_gui_text_changed, handlers.on_gui_text_changed)
  script.on_event(defines.events.on_runtime_mod_setting_changed, handlers.on_runtime_mod_setting_changed)
  script.on_event(defines.events.on_research_finished, handlers.on_research_finished)
  script.on_event(defines.events.on_force_created, handlers.on_force_created)
  script.on_event(defines.events.on_entity_damaged, handlers.on_entity_damaged)
  script.on_event(defines.events.on_entity_died, handlers.on_entity_died)
  script.on_event(defines.events.on_built_entity, handlers.on_built_entity)
  script.on_event(defines.events.on_robot_built_entity, handlers.on_robot_built_entity)
  script.on_event(defines.events.on_pre_player_mined_item, handlers.on_turret_removed)
  script.on_event(defines.events.on_robot_pre_mined, handlers.on_turret_removed)
  script.on_event(defines.events.on_player_mined_entity, handlers.on_turret_mined_entity)
  script.on_event(defines.events.on_robot_mined_entity, handlers.on_turret_mined_entity)
  script.on_event(defines.events.on_tick, handlers.on_tick)
  script.on_nth_tick(REFRESH_TICKS, handlers.on_refresh_tick)

  space_platform_built_event = defines.events.on_space_platform_built_entity
  if space_platform_built_event then
    script.on_event(space_platform_built_event, handlers.on_space_platform_built_entity)
  end

  space_platform_mined_event = defines.events.on_space_platform_mined_entity
  if space_platform_mined_event then
    script.on_event(space_platform_mined_event, handlers.on_space_platform_mined_entity)
  end
end
