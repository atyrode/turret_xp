local combat_scheduler = {}

function combat_scheduler.new(deps)
  local service = {}
  local safe_read = deps.safe_read
  local effect_budget = deps.effect_budget

  function service.schedule_status_damage(turret, state, target, total_damage, damage_type, duration_ticks, interval_ticks, sprite, color)
    if not deps.is_gun_turret(turret) or not state or not target or not target.valid then
      return false
    end

    total_damage = math.max(0, tonumber(total_damage) or 0)
    if total_damage <= 0 then
      return false
    end

    deps.ensure_storage()
    interval_ticks = math.max(1, math.floor(tonumber(interval_ticks) or 60))
    duration_ticks = math.max(interval_ticks, math.floor(tonumber(duration_ticks) or interval_ticks))
    local ticks = math.max(1, math.ceil(duration_ticks / interval_ticks))
    local effects = deps.storage_root().status_effects
    effects[#effects + 1] = {
      target = target,
      turret = turret,
      chip_id = state.chip_id,
      force_name = safe_read(turret.force, "name") or turret.force,
      damage_type = damage_type or "physical",
      remaining = total_damage,
      per_tick = total_damage / ticks,
      next_tick = deps.game_tick() + interval_ticks,
      interval = interval_ticks,
      expires = deps.game_tick() + duration_ticks + interval_ticks,
      sprite = sprite,
      color = color,
    }
    return true
  end

  function service.apply_slowdown_sticker(target)
    if not target or not target.valid then
      return
    end

    local surface = safe_read(target, "surface")
    local position = safe_read(target, "position")
    if not surface or not position then
      return
    end

    pcall(function()
      surface.create_entity({
        name = "slowdown-sticker",
        position = position,
        target = target,
      })
    end)
  end

  function service.process_status_effects()
    local storage_root = deps.storage_root()
    local effects = storage_root and storage_root.status_effects
    if not effects or #effects == 0 then
      return
    end

    for index = #effects, 1, -1 do
      local effect = effects[index]
      local target = effect and effect.target
      local turret = effect and effect.turret
      local state = effect and effect.chip_id and storage_root.chips[effect.chip_id] or nil
      if
        not effect
        or not target
        or not target.valid
        or not deps.is_gun_turret(turret)
        or not state
        or (effect.expires or 0) <= deps.game_tick()
        or (effect.remaining or 0) <= 0
      then
        table.remove(effects, index)
      elseif deps.game_tick() >= (effect.next_tick or 0) and effect_budget.reserve_global("status_effect_ticks") then
        local force = effect.force_name and deps.force_by_name(effect.force_name) or safe_read(turret, "force")
        local amount = math.min(effect.remaining or 0, effect.per_tick or 0)
        local context = deps.get_entity_xp_context(target)
        if amount > 0 and deps.apply_tracked_runtime_damage(target, amount, force, effect.damage_type, turret) then
          effect.remaining = math.max(0, (effect.remaining or 0) - amount)
          deps.add_profile_damage(state, amount, turret, context)
          deps.apply_shield_on_hit(turret, state, amount)
          local lifesteal_rate = deps.get_lifesteal_rate(state)
          if lifesteal_rate > 0 then
            deps.heal_turret(turret, amount * lifesteal_rate)
          end
          deps.sync_turret_progression(state)
          local surface = safe_read(target, "surface")
          local position = safe_read(target, "position")
          if effect.sprite then
            deps.draw_effect_sprite(surface, position, effect.sprite, 0.34, 20)
          elseif effect.color then
            deps.draw_attack_line(surface, position, {
              x = position.x,
              y = position.y - 0.2,
            }, effect.color, 2, 12)
          end
        end

        effect.next_tick = deps.game_tick() + (effect.interval or 60)
        if effect.remaining <= 0 or not target.valid then
          table.remove(effects, index)
        end
      end
    end
  end

  return service
end

return combat_scheduler
