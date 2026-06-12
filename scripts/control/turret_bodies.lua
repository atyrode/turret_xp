return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  function swap_turret_body(entity, target_name)
    if not is_gun_turret(entity) or entity.name == target_name then
      return entity
    end

    local function snapshot_inventory_contents(source, inventory_id)
      local inventory = compat.get_entity_inventory(source, inventory_id, "turret body snapshot inventory")
      local contents = {}
      if not inventory or not inventory.valid then
        return contents
      end

      for i = 1, #inventory do
        local stack = inventory[i]
        if stack and stack.valid_for_read then
          local entry = {
            name = stack.name,
            count = stack.count,
          }
          entry.quality = compat.quality_name(stack, nil, "turret body stack quality")
          contents[i] = entry
        end
      end

      return contents
    end

    local function restore_inventory_contents(destination, inventory_id, contents)
      local inventory = compat.get_entity_inventory(destination, inventory_id, "turret body restore inventory")
      if not inventory or not inventory.valid then
        return
      end

      for i = 1, #inventory do
        local stack = inventory[i]
        if stack then
          stack.clear()
        end
      end

      for i, entry in pairs(contents or {}) do
        local stack = inventory[i]
        if stack and entry and entry.name and entry.count and entry.count > 0 then
          pcall(function()
            stack.set_stack(entry)
          end)
        end
      end
    end

    local surface = entity.surface
    local position = entity.position
    local force = entity.force
    local direction = entity.direction
    local original_name = entity.name
    local quality = safe_read(entity, "quality")
    local health = safe_read(entity, "health")
    local max_health = safe_read(entity, "max_health")
    local health_ratio = max_health and max_health > 0 and health and math.max(0.01, health / max_health) or 1
    local host = get_turret_host(entity, false)
    local chip_id = host and host.chip_id or nil
    local old_key = turret_key(entity)
    local ammo_contents = snapshot_inventory_contents(entity, defines.inventory.turret_ammo)

    local create_parameters = {
      name = target_name,
      position = position,
      force = force,
      direction = direction,
      spill = false,
      raise_built = false,
      create_build_effect_smoke = false,
    }
    if quality and quality.name then
      create_parameters.quality = quality.name
    end

    entity.destroy({ raise_destroy = false })
    storage.turret_xp.turrets[old_key] = nil

    local ok, new_entity = pcall(function()
      return surface.create_entity(create_parameters)
    end)
    if not ok or not new_entity then
      create_parameters.quality = nil
      ok, new_entity = pcall(function()
        return surface.create_entity(create_parameters)
      end)
    end

    if not ok or not new_entity then
      create_parameters.name = original_name
      ok, new_entity = pcall(function()
        return surface.create_entity(create_parameters)
      end)
    end

    if not ok or not new_entity then
      return nil
    end

    local profile = chip_id and storage.turret_xp.chips[chip_id] or nil
    if profile then
      destroy_name_render(profile)
      profile.entity = new_entity
    end

    restore_inventory_contents(new_entity, defines.inventory.turret_ammo, ammo_contents)

    local new_max_health = safe_read(new_entity, "max_health")
    if new_max_health then
      new_entity.health = math.max(1, math.min(new_max_health, new_max_health * health_ratio))
    end

    local new_host = get_turret_host(new_entity, true)
    new_host.chip_id = chip_id

    if profile then
      update_name_render(new_entity, profile)
      feeder.ensure(new_entity, profile)
    end

    return new_entity
  end

  function replace_bound_turret_placeholder(entity, turret_snapshot)
    if not entity or not entity.valid or not is_bound_turret_placeholder(entity) then
      return entity
    end

    local surface = entity.surface
    local position = { x = entity.position.x, y = entity.position.y }
    local force = entity.force
    local direction = entity.direction
    local quality = quality_name_from_entity(entity, turret_snapshot and turret_snapshot.quality or "normal")
    local create_parameters = {
      name = BASE_TURRET_NAME,
      position = position,
      force = force,
      direction = direction,
      spill = false,
      raise_built = false,
      create_build_effect_smoke = false,
    }
    if quality and quality ~= "normal" then
      create_parameters.quality = quality
    end

    entity.destroy({ raise_destroy = false })

    local ok, created = pcall(function()
      return surface.create_entity(create_parameters)
    end)
    if ok and created and created.valid then
      return created
    end

    create_parameters.quality = nil
    ok, created = pcall(function()
      return surface.create_entity(create_parameters)
    end)
    if ok and created and created.valid then
      return created
    end

    return nil
  end

  function ensure_specialized_turret_body(entity, state)
    if not is_gun_turret(entity) then
      return entity
    end

    local evolution = state and ensure_evolution_state(state) or nil
    local specialization = evolution and evolution.specialization or nil
    local sub_specialization = evolution and evolution.sub_specialization or nil
    local target_name = get_specialized_turret_name(specialization, 0, 0, sub_specialization)
    return swap_turret_body(entity, target_name)
  end

  function combat.mark_turret_body_sync_pending(state)
    if state then
      state._body_sync_pending = true
    end
  end

  function combat.turret_gui_is_open(entity)
    if not is_gun_turret(entity) or not storage or not storage.turret_xp then
      return false
    end

    for player_index, player_state in pairs(storage.turret_xp.players or {}) do
      if player_state and player_state.entity == entity then
        local player = game.get_player(player_index)
        if player and player.valid and player.opened == entity then
          return true
        end
      end
    end

    return false
  end

  function combat.sync_turret_body_when_idle(entity, state)
    if not state or not is_gun_turret(entity) then
      return entity
    end

    local evolution = ensure_evolution_state(state)
    local target_name = get_specialized_turret_name(
      evolution.specialization,
      0,
      0,
      evolution.sub_specialization
    )
    if entity.name == target_name then
      state._body_sync_pending = nil
      return entity
    end

    if combat.turret_gui_is_open(entity) then
      combat.mark_turret_body_sync_pending(state)
      return entity
    end

    local new_entity = ensure_specialized_turret_body(entity, state)
    if new_entity and new_entity.name == target_name then
      state._body_sync_pending = nil
    else
      combat.mark_turret_body_sync_pending(state)
    end

    return new_entity or entity
  end

  function combat.mark_turret_body_target_pending(entity, target_name)
    if is_gun_turret(entity) and target_name then
      local host = get_turret_host(entity, true)
      host.body_sync_target = target_name
    end
  end

  function combat.sync_turret_body_target_when_idle(entity)
    if not is_gun_turret(entity) then
      return entity
    end

    local host = get_turret_host(entity, false)
    local target_name = host and host.body_sync_target or nil
    if not target_name then
      return entity
    end

    if entity.name == target_name then
      host.body_sync_target = nil
      return entity
    end

    if combat.turret_gui_is_open(entity) then
      return entity
    end

    local new_entity = swap_turret_body(entity, target_name)
    if new_entity then
      local new_host = get_turret_host(new_entity, true)
      new_host.body_sync_target = nil
      return new_entity
    end

    return entity
  end
end
