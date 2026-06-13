local combat_application = {}

function combat_application.new(deps)
  local service = {}
  local feeder = deps.feeder
  local compat = deps.compat
  local safe_read = deps.safe_read

  function service.remember_loaded_ammo(entity, state)
    if not deps.is_gun_turret(entity) or not state then
      return nil
    end

    local snapshot = deps.get_loaded_ammo_snapshot(entity)
    if snapshot and snapshot.name and (snapshot.count or 0) > 0 and feeder.is_ammo_item(snapshot.name) then
      state.last_ammo = {
        name = snapshot.name,
        quality = snapshot.quality or "normal",
      }
      state._ammo_productivity_last = {
        name = snapshot.name,
        quality = snapshot.quality or "normal",
        count = math.max(0, math.floor(tonumber(snapshot.count) or 0)),
        ammo = math.max(0, math.floor(tonumber(snapshot.ammo) or 0)),
        magazine_size = math.max(0, math.floor(tonumber(snapshot.magazine_size) or 0)),
      }
    end

    return state.last_ammo
  end

  local function current_ammo_snapshot(entity)
    local snapshot = deps.get_loaded_ammo_snapshot(entity)
    if snapshot and snapshot.name and (snapshot.count or 0) > 0 and feeder.is_ammo_item(snapshot.name) then
      return {
        name = snapshot.name,
        quality = snapshot.quality or "normal",
        count = math.max(0, math.floor(tonumber(snapshot.count) or 0)),
        ammo = math.max(0, math.floor(tonumber(snapshot.ammo) or 0)),
        magazine_size = math.max(0, math.floor(tonumber(snapshot.magazine_size) or 0)),
      }
    end

    return {
      count = 0,
      ammo = 0,
    }
  end

  local function remember_ammo_snapshot(state, snapshot)
    if not state then
      return
    end

    if snapshot and snapshot.name then
      state.last_ammo = {
        name = snapshot.name,
        quality = snapshot.quality or "normal",
      }
      state._ammo_productivity_last = {
        name = snapshot.name,
        quality = snapshot.quality or "normal",
        count = math.max(0, math.floor(tonumber(snapshot.count) or 0)),
        ammo = math.max(0, math.floor(tonumber(snapshot.ammo) or 0)),
        magazine_size = math.max(0, math.floor(tonumber(snapshot.magazine_size) or 0)),
      }
    else
      state._ammo_productivity_last = nil
    end
  end

  function service.insert_recovered_ammo(entity, ammo, amount)
    if not deps.is_gun_turret(entity) or not ammo or not ammo.name or amount <= 0 then
      return 0
    end

    local inventory = feeder.get_entity_inventory(entity, deps.inventory_defines.turret_ammo)
    if not inventory or not inventory.valid then
      return 0
    end

    local stack = {
      name = ammo.name,
      count = amount,
    }
    if ammo.quality and ammo.quality ~= "" then
      stack.quality = ammo.quality
    end

    local ok, inserted = pcall(function()
      return inventory.insert(stack)
    end)
    if ok and inserted then
      return inserted
    end

    stack.quality = nil
    ok, inserted = pcall(function()
      return inventory.insert(stack)
    end)
    if ok and inserted then
      return inserted
    end

    return 0
  end

  local function set_stack_ammo(stack, amount)
    if not stack or not stack.valid_for_read then
      return 0
    end

    local before = math.max(0, math.floor(tonumber(safe_read(stack, "ammo")) or 0))
    local target = math.max(0, math.floor(tonumber(amount) or 0))
    local ok = pcall(function()
      stack.ammo = target
    end)
    if not ok then
      local delta = target - before
      if delta > 0 then
        pcall(function()
          stack.add_ammo(delta)
        end)
      elseif delta < 0 then
        pcall(function()
          stack.drain_ammo(-delta)
        end)
      end
    end

    local after = math.max(0, math.floor(tonumber(safe_read(stack, "ammo")) or before))
    return math.max(0, after - before)
  end

  function service.add_productivity_ammo(entity, ammo, amount)
    local bonus_ammo = math.max(0, math.floor(tonumber(amount) or 0))
    if not deps.is_gun_turret(entity) or not ammo or not ammo.name or bonus_ammo <= 0 then
      return 0
    end

    local snapshot = deps.get_loaded_ammo_snapshot(entity, ammo)
    local stack = snapshot and snapshot.stack or nil

    if not stack or not stack.valid_for_read then
      local inventory = feeder.get_entity_inventory(entity, deps.inventory_defines.turret_ammo)
      if not inventory or not inventory.valid then
        return 0
      end

      local stack_definition = {
        name = ammo.name,
        count = 1,
      }
      if ammo.quality and ammo.quality ~= "" then
        stack_definition.quality = ammo.quality
      end

      local inserted = compat.try("insert productivity magazine shell", function()
        return inventory.insert(stack_definition)
      end, 0) or 0
      if inserted <= 0 and stack_definition.quality then
        stack_definition.quality = nil
        inserted = compat.try("insert productivity magazine shell fallback", function()
          return inventory.insert(stack_definition)
        end, 0) or 0
      end
      if inserted <= 0 then
        return 0
      end

      snapshot = deps.get_loaded_ammo_snapshot(entity, ammo)
      stack = snapshot and snapshot.stack or nil
      if not stack or not stack.valid_for_read then
        return 0
      end

      local magazine_size = tonumber(safe_read(safe_read(stack, "prototype"), "magazine_size")) or 0
      if magazine_size > 0 then
        pcall(function()
          stack.drain_ammo(magazine_size)
        end)
      end
    end

    local before = math.max(0, math.floor(tonumber(safe_read(stack, "ammo")) or 0))
    local magazine_size = tonumber(safe_read(safe_read(stack, "prototype"), "magazine_size"))
      or tonumber(snapshot and snapshot.magazine_size)
      or 0
    local target = before + bonus_ammo
    if magazine_size > 0 then
      target = math.min(magazine_size, target)
    end

    return set_stack_ammo(stack, target)
  end

  function service.apply_ammo_productivity(entity, state)
    local rank = deps.get_base_rank(state, "ammo_regen")
    local current = current_ammo_snapshot(entity)
    if rank <= 0 then
      state.ammo_productivity_progress = 0
      remember_ammo_snapshot(state, current)
      return
    end

    local tick = deps.game_tick()
    if state._ammo_productivity_last_tick == tick then
      remember_ammo_snapshot(state, current)
      return
    end

    state._ammo_productivity_last_tick = tick

    local previous = state._ammo_productivity_last
    local spent = 0
    local spent_ammo = nil
    if previous and previous.name and feeder.is_ammo_item(previous.name) then
      spent_ammo = {
        name = previous.name,
        quality = previous.quality or "normal",
      }
      if current.name == previous.name and (current.quality or "normal") == (previous.quality or "normal") then
        if (current.count or 0) < (previous.count or 0) then
          spent = math.max(1, (previous.count or 0) - (current.count or 0))
        elseif previous.ammo and current.ammo then
          spent = math.max(0, (previous.ammo or 0) - (current.ammo or 0))
        end
      elseif not current.name and (previous.count or 0) > 0 then
        spent = 1
      elseif current.name then
        spent = 1
        spent_ammo = {
          name = current.name,
          quality = current.quality or "normal",
        }
      end
    elseif current.name then
      spent = 1
      spent_ammo = {
        name = current.name,
        quality = current.quality or "normal",
      }
    end

    if spent <= 0 or not spent_ammo then
      state.ammo_productivity_progress = math.max(0, tonumber(state.ammo_productivity_progress or state.ammo_regen_progress) or 0)
      remember_ammo_snapshot(state, current)
      return
    end

    local productivity = deps.get_effective_ammo_productivity_fraction(state)
    local progress = math.max(0, tonumber(state.ammo_productivity_progress or state.ammo_regen_progress) or 0) + (spent * productivity)
    local bonus_ammo = math.floor(progress + 0.000001)
    if bonus_ammo > 0 then
      local added = service.add_productivity_ammo(entity, spent_ammo, bonus_ammo)
      if added > 0 then
        progress = math.max(0, progress - added)
      end
    end

    state.ammo_productivity_progress = math.min(progress, 1)
    state.ammo_regen_progress = nil
    remember_ammo_snapshot(state, current_ammo_snapshot(entity))
  end

  function service.apply_ammo_regeneration(entity, state)
    return service.apply_ammo_productivity(entity, state)
  end

  function service.apply_shield_on_hit(entity, state, amount)
    if not deps.is_gun_turret(entity) or not state or amount <= 0 then
      return 0
    end

    local fraction = deps.get_shield_on_hit_fraction(state)
    if fraction <= 0 then
      return 0
    end

    local shield, capacity = deps.normalize_shield_state(state, false)
    if capacity <= 0 or shield >= capacity then
      return 0
    end

    local gained = math.min(capacity - shield, amount * fraction)
    if gained <= 0 then
      return 0
    end

    state.shield = shield + gained
    deps.update_shield_bar_render(entity, state, true)
    return gained
  end

  function service.apply_damage_resistance(event, entity, state, damage_override)
    if not deps.is_gun_turret(entity) or not state then
      return 0
    end

    local mitigation = deps.get_damage_resistance_fraction(state)
    local damage = tonumber(damage_override) or tonumber(event.final_damage_amount) or 0
    if mitigation <= 0 or damage <= 0 then
      return 0
    end

    local final_health = tonumber(event.final_health) or safe_read(entity, "health")
    if not final_health or final_health <= 0 then
      return 0
    end

    local health = safe_read(entity, "health")
    local max_health = safe_read(entity, "max_health")
    if not health or not max_health or health <= 0 or health >= max_health then
      return 0
    end

    local refunded = math.min(damage * mitigation, max_health - health)
    if refunded <= 0 then
      return 0
    end

    entity.health = math.min(max_health, health + refunded)
    return refunded
  end

  function service.apply_shield_absorption(event, entity, state)
    if not deps.is_gun_turret(entity) or not state then
      return 0
    end

    local damage = tonumber(event.final_damage_amount) or 0
    if damage <= 0 then
      return 0
    end

    local shield, capacity = deps.normalize_shield_state(state, true)
    if capacity <= 0 then
      return 0
    end

    state._shield_last_damage_tick = deps.game_tick()
    deps.shield_bar_visible_for_damage(state)
    if shield <= 0 then
      deps.update_shield_bar_render(entity, state, true)
      return 0
    end

    local health = safe_read(entity, "health")
    if health == nil then
      return 0
    end

    local absorbed = math.min(shield, damage)
    if absorbed <= 0 then
      return 0
    end

    local max_health = safe_read(entity, "max_health")
    local restored_health = health + absorbed
    if max_health then
      restored_health = math.min(max_health, restored_health)
      if absorbed >= damage and restored_health >= max_health then
        -- Factorio does not expose a runtime API to show the native HP bar.
        -- Leaving a visually-full scratch lets the engine show its own bar
        -- during shield-only hits without drawing a custom HP bar.
        restored_health = math.max(1, max_health - deps.shield_health_bar_nudge)
      end
    end

    if restored_health > 0 then
      entity.health = restored_health
    end

    state.shield = math.max(0, shield - absorbed)
    deps.update_shield_bar_render(entity, state, true)
    return absorbed
  end

  function service.recharge_shield(entity, state, elapsed_ticks)
    if not deps.is_gun_turret(entity) or not state then
      return 0
    end

    local shield, capacity = deps.normalize_shield_state(state, true)
    if capacity <= 0 or shield >= capacity then
      return 0
    end

    local tick = deps.game_tick()
    local last_damage_tick = tonumber(state._shield_last_damage_tick) or 0
    if tick - last_damage_tick < deps.shield_recharge_delay_ticks then
      return 0
    end

    local recharge_ticks = math.max(1, tonumber(elapsed_ticks) or deps.shield_recharge_ticks)
    local recharge = deps.get_shield_recharge_per_second(state) * (recharge_ticks / 60)
    if recharge <= 0 then
      return 0
    end

    state.shield = math.min(capacity, shield + recharge)
    deps.update_shield_bar_render(entity, state, false)
    return state.shield - shield
  end

  function service.apply_runtime_damage(target, amount, force, damage_type)
    if not target or not target.valid or amount <= 0 then
      return false
    end

    local ok = pcall(function()
      target.damage(amount, force, damage_type or "physical")
    end)

    return ok
  end

  function service.record_scripted_damage_contribution(target_key, turret, damage)
    if not target_key or not deps.is_gun_turret(turret) or damage <= 0 then
      return
    end

    local profile = deps.get_turret_state(turret)
    if not profile then
      return
    end

    deps.ensure_storage()
    local root = deps.storage_root()
    local entry = root.targets[target_key]
    if not entry then
      entry = {
        total_damage = 0,
        turrets = {},
        tick = deps.game_tick(),
      }
      root.targets[target_key] = entry
    end

    entry.total_damage = (entry.total_damage or 0) + damage
    entry.tick = deps.game_tick()

    local key = deps.turret_key(turret)
    local contributor = entry.turrets[key]
    if not contributor then
      contributor = {
        damage = 0,
        entity = turret,
        chip_id = profile.chip_id,
      }
      entry.turrets[key] = contributor
    end

    contributor.damage = (contributor.damage or 0) + damage
    contributor.entity = turret
    contributor.chip_id = profile.chip_id
  end

  function service.apply_tracked_runtime_damage(target, amount, force, damage_type, turret)
    local target_key = deps.entity_tracking_key(target)
    local ok = service.apply_runtime_damage(target, amount, force, damage_type)
    if ok then
      service.record_scripted_damage_contribution(target_key, turret, amount)
    end

    return ok
  end

  function service.heal_turret(entity, amount)
    if not deps.is_gun_turret(entity) or amount <= 0 then
      return
    end

    local max_health = safe_read(entity, "max_health")
    local health = safe_read(entity, "health")
    if max_health and health and health > 0 and health < max_health then
      entity.health = math.min(max_health, health + amount)
    end
  end

  return service
end

return combat_application
