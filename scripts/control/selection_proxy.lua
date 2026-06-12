return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  local function proxy_key(entity)
    return entity_tracking_key(entity)
  end

  local function forget_proxy(entity)
    if not entity or not storage or not storage.turret_xp then
      return
    end

    local key = proxy_key(entity)
    if key and storage.turret_xp.selection_proxies then
      storage.turret_xp.selection_proxies[key] = nil
    end
  end

  function destroy_selection_proxy(profile)
    if not profile then
      return
    end

    local proxy = profile.selection_proxy
    if proxy and proxy.valid then
      forget_proxy(proxy)
      pcall(function()
        proxy.destroy({ raise_destroy = false })
      end)
    end
    profile.selection_proxy = nil
  end

  function get_selection_proxy_turret(proxy)
    if not is_selection_proxy(proxy) then
      return nil, nil
    end

    ensure_storage()
    local chip_id = storage.turret_xp.selection_proxies[proxy_key(proxy)]
    local state = chip_id and storage.turret_xp.chips[chip_id] or nil
    local entity = state and state.entity or nil
    if not is_gun_turret(entity) then
      forget_proxy(proxy)
      return nil, nil
    end

    state = normalize_profile(state)
    return entity, state
  end

  function resolve_veteran_selection(entity)
    if is_gun_turret(entity) then
      return entity, get_turret_state(entity)
    end

    if is_selection_proxy(entity) then
      return get_selection_proxy_turret(entity)
    end

    return nil, nil
  end

  function ensure_selection_proxy(entity, profile)
    if not is_gun_turret(entity) or not profile or not profile.chip_id then
      return nil
    end

    if not prototypes or not prototypes.entity or not prototypes.entity[SELECTION_PROXY_NAME] then
      return nil
    end

    ensure_storage()
    local proxy = profile.selection_proxy
    if proxy and proxy.valid and proxy.surface == entity.surface then
      local ok = pcall(function()
        proxy.teleport(entity.position, entity.surface)
        proxy.force = entity.force
        proxy.destructible = false
        proxy.minable_flag = false
        proxy.operable = false
        proxy.rotatable = false
        proxy.display_panel_text = ""
        proxy.display_panel_always_show = false
        proxy.display_panel_show_in_chart = false
        proxy.display_panel_icon = nil
      end)
      if ok then
        storage.turret_xp.selection_proxies[proxy_key(proxy)] = profile.chip_id
        return proxy
      end
      destroy_selection_proxy(profile)
    end

    local create_parameters = {
      name = SELECTION_PROXY_NAME,
      position = entity.position,
      force = entity.force,
      raise_built = false,
      create_build_effect_smoke = false,
    }
    local ok, created = pcall(function()
      return entity.surface.create_entity({
        name = create_parameters.name,
        position = create_parameters.position,
        force = create_parameters.force,
        raise_built = create_parameters.raise_built,
        create_build_effect_smoke = create_parameters.create_build_effect_smoke,
      })
    end)

    if not ok or not created then
      create_parameters.force = nil
      ok, created = pcall(function()
        return entity.surface.create_entity(create_parameters)
      end)
    end

    if not ok or not created then
      return nil
    end

    pcall(function()
      created.destructible = false
      created.minable_flag = false
      created.operable = false
      created.rotatable = false
      created.display_panel_text = ""
      created.display_panel_always_show = false
      created.display_panel_show_in_chart = false
      created.display_panel_icon = nil
    end)

    profile.selection_proxy = created
    storage.turret_xp.selection_proxies[proxy_key(created)] = profile.chip_id
    return created
  end

  function cleanup_selection_proxies()
    if not storage or not storage.turret_xp then
      return
    end

    for key, chip_id in pairs(storage.turret_xp.selection_proxies or {}) do
      local state = chip_id and storage.turret_xp.chips[chip_id] or nil
      if not state or not is_gun_turret(state.entity) then
        storage.turret_xp.selection_proxies[key] = nil
      end
    end

    for _, state in pairs(storage.turret_xp.chips or {}) do
      if is_gun_turret(state.entity) then
        ensure_selection_proxy(state.entity, state)
      else
        destroy_selection_proxy(state)
      end
    end
  end
end
