local profile_service = {}

function profile_service.new(deps)
  local service = {}

  local function storage_root()
    deps.ensure_storage()
    return deps.storage_root()
  end

  function service.allocate_chip_id()
    local root = storage_root()
    local id = "core-" .. tostring(root.next_chip_id)
    root.next_chip_id = root.next_chip_id + 1
    return id
  end

  function service.get_turret_host(entity, create)
    if not deps.is_gun_turret(entity) then
      return nil
    end

    local root = storage_root()
    local key = deps.turret_key(entity)
    local host = root.turrets[key]

    if host and not host.chip_id and (host.evolution or host.skills or host.total_xp or host.damage or host.kills) then
      local profile = deps.normalize_profile(host)
      profile.chip_id = profile.chip_id or service.allocate_chip_id()
      profile.entity = entity
      root.chips[profile.chip_id] = profile
      host = {
        chip_id = profile.chip_id,
      }
      root.turrets[key] = host
    end

    if not host and create then
      host = {}
      root.turrets[key] = host
    end

    if host then
      host.entity = entity
    end

    return host
  end

  function service.get_installed_profile(entity)
    local host = service.get_turret_host(entity, false)
    if not host or not host.chip_id then
      return nil
    end

    local root = storage_root()
    local profile = root.chips[host.chip_id]
    if not profile then
      host.chip_id = nil
      return nil
    end

    profile.chip_id = host.chip_id
    profile.entity = entity
    return deps.normalize_profile(profile)
  end

  function service.get_turret_state(entity)
    return service.get_installed_profile(entity)
  end

  function service.remove_turret_state(entity, destroy_profile)
    if not deps.is_gun_turret(entity) then
      return
    end

    local root = storage_root()
    local key = deps.turret_key(entity)
    local host = root.turrets[key]
    if host and host.chip_id then
      local profile = root.chips[host.chip_id]
      if profile then
        deps.destroy_name_render(profile)
        deps.destroy_shield_bar_render(profile)
      end
      if destroy_profile then
        root.chips[host.chip_id] = nil
      end
    end
    root.turrets[key] = nil
  end

  function service.chip_id_is_installed(chip_id)
    if not chip_id then
      return false
    end

    local root = storage_root()
    for _, host in pairs(root.turrets) do
      if host and host.chip_id == chip_id then
        return true
      end
    end

    return false
  end

  function service.install_profile_on_turret(entity, profile)
    if not deps.is_gun_turret(entity) then
      return nil
    end

    local root = storage_root()
    local host = service.get_turret_host(entity, true)
    if host.chip_id then
      return nil
    end

    profile = deps.normalize_profile(profile)
    if not profile.chip_id or service.chip_id_is_installed(profile.chip_id) or root.chips[profile.chip_id] then
      profile.chip_id = service.allocate_chip_id()
    end

    profile.entity = entity
    root.chips[profile.chip_id] = profile
    host.chip_id = profile.chip_id
    deps.ensure_feeder(entity, profile)
    deps.update_name_render(entity, profile)
    deps.update_shield_bar_render(entity, profile, false)
    return profile
  end

  function service.detach_profile_from_turret(entity)
    local profile = service.get_installed_profile(entity)
    if not profile then
      return nil
    end

    local root = storage_root()
    local chip_id = profile.chip_id
    deps.destroy_name_render(profile)
    deps.destroy_shield_bar_render(profile)
    deps.destroy_feeder(profile, entity.position, true)
    profile.entity = nil
    if chip_id then
      root.chips[chip_id] = nil
    end

    local host = service.get_turret_host(entity, false)
    if host then
      host.chip_id = nil
    end

    return profile
  end

  return service
end

return profile_service
