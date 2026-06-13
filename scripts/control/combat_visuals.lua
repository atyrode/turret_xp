local combat_visuals = {}

function combat_visuals.new(deps)
  local service = {}
  local safe_read = deps.safe_read
  local combat_constants = deps.combat_constants or {}
  local effect_budget = deps.effect_budget

  local function root()
    deps.ensure_storage()
    return deps.storage_root()
  end

  function service.draw_attack_line(surface, from, to, color, width, ttl)
    if not surface or not from or not to then
      return false
    end

    if not effect_budget.reserve_surface(surface, "render_lines") then
      return false
    end

    local ok = pcall(function()
      deps.rendering().draw_line({
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

    return ok
  end

  function service.has_entity_prototype(name)
    local entity_prototypes = deps.entity_prototypes()
    return name and entity_prototypes and entity_prototypes[name] ~= nil
  end

  function service.track_visual_entity(entity, duration)
    if not entity or not entity.valid or not duration then
      return
    end

    local ttl = math.max(1, math.floor(tonumber(duration) or 12))
    local visual_entities = root().visual_entities
    visual_entities[#visual_entities + 1] = {
      entity = entity,
      expires = deps.game_tick() + ttl,
    }
  end

  function service.create_visual_entity(surface, name, position, source, target, force, duration)
    if not surface or not name or not position or not service.has_entity_prototype(name) then
      return false
    end

    local storage_root = root()
    if
      not effect_budget.allow_active("visual_entities_active", #(storage_root.visual_entities or {}))
      or not effect_budget.reserve_surface(surface, "visual_entities")
    then
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
      service.track_visual_entity(entity, parameters.duration)
      return true
    end

    return false
  end

  function service.draw_trail(surface, from, to, trail_name, fallback_color, width, ttl, force)
    if not surface or not from or not to then
      return false
    end

    if service.create_visual_entity(surface, trail_name, to, from, to, force, ttl or 12) then
      return true
    end

    return service.draw_attack_line(surface, from, to, fallback_color, width, ttl)
  end

  function service.play_effect_sound(state, surface, sound_name, position, key, cooldown, volume)
    if not state or not surface or not sound_name or not position then
      return
    end

    state._last_effect_sound_tick = state._last_effect_sound_tick or {}
    key = key or sound_name
    cooldown = cooldown or 20
    local last_tick = state._last_effect_sound_tick[key] or 0
    if deps.game_tick() - last_tick < cooldown then
      return
    end
    if not effect_budget.reserve_surface(surface, "sounds") then
      return
    end
    state._last_effect_sound_tick[key] = deps.game_tick()

    pcall(function()
      surface.play_sound({
        path = sound_name,
        position = position,
        volume_modifier = volume or 1,
      })
    end)
  end

  function service.copy_position(position)
    if not position then
      return nil
    end

    return {
      x = position.x or position[1] or 0,
      y = position.y or position[2] or 0,
    }
  end

  function service.offset_toward_perpendicular(from, to, amount)
    from = service.copy_position(from)
    to = service.copy_position(to)
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

  function service.draw_readable_bullet_trail(surface, from, to, trail_name, color, width, ttl, force, impact_position)
    if not surface or not from or not to then
      return
    end

    local created = service.create_visual_entity(surface, trail_name, to, from, to, force, ttl or 18)
    local overlay_width = created and math.max(1, (width or 3) - 1) or (width or 3)
    service.draw_attack_line(surface, from, to, color, overlay_width, ttl or 18)
    service.create_short_effect(surface, "explosion-gunshot", impact_position or to)
  end

  function service.draw_double_shot_feedback(turret, target, second_target, force)
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
      first_visual_to = service.offset_toward_perpendicular(from, first_to, -0.12)
      second_visual_to = service.offset_toward_perpendicular(from, second_to, 0.16)
    end

    service.draw_readable_bullet_trail(
      surface,
      from,
      first_visual_to,
      combat_constants.trail.bullet,
      { 1, 0.92, 0.35 },
      3,
      20,
      force,
      first_to
    )
    service.draw_readable_bullet_trail(
      surface,
      from,
      second_visual_to,
      combat_constants.trail.bullet,
      { 1, 0.92, 0.35 },
      4,
      22,
      force,
      second_to
    )
  end

  function service.draw_crit_feedback(turret, target, force)
    local surface = safe_read(target, "surface")
    local from = safe_read(turret, "position")
    local to = safe_read(target, "position")
    if not surface or not from or not to then
      return
    end

    service.draw_readable_bullet_trail(surface, from, to, combat_constants.trail.bullet, { 1, 0.82, 0.18 }, 5, 18, force, to)
    service.draw_effect_sprite(surface, to, "virtual-signal/signal-star", 0.42, 20)
  end

  function service.draw_bounce_feedback(surface, from, to, force)
    service.draw_readable_bullet_trail(surface, from, to, combat_constants.trail.explosive, { 1, 0.58, 0.15 }, 4, 26, force, to)
  end

  function service.schedule_attack_line(surface, from, to, color, width, ttl, delay, trail_name, force)
    if not surface or not from or not to then
      return
    end

    local storage_root = root()
    local visuals = storage_root.pending_visuals
    if not effect_budget.allow_active("pending_visuals_active", #visuals) then
      return
    end

    visuals[#visuals + 1] = {
      tick = deps.game_tick() + math.max(0, math.floor(delay or 0)),
      surface_index = surface.index,
      from = service.copy_position(from),
      to = service.copy_position(to),
      color = color,
      width = width or 2,
      ttl = ttl or 20,
      trail_name = trail_name,
      force = force and (safe_read(force, "name") or force) or nil,
    }
  end

  function service.process_pending_visuals()
    service.cleanup_visual_entities()

    local storage_root = deps.storage_root()
    local visuals = storage_root and storage_root.pending_visuals
    if not visuals or #visuals == 0 then
      return
    end

    for index = #visuals, 1, -1 do
      local visual = visuals[index]
      if not visual or not visual.tick or deps.game_tick() >= visual.tick then
        local processed = true
        if visual then
          local surface = deps.get_surface(visual.surface_index)
          if visual.trail_name then
            processed =
              service.draw_trail(surface, visual.from, visual.to, visual.trail_name, visual.color, visual.width, visual.ttl, visual.force)
          else
            processed = service.draw_attack_line(surface, visual.from, visual.to, visual.color, visual.width, visual.ttl)
          end
        end
        if processed then
          table.remove(visuals, index)
        end
      end
    end
  end

  function service.cleanup_visual_entities()
    local storage_root = deps.storage_root()
    local visual_entities = storage_root and storage_root.visual_entities
    if not visual_entities or #visual_entities == 0 then
      return
    end

    for index = #visual_entities, 1, -1 do
      local entry = visual_entities[index]
      local entity = entry and entry.entity
      if not entry or not entity or not entity.valid or deps.game_tick() >= (entry.expires or 0) then
        if entity and entity.valid then
          pcall(function()
            entity.destroy({ raise_destroy = false })
          end)
        end
        table.remove(visual_entities, index)
      end
    end
  end

  function service.destroy_existing_visual_entities()
    local surfaces = deps.game_surfaces()
    if not surfaces then
      return
    end

    for _, surface in pairs(surfaces) do
      local ok, entities = pcall(function()
        return surface.find_entities_filtered({ name = combat_constants.vfx.electric_arc })
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

    root().visual_entities = {}
  end

  function service.draw_effect_sprite(surface, target, sprite, scale, ttl)
    if not surface or not target or not sprite then
      return false
    end

    if not effect_budget.reserve_surface(surface, "render_sprites") then
      return false
    end

    local ok = pcall(function()
      deps.rendering().draw_sprite({
        surface = surface,
        sprite = sprite,
        target = target,
        x_scale = scale or 0.55,
        y_scale = scale or 0.55,
        time_to_live = ttl or 30,
        render_layer = "air-object",
      })
    end)

    return ok
  end

  function service.create_short_effect(surface, name, position)
    if not surface or not name or not position then
      return false
    end

    if not effect_budget.reserve_surface(surface, "short_effects") then
      return false
    end

    local ok = pcall(function()
      surface.create_entity({
        name = name,
        position = position,
      })
    end)

    return ok
  end

  return service
end

return combat_visuals
