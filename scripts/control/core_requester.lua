local core_requester = {}

function core_requester.new(deps)
  local service = {}

  local function storage_root()
    deps.ensure_storage()
    return deps.storage_root()
  end

  local function requester_inventory(entity)
    if not entity or not entity.valid then
      return nil
    end

    return deps.compat.try("read core requester inventory", function()
      return entity.get_inventory(deps.inventory_defines.chest)
    end)
  end

  local function requester_from_host(host)
    local requester = host and host.core_requester
    if requester and requester.valid and requester.name == deps.requester_name then
      return requester
    end
    return nil
  end

  local function configure_requester(entity)
    deps.compat.try("configure core requester logistics", function()
      local point = entity.get_requester_point and entity.get_requester_point()
      if not point then
        return
      end

      point.enabled = true
      point.trash_not_requested = true
      local section = point.sections_count > 0 and point.get_section(1) or point.add_section("Turret XP")
      if not section then
        return
      end

      section.active = true
      section.set_slot(1, {
        value = {
          type = "item",
          name = deps.chip_name,
          quality = "normal",
        },
        min = 1,
        max = 1,
      })
      entity.request_from_buffers = true
    end)
  end

  local function register_requester(host, requester, turret_key)
    host.core_requester = requester
    host.core_requester_unit_number = requester and requester.valid and requester.unit_number or nil
    if requester and requester.valid and requester.unit_number then
      storage_root().core_requesters[requester.unit_number] = turret_key
    end
  end

  local function unregister_requester(host)
    local unit_number = host and host.core_requester_unit_number
    if unit_number then
      storage_root().core_requesters[unit_number] = nil
    end
    if host then
      host.core_requester = nil
      host.core_requester_unit_number = nil
    end
  end

  local function spill_stack(surface, position, force, stack)
    if not surface or not stack or not stack.valid_for_read then
      return false
    end

    if stack.name == deps.chip_name then
      local profile = deps.read_profile_from_chip_stack(stack)
      if profile then
        deps.spill_chip_profile(surface, position, profile)
        return true
      end
    end

    return deps.compat.try("spill core requester stack", function()
      surface.spill_item_stack({
        position = position,
        stack = {
          name = stack.name,
          count = stack.count,
          quality = deps.quality_name(stack, "normal", "core requester spill quality"),
        },
        force = force,
        enable_looted = true,
      })
      return true
    end, false)
  end

  local function spill_requester_contents(requester, turret, spill)
    if spill ~= true then
      return
    end

    local inventory = requester_inventory(requester)
    if not inventory or not inventory.valid then
      return
    end

    local surface = (turret and turret.valid and turret.surface) or requester.surface
    local position = (turret and turret.valid and turret.position) or requester.position
    local force = (turret and turret.valid and turret.force) or requester.force
    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read and spill_stack(surface, position, force, stack) then
        stack.clear()
      end
    end
  end

  function service.status(entity)
    local host = deps.get_turret_host(entity, false)
    local requester = requester_from_host(host)
    local inventory = requester_inventory(requester)
    return {
      enabled = host and host.request_core == true or false,
      requester_valid = requester ~= nil,
      delivered = inventory and not inventory.is_empty() or false,
      network = requester and requester.valid and requester.logistic_network ~= nil or false,
    }
  end

  function service.destroy_for_turret(entity, spill)
    local host = deps.get_turret_host(entity, false)
    if not host then
      return
    end

    local requester = requester_from_host(host)
    unregister_requester(host)
    if requester and requester.valid then
      spill_requester_contents(requester, entity, spill)
      requester.destroy({ raise_destroy = false })
    end
  end

  function service.ensure(entity)
    if not deps.is_gun_turret(entity) then
      return nil
    end

    local host = deps.get_turret_host(entity, true)
    if host.chip_id or host.request_core ~= true then
      service.destroy_for_turret(entity, true)
      return nil
    end

    local requester = requester_from_host(host)
    if requester then
      configure_requester(requester)
      return requester
    end

    requester = deps.compat.try("create core requester", function()
      return entity.surface.create_entity({
        name = deps.requester_name,
        position = entity.position,
        force = entity.force,
        create_build_effect_smoke = false,
        raise_built = false,
      })
    end)

    if not requester then
      host.request_core_status = "unavailable"
      return nil
    end

    deps.compat.try("hide core requester", function()
      requester.destructible = false
      requester.operable = false
    end)
    register_requester(host, requester, deps.turret_key(entity))
    configure_requester(requester)
    host.request_core_status = "waiting"
    return requester
  end

  function service.set_request(entity, enabled)
    if not deps.is_gun_turret(entity) then
      return false
    end

    local host = deps.get_turret_host(entity, true)
    if host.chip_id then
      host.request_core = false
      service.destroy_for_turret(entity, true)
      return false
    end

    host.request_core = enabled == true
    if host.request_core then
      service.ensure(entity)
    else
      service.destroy_for_turret(entity, true)
    end
    return host.request_core == true
  end

  local function delivered_core_stack(inventory)
    if not inventory or not inventory.valid then
      return nil
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read and stack.name == deps.chip_name then
        return stack
      end
    end
    return nil
  end

  function service.process_requests(limit)
    local root = storage_root()
    limit = math.max(1, math.floor(tonumber(limit) or 64))
    local processed = 0
    local installed = 0

    for requester_unit_number, turret_key in pairs(root.core_requesters) do
      if processed >= limit then
        break
      end
      processed = processed + 1

      local host = root.turrets[turret_key]
      local turret = host and host.entity or nil
      local requester = requester_from_host(host)
      if not host or not deps.is_gun_turret(turret) or not requester then
        root.core_requesters[requester_unit_number] = nil
        if requester and requester.valid then
          spill_requester_contents(requester, turret, true)
          requester.destroy({ raise_destroy = false })
        end
      elseif host.chip_id or host.request_core ~= true then
        service.destroy_for_turret(turret, true)
      else
        configure_requester(requester)
        local inventory = requester_inventory(requester)
        local stack = delivered_core_stack(inventory)
        if stack then
          local profile = deps.read_profile_from_chip_stack(stack) or deps.create_blank_profile()
          stack.clear()
          local installed_profile = deps.install_profile_on_turret(turret, profile)
          if installed_profile then
            installed = installed + 1
            deps.mark_turret_body_sync_pending(installed_profile)
          else
            deps.spill_chip_profile(turret.surface, turret.position, profile)
          end
        end
      end
    end

    root.core_requester_refresh = {
      tick = deps.game_tick(),
      active = table_size(root.core_requesters),
      processed = processed,
      installed = installed,
    }
    return root.core_requester_refresh
  end

  return service
end

return core_requester
