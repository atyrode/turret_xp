return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  function get_open_turret_state(player)
    local entity = get_remembered_turret(player)
    if not entity or player.opened ~= entity then
      return nil, nil
    end

    return entity, get_turret_state(entity)
  end

  function refresh_open_turret(player, entity, evolution_anchor)
    if entity and entity.valid then
      if not update_turret_gui(player, entity, evolution_anchor) then
        build_turret_gui(player, entity, evolution_anchor)
      end
    end
  end

  function refresh_open_turret_stats(player, entity)
    if entity and entity.valid then
      update_turret_gui_stats(player, entity)
    end
  end

  function sanitize_core_name(name)
    name = tostring(name or "")
    name = name:gsub("[%c\r\n\t]", " ")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if #name > 48 then
      name = string.sub(name, 1, 48)
    end
    return name
  end

  function show_core_slot_warning(player, message)
    if not player then
      return
    end

    local shown = compat.try("core slot local flying text", function()
      if type(player.create_local_flying_text) ~= "function" then
        return false
      end
      player.create_local_flying_text({
        create_at_cursor = true,
        text = message,
        color = { r = 1, g = 1, b = 1 },
        time_to_live = 90,
      })
      return true
    end, false)

    if not shown and type(player.print) == "function" then
      player.print(message)
    end
  end

  local function clear_last_extracted_core_if_reinstalled(player, entity, installed)
    local record = get_last_extracted_core(player, entity)
    if record and installed and installed.chip_id == record.chip_id then
      clear_last_extracted_core(player)
    end
  end

  function install_core(player)
    local entity = get_remembered_turret(player)
    if not entity or player.opened ~= entity then
      return
    end

    if get_turret_state(entity) then
      show_core_slot_warning(player, { "turret-xp.core-already-installed" })
      refresh_open_turret(player, entity)
      return
    end

    local stack = find_best_carried_chip_stack(player)
    if not stack then
      show_core_slot_warning(player, { "turret-xp.no-core-to-install" })
      refresh_open_turret(player, entity)
      return
    end

    local profile = read_profile_from_chip_stack(stack) or create_blank_profile()
    if not remove_one_chip_stack(stack) then
      refresh_open_turret(player, entity)
      return
    end

    local installed = install_profile_on_turret(entity, profile)
    if not installed then
      insert_chip_item(player, profile)
    else
      clear_last_extracted_core_if_reinstalled(player, entity, installed)
      combat.mark_turret_body_sync_pending(installed)
    end

    refresh_open_turret(player, entity)
  end

  function install_core_from_inventory(player, slot)
    slot = math.floor(tonumber(slot) or 0)
    if slot <= 0 then
      return
    end

    local entity, existing = get_open_turret_state(player)
    if not entity then
      return
    end
    if existing then
      show_core_slot_warning(player, { "turret-xp.core-already-installed" })
      refresh_open_turret(player, entity)
      return
    end

    local inventory = type(player.get_main_inventory) == "function" and player.get_main_inventory() or nil
    local stack = inventory and inventory.valid and inventory[slot] or nil
    if not stack or not stack.valid_for_read or stack.name ~= CHIP_NAME then
      show_core_slot_warning(player, { "turret-xp.inventory-core-missing" })
      refresh_open_turret(player, entity)
      return
    end

    local profile = read_profile_from_chip_stack(stack) or create_blank_profile()
    if not remove_one_chip_stack(stack) then
      refresh_open_turret(player, entity)
      return
    end

    local installed = install_profile_on_turret(entity, profile)
    if not installed then
      compat.try("return inventory core after failed install", function()
        inventory.insert(make_chip_item_stack(profile))
      end)
      refresh_open_turret(player, entity)
      return
    end

    combat.mark_turret_body_sync_pending(installed)
    clear_last_extracted_core_if_reinstalled(player, entity, installed)
    refresh_open_turret(player, entity)
  end

  function reinstall_last_extracted_core(player)
    local entity, existing = get_open_turret_state(player)
    if not entity then
      return
    end

    if existing then
      show_core_slot_warning(player, { "turret-xp.core-already-installed" })
      refresh_open_turret(player, entity)
      return
    end

    local record = get_last_extracted_core(player, entity)
    local inventory = type(player.get_main_inventory) == "function" and player.get_main_inventory() or nil
    local option = record and find_core_option_by_chip_id(inventory, record.chip_id) or nil
    if not option then
      clear_last_extracted_core(player)
      show_core_slot_warning(player, { "turret-xp.inventory-core-missing" })
      refresh_open_turret(player, entity)
      return
    end

    install_core_from_inventory(player, option.index)
  end

  function extract_core(player)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    local stack = make_chip_item_stack(state)
    local can_insert = compat.try("player can_insert extracted core", function()
      return player.can_insert(stack)
    end, false)

    if not can_insert then
      show_core_slot_warning(player, { "turret-xp.no-room-for-core" })
      refresh_open_turret(player, entity)
      return
    end

    local profile = detach_profile_from_turret(entity)
    if not profile then
      refresh_open_turret(player, entity)
      return
    end

    if not insert_chip_item(player, profile) then
      install_profile_on_turret(entity, profile)
      show_core_slot_warning(player, { "turret-xp.no-room-for-core" })
      refresh_open_turret(player, entity)
      return
    end

    remember_last_extracted_core(player, entity, profile)
    combat.mark_turret_body_target_pending(entity, BASE_TURRET_NAME)
    refresh_open_turret(player, entity)
  end

  function install_core_from_platform(player, slot)
    slot = math.floor(tonumber(slot) or 0)
    if slot <= 0 then
      return
    end

    local entity, existing = get_open_turret_state(player)
    if not entity or existing then
      if existing then
        show_core_slot_warning(player, { "turret-xp.core-already-installed" })
      end
      refresh_open_turret(player, entity)
      return
    end

    local inventory = get_platform_hub_inventory(entity)
    local stack = inventory and inventory[slot] or nil
    if not stack or not stack.valid_for_read or stack.name ~= CHIP_NAME then
      refresh_open_turret(player, entity)
      return
    end

    local profile = read_profile_from_chip_stack(stack) or create_blank_profile()
    if not remove_one_chip_stack(stack) then
      refresh_open_turret(player, entity)
      return
    end

    local installed = install_profile_on_turret(entity, profile)
    if not installed then
      compat.try("return platform core after failed install", function()
        inventory.insert(make_chip_item_stack(profile))
      end)
      refresh_open_turret(player, entity)
      return
    end

    combat.mark_turret_body_sync_pending(installed)
    clear_last_extracted_core_if_reinstalled(player, entity, installed)

    refresh_open_turret(player, entity)
  end

  function send_core_to_platform(player)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    local inventory = get_platform_hub_inventory(entity)
    if not inventory or not can_insert_chip_inventory(inventory, state) then
      show_core_slot_warning(player, { "turret-xp.platform-core-no-room" })
      refresh_open_turret(player, entity)
      return
    end

    local profile = detach_profile_from_turret(entity)
    if not profile then
      refresh_open_turret(player, entity)
      return
    end

    local inserted = compat.try("send core to platform hub", function()
      return inventory.insert(make_chip_item_stack(profile))
    end, 0)
    if not inserted or inserted <= 0 then
      install_profile_on_turret(entity, profile)
      show_core_slot_warning(player, { "turret-xp.platform-core-no-room" })
      refresh_open_turret(player, entity)
      return
    end

    combat.mark_turret_body_target_pending(entity, BASE_TURRET_NAME)
    refresh_open_turret(player, entity)
  end

  function set_bound_turret(player, bound)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    state.bound_turret = bound == true
    refresh_open_turret(player, entity)
  end

  function handle_core_slot_click(player, event)
    local entity, state = get_open_turret_state(player)
    if not entity then
      return
    end

    local cursor = player.cursor_stack
    local cursor_has_stack = cursor and cursor.valid_for_read

    if state then
      if cursor_has_stack then
        if cursor.name ~= CHIP_NAME then
          show_core_slot_warning(player, { "turret-xp.core-slot-reject" })
          refresh_open_turret(player, entity)
          return
        end

        local incoming_profile = read_profile_from_chip_stack(cursor)
        local outgoing_stack = make_chip_item_stack(state)
        local outgoing_profile = detach_profile_from_turret(entity)
        if not outgoing_profile then
          refresh_open_turret(player, entity)
          return
        end

        local installed = install_profile_on_turret(entity, incoming_profile)
        if not installed then
          install_profile_on_turret(entity, outgoing_profile)
          refresh_open_turret(player, entity)
          return
        end

        cursor.set_stack(outgoing_stack)
        combat.mark_turret_body_sync_pending(installed)
        clear_last_extracted_core_if_reinstalled(player, entity, installed)

        refresh_open_turret(player, entity)
        return
      end

      if event.shift or event.control then
        extract_core(player)
        return
      end

      local stack = make_chip_item_stack(state)
      local ok = pcall(function()
        cursor.set_stack(stack)
      end)
      if not ok or not cursor.valid_for_read then
        show_core_slot_warning(player, { "turret-xp.no-room-for-core" })
        refresh_open_turret(player, entity)
        return
      end

      local profile = detach_profile_from_turret(entity)
      if not profile then
        cursor.clear()
        refresh_open_turret(player, entity)
        return
      end

      combat.mark_turret_body_target_pending(entity, BASE_TURRET_NAME)
      refresh_open_turret(player, entity)
      return
    end

    if cursor_has_stack then
      if cursor.name ~= CHIP_NAME then
        show_core_slot_warning(player, { "turret-xp.core-slot-reject" })
        refresh_open_turret(player, entity)
        return
      end

      local profile = read_profile_from_chip_stack(cursor) or create_blank_profile()
      if not remove_one_chip_stack(cursor) then
        refresh_open_turret(player, entity)
        return
      end

      local installed = install_profile_on_turret(entity, profile)
      if not installed then
        cursor.set_stack(make_chip_item_stack(profile))
        refresh_open_turret(player, entity)
        return
      end

      combat.mark_turret_body_sync_pending(installed)
      clear_last_extracted_core_if_reinstalled(player, entity, installed)

      refresh_open_turret(player, entity)
      return
    end

    if event.shift or event.control then
      install_core(player)
    else
      show_core_slot_warning(player, { "turret-xp.no-core-to-install" })
      refresh_open_turret(player, entity)
    end
  end
end
