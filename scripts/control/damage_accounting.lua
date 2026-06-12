local damage_accounting = {}

function damage_accounting.new(deps)
  local service = {}

  local function root()
    deps.ensure_storage()
    return deps.storage_root()
  end

  function service.target_prior_damage(event, damage)
    local max_health = deps.safe_read(event.entity, "max_health")
    local final_health = event.final_health

    if not max_health or not final_health then
      return 0
    end

    local pre_hit_health = final_health + damage
    return math.max(0, max_health - pre_hit_health)
  end

  function service.get_or_create_target_damage(event, damage, create)
    local storage_root = root()
    local key = deps.entity_tracking_key(event.entity)
    if not key then
      return nil
    end

    local entry = storage_root.targets[key]
    if not entry and create then
      entry = {
        total_damage = service.target_prior_damage(event, damage),
        target_context = deps.get_entity_xp_context(event.entity),
        turrets = {},
        tick = deps.game_tick()
      }
      storage_root.targets[key] = entry
    elseif entry and not entry.target_context then
      entry.target_context = deps.get_entity_xp_context(event.entity)
    end

    return entry, key
  end

  function service.record_damage_contribution(event, turret, damage)
    local profile = deps.is_gun_turret(turret) and deps.get_turret_state(turret) or nil
    local create = profile ~= nil
    local entry = service.get_or_create_target_damage(event, damage, create)

    if not entry then
      return
    end

    entry.total_damage = (entry.total_damage or 0) + damage
    entry.tick = deps.game_tick()

    if not create then
      return
    end

    local key = deps.turret_key(turret)
    local contributor = entry.turrets[key]
    if not contributor then
      contributor = {
        damage = 0,
        entity = turret,
        chip_id = profile.chip_id
      }
      entry.turrets[key] = contributor
    end

    contributor.damage = (contributor.damage or 0) + damage
    contributor.entity = turret
    contributor.chip_id = profile.chip_id
  end

  function service.resolve_kill_turret(entry, killing_turret)
    if deps.is_gun_turret(killing_turret) and deps.get_turret_state(killing_turret) then
      return killing_turret
    end

    local best_turret = nil
    local best_damage = 0
    for _, contributor in pairs((entry and entry.turrets) or {}) do
      local damage = contributor.damage or 0
      if damage > best_damage then
        local state = contributor.chip_id and root().chips[contributor.chip_id] or nil
        local turret = (state and state.entity) or contributor.entity
        if deps.is_gun_turret(turret) then
          best_turret = turret
          best_damage = damage
        end
      end
    end

    return best_turret
  end

  function service.award_kill_credit(target, killing_turret)
    local storage_root = root()
    local target_key = deps.entity_tracking_key(target)
    local entry = target_key and storage_root.targets[target_key] or nil
    local credited_kill_turret = service.resolve_kill_turret(entry, killing_turret)

    if entry and entry.total_damage and entry.total_damage > 0 then
      for _, contributor in pairs(entry.turrets or {}) do
        local contribution = math.max(0, contributor.damage or 0)
        local credit = contribution / entry.total_damage

        if credit > 0 then
          local turret = contributor.entity
          local state = nil

          if contributor.chip_id then
            state = storage_root.chips[contributor.chip_id]
          elseif deps.is_gun_turret(turret) then
            state = deps.get_turret_state(turret)
          end

          if state then
            deps.add_profile_kill_credit(state, credit, turret, entry.target_context or target)
            deps.sync_turret_progression(state)
            if deps.is_gun_turret(state.entity) then
              deps.update_name_render(state.entity, state)
            end
          end
        end
      end

      storage_root.targets[target_key] = nil
      return credited_kill_turret
    end

    if deps.is_gun_turret(killing_turret) then
      local state = deps.get_turret_state(killing_turret)
      if state then
        deps.add_profile_kill_credit(state, 1, killing_turret, target)
        deps.sync_turret_progression(state)
        if deps.is_gun_turret(state.entity) then
          deps.update_name_render(state.entity, state)
        end
      end
      return killing_turret
    end

    return credited_kill_turret
  end

  function service.award_visible_kill(turret)
    if not deps.is_gun_turret(turret) then
      return
    end

    local state = deps.get_turret_state(turret)
    if not state then
      return
    end

    local before = math.max(0, math.floor(tonumber(state.kills) or 0))
    local engine_kills = math.max(0, math.floor(tonumber(deps.safe_read(turret, "kills")) or 0))
    state.kills = math.max(before + 1, engine_kills)
    deps.sync_turret_progression(state)
    deps.update_name_render(turret, state)
  end

  function service.cleanup_target_damage()
    local storage_root = root()

    for key, entry in pairs(storage_root.targets) do
      if not entry.tick or deps.game_tick() - entry.tick > deps.target_damage_ttl then
        storage_root.targets[key] = nil
      end
    end
  end

  return service
end

return damage_accounting
