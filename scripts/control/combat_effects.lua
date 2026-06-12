return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  function apply_passive_evolution_effects()
    ensure_storage()

    for _, state in pairs(storage.turret_xp.chips) do
      ensure_evolution_state(state)
      local entity = state.entity
      if is_gun_turret(entity) then
        entity = combat.sync_turret_body_when_idle(entity, state)
        auto_feed_open_turret(state)
        combat.apply_ammo_regeneration(entity, state)
        local repair_per_second = get_repair_per_second(state, entity)
        if repair_per_second > 0 then
          local max_health = safe_read(entity, "max_health")
          local health = safe_read(entity, "health")
          if max_health and health and health > 0 and health < max_health then
            entity.health = math.min(max_health, health + (repair_per_second * (REFRESH_TICKS / 60)))
          end
        end
        update_name_render(entity, state)
      elseif entity and not entity.valid then
        destroy_name_render(state)
        state.entity = nil
      end
    end
  end

  function combat.remember_loaded_ammo(entity, state)
    if not is_gun_turret(entity) or not state then
      return nil
    end

    local ammo_name, ammo_count, ammo_quality = get_loaded_ammo(entity)
    if ammo_name and (ammo_count or 0) > 0 and feeder.is_ammo_item(ammo_name) then
      state.last_ammo = {
        name = ammo_name,
        quality = ammo_quality or "normal",
      }
    end

    return state.last_ammo
  end

  function combat.insert_recovered_ammo(entity, ammo, amount)
    if not is_gun_turret(entity) or not ammo or not ammo.name or amount <= 0 then
      return 0
    end

    local inventory = feeder.get_entity_inventory(entity, defines.inventory.turret_ammo)
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

  function combat.apply_ammo_regeneration(entity, state)
    local rank = get_base_rank(state, "ammo_regen")
    local last_ammo = combat.remember_loaded_ammo(entity, state)
    if rank <= 0 then
      state.ammo_regen_progress = 0
      return
    end

    if not last_ammo or not feeder.is_ammo_item(last_ammo.name) then
      state.ammo_regen_progress = math.min(1, tonumber(state.ammo_regen_progress) or 0)
      return
    end

    local recovery_per_minute = get_ammo_recovery_per_minute(state)
    local progress = (tonumber(state.ammo_regen_progress) or 0) + ((recovery_per_minute * REFRESH_TICKS) / AMMO_REGEN_TICKS_PER_ROUND)
    local amount = math.floor(progress)
    if amount <= 0 then
      state.ammo_regen_progress = progress
      return
    end

    local inserted = combat.insert_recovered_ammo(entity, last_ammo, amount)
    if inserted > 0 then
      state.ammo_regen_progress = math.max(0, progress - inserted)
      return
    end

    state.ammo_regen_progress = math.min(progress, 1)
  end

  function combat.apply_damage_resistance(event, entity, state)
    if not is_gun_turret(entity) or not state then
      return 0
    end

    local mitigation = get_damage_resistance_fraction(state)
    local damage = tonumber(event.final_damage_amount) or 0
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

  function combat.chance_roll(chance)
    chance = math.max(0, math.min(0.95, chance or 0))
    return chance > 0 and math.random() < chance
  end

  function combat.get_distance(a, b)
    if not a or not b then
      return 0
    end

    local dx = (a.x or a[1] or 0) - (b.x or b[1] or 0)
    local dy = (a.y or a[2] or 0) - (b.y or b[2] or 0)
    return math.sqrt((dx * dx) + (dy * dy))
  end

  function combat.apply_runtime_damage(target, amount, force, damage_type)
    if not target or not target.valid or amount <= 0 then
      return false
    end

    local ok = pcall(function()
      target.damage(amount, force, damage_type or "physical")
    end)

    return ok
  end

  function combat.record_scripted_damage_contribution(target_key, turret, damage)
    if not target_key or not is_gun_turret(turret) or damage <= 0 then
      return
    end

    local profile = get_turret_state(turret)
    if not profile then
      return
    end

    ensure_storage()
    local entry = storage.turret_xp.targets[target_key]
    if not entry then
      entry = {
        total_damage = 0,
        turrets = {},
        tick = game.tick,
      }
      storage.turret_xp.targets[target_key] = entry
    end

    entry.total_damage = (entry.total_damage or 0) + damage
    entry.tick = game.tick

    local key = turret_key(turret)
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

  function combat.apply_tracked_runtime_damage(target, amount, force, damage_type, turret)
    local target_key = entity_tracking_key(target)
    local ok = combat.apply_runtime_damage(target, amount, force, damage_type)
    if ok then
      combat.record_scripted_damage_contribution(target_key, turret, amount)
    end

    return ok
  end

  function combat.heal_turret(entity, amount)
    if not is_gun_turret(entity) or amount <= 0 then
      return
    end

    local max_health = safe_read(entity, "max_health")
    local health = safe_read(entity, "health")
    if max_health and health and health > 0 and health < max_health then
      entity.health = math.min(max_health, health + amount)
    end
  end

  function combat.find_nearby_enemy(surface, position, force, radius, exclude)
    if not surface or not position then
      return nil
    end

    local entities = surface.find_entities_filtered({
      area = {
        { position.x - radius, position.y - radius },
        { position.x + radius, position.y + radius },
      },
    })

    for _, entity in pairs(entities) do
      local excluded = entity == exclude
      if type(exclude) == "table" and not exclude.valid then
        local unit_number = safe_read(entity, "unit_number")
        excluded = excluded or exclude[unit_number] == true or exclude[entity_tracking_key(entity)] == true
      end
      if
        entity.valid
        and not excluded
        and safe_read(entity, "health")
        and entity.force ~= force
        and combat.get_distance(position, entity.position) <= radius
      then
        return entity
      end
    end

    return nil
  end

  function combat.draw_attack_line(surface, from, to, color, width, ttl)
    if not surface or not from or not to then
      return
    end

    pcall(function()
      rendering.draw_line({
        surface = surface,
        from = from,
        to = to,
        color = color,
        width = width or 2,
        time_to_live = ttl or 20,
        forces = nil,
        draw_on_ground = false,
      })
    end)
  end

  function combat.has_entity_prototype(name)
    return name and prototypes and prototypes.entity and prototypes.entity[name] ~= nil
  end

  function combat.track_visual_entity(entity, duration)
    if not entity or not entity.valid or not duration then
      return
    end

    ensure_storage()
    local ttl = math.max(1, math.floor(tonumber(duration) or 12))
    local visual_entities = storage.turret_xp.visual_entities
    visual_entities[#visual_entities + 1] = {
      entity = entity,
      expires = game.tick + ttl,
    }
  end

  function combat.create_visual_entity(surface, name, position, source, target, force, duration)
    if not surface or not name or not position or not combat.has_entity_prototype(name) then
      return false
    end

    local parameters = {
      name = name,
      position = position,
      source = source,
      target = target,
      force = force and (safe_read(force, "name") or force) or nil,
    }
    if duration then
      parameters.duration = math.max(1, math.floor(tonumber(duration) or 12))
    end

    local ok, entity = pcall(function()
      return surface.create_entity(parameters)
    end)

    if ok and entity ~= nil then
      combat.track_visual_entity(entity, parameters.duration)
      return true
    end

    return false
  end

  function combat.draw_trail(surface, from, to, trail_name, fallback_color, width, ttl, force)
    if not surface or not from or not to then
      return
    end

    if combat.create_visual_entity(surface, trail_name, to, from, to, force, ttl or 12) then
      return
    end

    combat.draw_attack_line(surface, from, to, fallback_color, width, ttl)
  end

  function combat.play_effect_sound(state, surface, sound_name, position, key, cooldown, volume)
    if not state or not surface or not sound_name or not position then
      return
    end

    state._last_effect_sound_tick = state._last_effect_sound_tick or {}
    key = key or sound_name
    cooldown = cooldown or 20
    local last_tick = state._last_effect_sound_tick[key] or 0
    if game.tick - last_tick < cooldown then
      return
    end
    state._last_effect_sound_tick[key] = game.tick

    pcall(function()
      surface.play_sound({
        path = sound_name,
        position = position,
        volume_modifier = volume or 1,
      })
    end)
  end

  function combat.copy_position(position)
    if not position then
      return nil
    end

    return {
      x = position.x or position[1] or 0,
      y = position.y or position[2] or 0,
    }
  end

  function combat.offset_toward_perpendicular(from, to, amount)
    from = combat.copy_position(from)
    to = combat.copy_position(to)
    if not from or not to then
      return to
    end

    local dx = to.x - from.x
    local dy = to.y - from.y
    local distance = math.sqrt((dx * dx) + (dy * dy))
    if distance <= 0.001 then
      return to
    end

    return {
      x = to.x + ((-dy / distance) * (amount or 0.12)),
      y = to.y + ((dx / distance) * (amount or 0.12)),
    }
  end

  function combat.draw_readable_bullet_trail(surface, from, to, trail_name, color, width, ttl, force, impact_position)
    if not surface or not from or not to then
      return
    end

    local created = combat.create_visual_entity(surface, trail_name, to, from, to, force, ttl or 18)
    local overlay_width = created and math.max(1, (width or 3) - 1) or (width or 3)
    combat.draw_attack_line(surface, from, to, color, overlay_width, ttl or 18)
    combat.create_short_effect(surface, "explosion-gunshot", impact_position or to)
  end

  function combat.draw_double_shot_feedback(turret, target, second_target, force)
    local surface = safe_read(second_target, "surface") or safe_read(target, "surface")
    local from = safe_read(turret, "position")
    local first_to = safe_read(target, "position")
    local second_to = safe_read(second_target, "position") or first_to
    if not surface or not from or not first_to or not second_to then
      return
    end

    local first_visual_to = first_to
    local second_visual_to = second_to
    if second_target == target then
      first_visual_to = combat.offset_toward_perpendicular(from, first_to, -0.12)
      second_visual_to = combat.offset_toward_perpendicular(from, second_to, 0.16)
    end

    combat.draw_readable_bullet_trail(
      surface,
      from,
      first_visual_to,
      COMBAT_CONSTANTS.trail.bullet,
      { 1, 0.92, 0.35 },
      3,
      20,
      force,
      first_to
    )
    combat.draw_readable_bullet_trail(
      surface,
      from,
      second_visual_to,
      COMBAT_CONSTANTS.trail.bullet,
      { 1, 0.92, 0.35 },
      4,
      22,
      force,
      second_to
    )
  end

  function combat.draw_crit_feedback(turret, target, force)
    local surface = safe_read(target, "surface")
    local from = safe_read(turret, "position")
    local to = safe_read(target, "position")
    if not surface or not from or not to then
      return
    end

    combat.draw_readable_bullet_trail(surface, from, to, COMBAT_CONSTANTS.trail.bullet, { 1, 0.82, 0.18 }, 5, 18, force, to)
    combat.draw_effect_sprite(surface, to, "virtual-signal/signal-star", 0.42, 20)
  end

  function combat.draw_bounce_feedback(surface, from, to, force)
    combat.draw_readable_bullet_trail(surface, from, to, COMBAT_CONSTANTS.trail.explosive, { 1, 0.58, 0.15 }, 4, 26, force, to)
  end

  function combat.schedule_attack_line(surface, from, to, color, width, ttl, delay, trail_name, force)
    if not surface or not from or not to then
      return
    end

    ensure_storage()
    local visuals = storage.turret_xp.pending_visuals
    visuals[#visuals + 1] = {
      tick = game.tick + math.max(0, math.floor(delay or 0)),
      surface_index = surface.index,
      from = combat.copy_position(from),
      to = combat.copy_position(to),
      color = color,
      width = width or 2,
      ttl = ttl or 20,
      trail_name = trail_name,
      force = force and (safe_read(force, "name") or force) or nil,
    }
  end

  function combat.process_pending_visuals()
    combat.cleanup_visual_entities()

    local mod_storage = storage and storage.turret_xp
    local visuals = mod_storage and mod_storage.pending_visuals
    if not visuals or #visuals == 0 then
      return
    end

    for index = #visuals, 1, -1 do
      local visual = visuals[index]
      if not visual or not visual.tick or game.tick >= visual.tick then
        if visual then
          local surface = game.get_surface(visual.surface_index)
          if visual.trail_name then
            combat.draw_trail(surface, visual.from, visual.to, visual.trail_name, visual.color, visual.width, visual.ttl, visual.force)
          else
            combat.draw_attack_line(surface, visual.from, visual.to, visual.color, visual.width, visual.ttl)
          end
        end
        table.remove(visuals, index)
      end
    end
  end

  function combat.schedule_status_damage(turret, state, target, total_damage, damage_type, duration_ticks, interval_ticks, sprite, color)
    if not is_gun_turret(turret) or not state or not target or not target.valid then
      return false
    end

    total_damage = math.max(0, tonumber(total_damage) or 0)
    if total_damage <= 0 then
      return false
    end

    ensure_storage()
    interval_ticks = math.max(1, math.floor(tonumber(interval_ticks) or 60))
    duration_ticks = math.max(interval_ticks, math.floor(tonumber(duration_ticks) or interval_ticks))
    local ticks = math.max(1, math.ceil(duration_ticks / interval_ticks))
    local effects = storage.turret_xp.status_effects
    effects[#effects + 1] = {
      target = target,
      turret = turret,
      chip_id = state.chip_id,
      force_name = safe_read(turret.force, "name") or turret.force,
      damage_type = damage_type or "physical",
      remaining = total_damage,
      per_tick = total_damage / ticks,
      next_tick = game.tick + interval_ticks,
      interval = interval_ticks,
      expires = game.tick + duration_ticks + interval_ticks,
      sprite = sprite,
      color = color,
    }
    return true
  end

  function combat.apply_slowdown_sticker(target)
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

  function combat.process_status_effects()
    local mod_storage = storage and storage.turret_xp
    local effects = mod_storage and mod_storage.status_effects
    if not effects or #effects == 0 then
      return
    end

    for index = #effects, 1, -1 do
      local effect = effects[index]
      local target = effect and effect.target
      local turret = effect and effect.turret
      local state = effect and effect.chip_id and storage.turret_xp.chips[effect.chip_id] or nil
      if
        not effect
        or not target
        or not target.valid
        or not is_gun_turret(turret)
        or not state
        or (effect.expires or 0) <= game.tick
        or (effect.remaining or 0) <= 0
      then
        table.remove(effects, index)
      elseif game.tick >= (effect.next_tick or 0) then
        local force = effect.force_name and game.forces[effect.force_name] or safe_read(turret, "force")
        local amount = math.min(effect.remaining or 0, effect.per_tick or 0)
        local context = combat.get_entity_xp_context(target)
        if amount > 0 and combat.apply_tracked_runtime_damage(target, amount, force, effect.damage_type, turret) then
          effect.remaining = math.max(0, (effect.remaining or 0) - amount)
          add_profile_damage(state, amount, turret, context)
          local siphon_rate = get_lifesteal_rate(state)
          if siphon_rate > 0 then
            combat.heal_turret(turret, amount * siphon_rate)
          end
          sync_turret_progression(state)
          local surface = safe_read(target, "surface")
          local position = safe_read(target, "position")
          if effect.sprite then
            combat.draw_effect_sprite(surface, position, effect.sprite, 0.34, 20)
          elseif effect.color then
            combat.draw_attack_line(surface, position, {
              x = position.x,
              y = position.y - 0.2,
            }, effect.color, 2, 12)
          end
        end

        effect.next_tick = game.tick + (effect.interval or 60)
        if effect.remaining <= 0 or not target.valid then
          table.remove(effects, index)
        end
      end
    end
  end

  function combat.cleanup_visual_entities()
    local mod_storage = storage and storage.turret_xp
    local visual_entities = mod_storage and mod_storage.visual_entities
    if not visual_entities or #visual_entities == 0 then
      return
    end

    for index = #visual_entities, 1, -1 do
      local entry = visual_entities[index]
      local entity = entry and entry.entity
      if not entry or not entity or not entity.valid or game.tick >= (entry.expires or 0) then
        if entity and entity.valid then
          pcall(function()
            entity.destroy({ raise_destroy = false })
          end)
        end
        table.remove(visual_entities, index)
      end
    end
  end

  function combat.destroy_existing_visual_entities()
    if not game or not game.surfaces then
      return
    end

    for _, surface in pairs(game.surfaces) do
      local ok, entities = pcall(function()
        return surface.find_entities_filtered({ name = COMBAT_CONSTANTS.vfx.electric_arc })
      end)
      if ok and entities then
        for _, entity in pairs(entities) do
          if entity and entity.valid then
            pcall(function()
              entity.destroy({ raise_destroy = false })
            end)
          end
        end
      end
    end

    ensure_storage()
    storage.turret_xp.visual_entities = {}
  end

  function combat.draw_effect_sprite(surface, target, sprite, scale, ttl)
    if not surface or not target or not sprite then
      return
    end

    pcall(function()
      rendering.draw_sprite({
        surface = surface,
        sprite = sprite,
        target = target,
        x_scale = scale or 0.55,
        y_scale = scale or 0.55,
        time_to_live = ttl or 30,
        render_layer = "air-object",
      })
    end)
  end

  function combat.create_short_effect(surface, name, position)
    if not surface or not name or not position then
      return
    end

    pcall(function()
      surface.create_entity({
        name = name,
        position = position,
      })
    end)
  end

  function combat.get_element_effect_multiplier(state, element_id)
    local rank = get_element_rank(state, element_id)
    if rank <= 0 then
      return 0
    end

    return 1 + ((rank - 1) * 0.18)
  end

  function combat.get_element_proc_chance(state, element_id)
    local rank = get_element_rank(state, element_id)
    if rank <= 0 then
      return 0
    end

    return math.min(0.60, 0.10 + (rank * 0.02))
  end

  function combat.get_electric_arc_count(state)
    local rank = get_element_rank(state, "electric")
    if rank <= 0 then
      return 0
    end

    return math.min(5, rank)
  end

  get_element_effect_summary = function(state, element_id)
    local rank = get_element_rank(state, element_id)
    return get_element_effect_summary_for_rank(state, element_id, rank, true)
  end

  function combat.draw_element_feedback(state, element_id, surface, from, to, force)
    if not state or not surface or not from or not to then
      return
    end

    state._last_element_visual_tick = state._last_element_visual_tick or {}
    local last_tick = state._last_element_visual_tick[element_id] or 0
    if game.tick - last_tick < 8 then
      return
    end
    state._last_element_visual_tick[element_id] = game.tick

    if element_id == "fire" then
      combat.draw_trail(surface, from, to, COMBAT_CONSTANTS.trail.fire, { 1, 0.28, 0.05 }, 1, 10, force)
    elseif element_id == "electric" then
      combat.draw_trail(surface, from, to, COMBAT_CONSTANTS.trail.electric_faint, { 0.35, 0.75, 1 }, 1, 10, force)
    elseif element_id == "explosive" then
      combat.draw_trail(surface, from, to, COMBAT_CONSTANTS.trail.explosive, { 1, 0.58, 0.15 }, 1, 10, force)
    elseif element_id == "toxic" then
      combat.draw_trail(surface, from, to, COMBAT_CONSTANTS.trail.toxic, { 0.42, 0.92, 0.28 }, 1, 10, force)
    end
  end

  function combat.get_active_elements(state)
    local evolution = ensure_evolution_state(state)
    local elements = {}
    for slot = 1, 2 do
      if evolution.elements[slot] then
        elements[#elements + 1] = evolution.elements[slot]
      end
    end
    return elements
  end

  function combat.has_element_pair(state, a, b)
    local elements = combat.get_active_elements(state)
    if #elements < 2 then
      return false
    end

    return (elements[1] == a and elements[2] == b) or (elements[1] == b and elements[2] == a)
  end

  function combat.apply_element_effects_to_target(turret, state, target, base_damage, force, source_position)
    local upgrade_damage = 0
    local flags = {
      fire = false,
      electric = false,
      explosive = false,
      toxic = false,
    }

    for _, element_id in ipairs(combat.get_active_elements(state)) do
      if not target or not target.valid then
        break
      end

      if element_is_powered(state, element_id) then
        local element_multiplier = combat.get_element_effect_multiplier(state, element_id)
        local element_proc_chance = apply_luck_to_chance(state, combat.get_element_proc_chance(state, element_id))
        local effect_surface = safe_read(target, "surface")
        local effect_position = safe_read(target, "position")
        local visual_from = source_position or safe_read(turret, "position")
        combat.draw_element_feedback(state, element_id, effect_surface, visual_from, effect_position, force)

        if element_id == "fire" and combat.chance_roll(element_proc_chance) then
          flags.fire = true
          local amount = base_damage * 0.10 * element_multiplier
          if combat.apply_tracked_runtime_damage(target, amount, force, "fire", turret) then
            upgrade_damage = upgrade_damage + amount
            combat.schedule_status_damage(
              turret,
              state,
              target,
              base_damage * 0.25 * element_multiplier,
              "fire",
              4 * 60,
              60,
              "virtual-signal/signal-fire",
              { 1, 0.28, 0.05 }
            )
            if
              not combat.create_visual_entity(
                effect_surface,
                COMBAT_CONSTANTS.vfx.fire_flash,
                effect_position,
                effect_position,
                effect_position,
                force
              )
            then
              combat.draw_effect_sprite(effect_surface, effect_position, "virtual-signal/signal-fire", 0.45, 24)
            end
            combat.play_effect_sound(state, effect_surface, COMBAT_CONSTANTS.sfx.fire, effect_position, "fire", 28, 0.75)
          end
        elseif element_id == "electric" and combat.chance_roll(element_proc_chance) then
          flags.electric = true
          local arc_surface = safe_read(target, "surface")
          local arc_from = safe_read(target, "position")
          local amount = base_damage * 0.25 * element_multiplier
          local excluded = {}
          local target_key = entity_tracking_key(target)
          if target_key then
            excluded[target_key] = true
          end
          local target_unit_number = safe_read(target, "unit_number")
          if target_unit_number then
            excluded[target_unit_number] = true
          end
          for _ = 1, combat.get_electric_arc_count(state) do
            local arc_target = combat.find_nearby_enemy(arc_surface, arc_from, force, 7, excluded)
            local arc_to = safe_read(arc_target, "position")
            if not arc_target then
              break
            end
            local arc_key = entity_tracking_key(arc_target)
            if arc_key then
              excluded[arc_key] = true
            end
            local arc_unit_number = safe_read(arc_target, "unit_number")
            if arc_unit_number then
              excluded[arc_unit_number] = true
            end
            if combat.apply_tracked_runtime_damage(arc_target, amount, force, "electric", turret) then
              upgrade_damage = upgrade_damage + amount
              if not combat.create_visual_entity(arc_surface, COMBAT_CONSTANTS.vfx.electric_arc, arc_to, arc_from, arc_to, force, 18) then
                combat.draw_trail(arc_surface, arc_from, arc_to, COMBAT_CONSTANTS.trail.electric, { 0.35, 0.75, 1 }, 2, 18, force)
              end
              combat.play_effect_sound(state, arc_surface, COMBAT_CONSTANTS.sfx.electric, arc_from, "electric", 20, 0.7)
            end
          end
        elseif element_id == "explosive" and combat.chance_roll(element_proc_chance) then
          flags.explosive = true
          local splashed = 0
          local splash_radius = 3 + math.min(3, get_element_rank(state, "explosive") * 0.15)
          local splash_surface = safe_read(target, "surface")
          local splash_position = safe_read(target, "position")
          local entities = splash_surface
              and splash_position
              and splash_surface.find_entities_filtered({
                area = {
                  { splash_position.x - splash_radius, splash_position.y - splash_radius },
                  { splash_position.x + splash_radius, splash_position.y + splash_radius },
                },
              })
            or {}
          combat.create_short_effect(splash_surface, "explosion", splash_position)
          for _, nearby in pairs(entities) do
            if splashed >= 4 then
              break
            end
            if nearby.valid and nearby ~= target and safe_read(nearby, "health") and nearby.force ~= force then
              local amount = base_damage * 0.20 * element_multiplier
              if combat.apply_tracked_runtime_damage(nearby, amount, force, "explosion", turret) then
                upgrade_damage = upgrade_damage + amount
                splashed = splashed + 1
              end
            end
          end
        elseif element_id == "toxic" and combat.chance_roll(element_proc_chance) then
          flags.toxic = true
          combat.schedule_status_damage(
            turret,
            state,
            target,
            base_damage * 0.08 * element_multiplier,
            "poison",
            8 * 60,
            60,
            "virtual-signal/signal-skull",
            { 0.42, 0.92, 0.28 }
          )
          combat.apply_slowdown_sticker(target)
          if
            not combat.create_visual_entity(
              effect_surface,
              COMBAT_CONSTANTS.vfx.toxic_puff,
              effect_position,
              effect_position,
              effect_position,
              force,
              90
            )
          then
            combat.draw_effect_sprite(effect_surface, effect_position, "virtual-signal/signal-skull", 0.38, 30)
          end
        end
      end
    end

    if not target or not target.valid then
      flags.fire = false
      flags.electric = false
      flags.explosive = false
      flags.toxic = false
    end

    return upgrade_damage, flags
  end

  function combat.apply_combo_effects_to_target(turret, state, target, base_damage, force, flags)
    if not target or not target.valid or not flags then
      return 0
    end

    local upgrade_damage = 0
    if flags.fire and flags.electric and combat.has_element_pair(state, "fire", "electric") then
      local stormfire = base_damage * 0.15
      local effect_surface = safe_read(target, "surface")
      local effect_position = safe_read(target, "position")
      if combat.apply_tracked_runtime_damage(target, stormfire, force, "fire", turret) then
        upgrade_damage = upgrade_damage + stormfire
        if
          not combat.create_visual_entity(
            effect_surface,
            COMBAT_CONSTANTS.vfx.fire_flash,
            effect_position,
            effect_position,
            effect_position,
            force
          )
        then
          combat.draw_effect_sprite(effect_surface, effect_position, "virtual-signal/signal-fire", 0.55, 30)
        end
        combat.play_effect_sound(state, effect_surface, COMBAT_CONSTANTS.sfx.fire, effect_position, "combo-fire", 36, 0.65)
      end
    elseif flags.fire and flags.explosive and combat.has_element_pair(state, "fire", "explosive") then
      local incendiary = base_damage * 0.20
      local effect_surface = safe_read(target, "surface")
      local effect_position = safe_read(target, "position")
      if combat.apply_tracked_runtime_damage(target, incendiary, force, "fire", turret) then
        upgrade_damage = upgrade_damage + incendiary
        if
          not combat.create_visual_entity(
            effect_surface,
            COMBAT_CONSTANTS.vfx.fire_flash,
            effect_position,
            effect_position,
            effect_position,
            force
          )
        then
          combat.draw_effect_sprite(effect_surface, effect_position, "virtual-signal/signal-fire", 0.55, 30)
        end
        combat.create_short_effect(effect_surface, "explosion-gunshot", effect_position)
        combat.play_effect_sound(state, effect_surface, COMBAT_CONSTANTS.sfx.fire, effect_position, "combo-fire", 36, 0.65)
      end
    elseif flags.electric and flags.explosive and combat.has_element_pair(state, "electric", "explosive") then
      local shock_surface = safe_read(target, "surface")
      local shock_from = safe_read(target, "position")
      local shockburst_target = combat.find_nearby_enemy(shock_surface, shock_from, force, 8, target)
      local shock_to = safe_read(shockburst_target, "position")
      if shockburst_target and combat.apply_tracked_runtime_damage(shockburst_target, base_damage * 0.25, force, "electric", turret) then
        upgrade_damage = upgrade_damage + (base_damage * 0.25)
        if not combat.create_visual_entity(shock_surface, COMBAT_CONSTANTS.vfx.electric_arc, shock_to, shock_from, shock_to, force, 18) then
          combat.draw_trail(shock_surface, shock_from, shock_to, COMBAT_CONSTANTS.trail.electric, { 0.35, 0.75, 1 }, 2, 18, force)
        end
        combat.create_short_effect(shock_surface, "explosion-gunshot", shock_from)
        combat.play_effect_sound(state, shock_surface, COMBAT_CONSTANTS.sfx.electric, shock_from, "combo-electric", 28, 0.7)
      end
    elseif flags.fire and flags.toxic and combat.has_element_pair(state, "fire", "toxic") then
      local effect_surface = safe_read(target, "surface")
      local effect_position = safe_read(target, "position")
      local choking = base_damage * 0.18
      if
        combat.schedule_status_damage(
          turret,
          state,
          target,
          choking,
          "poison",
          5 * 60,
          60,
          "virtual-signal/signal-skull",
          { 0.42, 0.92, 0.28 }
        )
      then
        combat.create_visual_entity(
          effect_surface,
          COMBAT_CONSTANTS.vfx.toxic_puff,
          effect_position,
          effect_position,
          effect_position,
          force,
          90
        )
      end
    elseif flags.electric and flags.toxic and combat.has_element_pair(state, "electric", "toxic") then
      combat.apply_slowdown_sticker(target)
    elseif flags.explosive and flags.toxic and combat.has_element_pair(state, "explosive", "toxic") then
      local splash_surface = safe_read(target, "surface")
      local splash_position = safe_read(target, "position")
      local entities = splash_surface
          and splash_position
          and splash_surface.find_entities_filtered({
            area = {
              { splash_position.x - 3, splash_position.y - 3 },
              { splash_position.x + 3, splash_position.y + 3 },
            },
          })
        or {}
      local spread = 0
      for _, nearby in pairs(entities) do
        if spread >= 3 then
          break
        end
        if nearby.valid and nearby ~= target and safe_read(nearby, "health") and nearby.force ~= force then
          combat.schedule_status_damage(
            turret,
            state,
            nearby,
            base_damage * 0.06,
            "poison",
            8 * 60,
            60,
            "virtual-signal/signal-skull",
            { 0.42, 0.92, 0.28 }
          )
          combat.apply_slowdown_sticker(nearby)
          spread = spread + 1
        end
      end
    end

    return upgrade_damage
  end

  function combat.apply_evolution_damage_effects(event, turret, state, base_damage)
    if not event.entity or not event.entity.valid or base_damage <= 0 then
      return
    end

    local force = turret.force
    local target = event.entity
    local target_xp_context = combat.get_entity_xp_context(target)
    local upgrade_damage = 0

    local damage_multiplier = get_specialization_multiplier(state, "damage_multiplier")
    local bonus_damage = get_base_rank(state, "damage") * 0.5 * damage_multiplier
    local shot_damage = base_damage + bonus_damage

    if bonus_damage > 0 and combat.apply_tracked_runtime_damage(target, bonus_damage, force, "physical", turret) then
      upgrade_damage = upgrade_damage + bonus_damage
    end

    local crit_chance = get_crit_chance_fraction(state)
    if combat.chance_roll(crit_chance) then
      local crit_damage = shot_damage * get_crit_damage_fraction(state)
      if combat.apply_tracked_runtime_damage(target, crit_damage, force, "physical", turret) then
        upgrade_damage = upgrade_damage + crit_damage
        combat.draw_crit_feedback(turret, target, force)
      end
    end

    if target.valid then
      local double_shot_chance = get_double_shot_chance(state)
      if double_shot_chance > 0 and combat.chance_roll(double_shot_chance) then
        local line_surface = safe_read(target, "surface")
        local second_target = combat.find_nearby_enemy(line_surface, safe_read(target, "position"), force, 8, target) or target
        if
          second_target
          and second_target.valid
          and combat.apply_tracked_runtime_damage(second_target, shot_damage, force, "physical", turret)
        then
          upgrade_damage = upgrade_damage + shot_damage
          combat.draw_double_shot_feedback(turret, target, second_target, force)
        end
      end
    end

    if not target.valid then
      if upgrade_damage > 0 then
        add_profile_damage(state, upgrade_damage, turret, target_xp_context)
        sync_turret_progression(state)
        local siphon_rate = get_lifesteal_rate(state)
        combat.heal_turret(turret, (base_damage + upgrade_damage) * siphon_rate)
      end
      return
    end

    local bounce_rank = get_augment_rank(state, "bounce")
    local bounce_chance = apply_luck_to_chance(state, bounce_rank * 0.05)
    if bounce_rank > 0 and combat.chance_roll(bounce_chance) then
      local bounce_surface = safe_read(target, "surface")
      local bounce_from = safe_read(target, "position")
      local bounce_target = combat.find_nearby_enemy(bounce_surface, bounce_from, force, 6, target)
      local bounce_to = safe_read(bounce_target, "position")
      local bounce_damage = shot_damage * 0.35
      if bounce_target and combat.apply_tracked_runtime_damage(bounce_target, bounce_damage, force, "physical", turret) then
        upgrade_damage = upgrade_damage + bounce_damage
        combat.draw_bounce_feedback(bounce_surface, bounce_from, bounce_to, force)
        local bounced_element_damage, bounced_flags =
          combat.apply_element_effects_to_target(turret, state, bounce_target, bounce_damage, force, bounce_from)
        upgrade_damage = upgrade_damage + bounced_element_damage
        upgrade_damage = upgrade_damage
          + combat.apply_combo_effects_to_target(turret, state, bounce_target, bounce_damage, force, bounced_flags)
      end
    end

    if target.valid then
      local element_damage, element_flags =
        combat.apply_element_effects_to_target(turret, state, target, shot_damage, force, safe_read(turret, "position"))
      upgrade_damage = upgrade_damage + element_damage
      upgrade_damage = upgrade_damage + combat.apply_combo_effects_to_target(turret, state, target, shot_damage, force, element_flags)
    end

    local siphon_rate = get_lifesteal_rate(state)
    if siphon_rate > 0 then
      combat.heal_turret(turret, (base_damage + upgrade_damage) * siphon_rate)
    end

    if upgrade_damage > 0 then
      add_profile_damage(state, upgrade_damage, turret, target_xp_context)
      sync_turret_progression(state)
    end
  end
end
