local combat_dispatch = {}

function combat_dispatch.new(deps)
  local service = {}
  local combat = deps.combat
  local safe_read = deps.safe_read
  local element_effects = deps.descriptors.elements
  local combo_effects = deps.descriptors.combos

  function service.get_element_effect_multiplier(state, element_id)
    local rank = deps.get_element_rank(state, element_id)
    if rank <= 0 then
      return 0
    end

    return 1 + ((rank - 1) * 0.18)
  end

  function service.get_element_proc_chance(state, element_id)
    local rank = deps.get_element_rank(state, element_id)
    if rank <= 0 then
      return 0
    end

    return math.min(0.60, 0.10 + (rank * 0.02))
  end

  function service.get_electric_arc_count(state)
    local rank = deps.get_element_rank(state, "electric")
    if rank <= 0 then
      return 0
    end

    return math.min(5, rank)
  end

  function service.get_element_effect_summary(state, element_id)
    local rank = deps.get_element_rank(state, element_id)
    return deps.get_element_effect_summary_for_rank(state, element_id, rank, true)
  end

  function service.draw_element_feedback(state, element_id, surface, from, to, force)
    if not state or not surface or not from or not to then
      return
    end

    local descriptor = element_effects[element_id]
    if not descriptor then
      return
    end

    state._last_element_visual_tick = state._last_element_visual_tick or {}
    local last_tick = state._last_element_visual_tick[element_id] or 0
    if deps.game_tick() - last_tick < 8 then
      return
    end
    state._last_element_visual_tick[element_id] = deps.game_tick()

    combat.draw_trail(surface, from, to, descriptor.trail, descriptor.color, descriptor.trail_width, descriptor.trail_ttl, force)
  end

  local element_handlers = {}

  function element_handlers.fire(context)
    local descriptor = context.descriptor
    context.flags.fire = true
    local amount = context.base_damage * descriptor.direct_damage_multiplier * context.element_multiplier
    if combat.apply_tracked_runtime_damage(context.target, amount, context.force, descriptor.status_damage_type, context.turret) then
      combat.schedule_status_damage(
        context.turret,
        context.state,
        context.target,
        context.base_damage * descriptor.status_damage_multiplier * context.element_multiplier,
        descriptor.status_damage_type,
        descriptor.status_duration,
        descriptor.status_interval,
        descriptor.status_sprite,
        descriptor.color
      )
      if
        not combat.create_visual_entity(
          context.effect_surface,
          descriptor.visual_entity,
          context.effect_position,
          context.effect_position,
          context.effect_position,
          context.force
        )
      then
        combat.draw_effect_sprite(
          context.effect_surface,
          context.effect_position,
          descriptor.fallback_sprite,
          descriptor.fallback_sprite_scale,
          descriptor.fallback_sprite_ttl
        )
      end
      combat.play_effect_sound(
        context.state,
        context.effect_surface,
        descriptor.sound,
        context.effect_position,
        descriptor.sound_key,
        descriptor.sound_cooldown,
        descriptor.sound_volume
      )
      return amount
    end

    return 0
  end

  function element_handlers.electric(context)
    local descriptor = context.descriptor
    context.flags.electric = true
    local arc_surface = safe_read(context.target, "surface")
    local arc_from = safe_read(context.target, "position")
    local amount = context.base_damage * descriptor.arc_damage_multiplier * context.element_multiplier
    local excluded = {}
    local target_key = deps.entity_tracking_key(context.target)
    if target_key then
      excluded[target_key] = true
    end
    local target_unit_number = safe_read(context.target, "unit_number")
    if target_unit_number then
      excluded[target_unit_number] = true
    end

    local upgrade_damage = 0
    for _ = 1, service.get_electric_arc_count(context.state) do
      local arc_target = combat.find_nearby_enemy(arc_surface, arc_from, context.force, descriptor.arc_radius, excluded)
      local arc_to = safe_read(arc_target, "position")
      if not arc_target then
        break
      end
      local arc_key = deps.entity_tracking_key(arc_target)
      if arc_key then
        excluded[arc_key] = true
      end
      local arc_unit_number = safe_read(arc_target, "unit_number")
      if arc_unit_number then
        excluded[arc_unit_number] = true
      end
      if combat.apply_tracked_runtime_damage(arc_target, amount, context.force, descriptor.arc_damage_type, context.turret) then
        upgrade_damage = upgrade_damage + amount
        if not combat.create_visual_entity(arc_surface, descriptor.arc_visual_entity, arc_to, arc_from, arc_to, context.force, 18) then
          combat.draw_trail(arc_surface, arc_from, arc_to, descriptor.arc_trail, descriptor.color, 2, 18, context.force)
        end
        combat.play_effect_sound(
          context.state,
          arc_surface,
          descriptor.sound,
          arc_from,
          descriptor.sound_key,
          descriptor.sound_cooldown,
          descriptor.sound_volume
        )
      end
    end

    return upgrade_damage
  end

  function element_handlers.explosive(context)
    local descriptor = context.descriptor
    context.flags.explosive = true
    local splashed = 0
    local splash_radius = descriptor.splash_radius
      + math.min(descriptor.splash_radius_bonus_cap, deps.get_element_rank(context.state, "explosive") * descriptor.splash_rank_radius)
    local splash_surface = safe_read(context.target, "surface")
    local splash_position = safe_read(context.target, "position")
    local entities = splash_surface
        and splash_position
        and splash_surface.find_entities_filtered({
          area = {
            { splash_position.x - splash_radius, splash_position.y - splash_radius },
            { splash_position.x + splash_radius, splash_position.y + splash_radius },
          },
        })
      or {}
    combat.create_short_effect(splash_surface, descriptor.short_effect, splash_position)

    local upgrade_damage = 0
    for _, nearby in pairs(entities) do
      if splashed >= descriptor.splash_targets then
        break
      end
      if nearby.valid and nearby ~= context.target and safe_read(nearby, "health") and nearby.force ~= context.force then
        local amount = context.base_damage * descriptor.splash_damage_multiplier * context.element_multiplier
        if combat.apply_tracked_runtime_damage(nearby, amount, context.force, descriptor.splash_damage_type, context.turret) then
          upgrade_damage = upgrade_damage + amount
          splashed = splashed + 1
        end
      end
    end

    return upgrade_damage
  end

  function element_handlers.toxic(context)
    local descriptor = context.descriptor
    context.flags.toxic = true
    combat.schedule_status_damage(
      context.turret,
      context.state,
      context.target,
      context.base_damage * descriptor.status_damage_multiplier * context.element_multiplier,
      descriptor.status_damage_type,
      descriptor.status_duration,
      descriptor.status_interval,
      descriptor.status_sprite,
      descriptor.color
    )
    combat.apply_slowdown_sticker(context.target)
    if
      not combat.create_visual_entity(
        context.effect_surface,
        descriptor.visual_entity,
        context.effect_position,
        context.effect_position,
        context.effect_position,
        context.force,
        descriptor.visual_duration
      )
    then
      combat.draw_effect_sprite(
        context.effect_surface,
        context.effect_position,
        descriptor.fallback_sprite,
        descriptor.fallback_sprite_scale,
        descriptor.fallback_sprite_ttl
      )
    end

    return 0
  end

  function service.apply_element_effects_to_target(turret, state, target, base_damage, force, source_position)
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

      local descriptor = element_effects[element_id]
      if descriptor and deps.element_is_powered(state, element_id) then
        local element_multiplier = service.get_element_effect_multiplier(state, element_id)
        local element_proc_chance = deps.apply_luck_to_chance(state, service.get_element_proc_chance(state, element_id))
        local effect_surface = safe_read(target, "surface")
        local effect_position = safe_read(target, "position")
        local visual_from = source_position or safe_read(turret, "position")
        service.draw_element_feedback(state, element_id, effect_surface, visual_from, effect_position, force)

        local handler = element_handlers[element_id]
        if handler and combat.chance_roll(element_proc_chance) then
          upgrade_damage = upgrade_damage
            + handler({
              turret = turret,
              state = state,
              target = target,
              base_damage = base_damage,
              force = force,
              source_position = source_position,
              descriptor = descriptor,
              element_multiplier = element_multiplier,
              effect_surface = effect_surface,
              effect_position = effect_position,
              flags = flags,
            })
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

  local combo_handlers = {}

  function combo_handlers.stormfire(context)
    local combo = context.combo
    local stormfire = context.base_damage * combo.damage_multiplier
    local effect_surface = safe_read(context.target, "surface")
    local effect_position = safe_read(context.target, "position")
    if combat.apply_tracked_runtime_damage(context.target, stormfire, context.force, combo.damage_type, context.turret) then
      if
        not combat.create_visual_entity(
          effect_surface,
          combo.visual_entity,
          effect_position,
          effect_position,
          effect_position,
          context.force
        )
      then
        combat.draw_effect_sprite(
          effect_surface,
          effect_position,
          combo.fallback_sprite,
          combo.fallback_sprite_scale,
          combo.fallback_sprite_ttl
        )
      end
      combat.play_effect_sound(
        context.state,
        effect_surface,
        combo.sound,
        effect_position,
        combo.sound_key,
        combo.sound_cooldown,
        combo.sound_volume
      )
      return stormfire
    end

    return 0
  end

  function combo_handlers.incendiary(context)
    local combo = context.combo
    local incendiary = context.base_damage * combo.damage_multiplier
    local effect_surface = safe_read(context.target, "surface")
    local effect_position = safe_read(context.target, "position")
    if combat.apply_tracked_runtime_damage(context.target, incendiary, context.force, combo.damage_type, context.turret) then
      if
        not combat.create_visual_entity(
          effect_surface,
          combo.visual_entity,
          effect_position,
          effect_position,
          effect_position,
          context.force
        )
      then
        combat.draw_effect_sprite(
          effect_surface,
          effect_position,
          combo.fallback_sprite,
          combo.fallback_sprite_scale,
          combo.fallback_sprite_ttl
        )
      end
      combat.create_short_effect(effect_surface, combo.short_effect, effect_position)
      combat.play_effect_sound(
        context.state,
        effect_surface,
        combo.sound,
        effect_position,
        combo.sound_key,
        combo.sound_cooldown,
        combo.sound_volume
      )
      return incendiary
    end

    return 0
  end

  function combo_handlers.shockburst(context)
    local combo = context.combo
    local shock_surface = safe_read(context.target, "surface")
    local shock_from = safe_read(context.target, "position")
    local shockburst_target = combat.find_nearby_enemy(shock_surface, shock_from, context.force, combo.radius, context.target)
    local shock_to = safe_read(shockburst_target, "position")
    local shockburst_damage = context.base_damage * combo.damage_multiplier
    if
      shockburst_target
      and combat.apply_tracked_runtime_damage(shockburst_target, shockburst_damage, context.force, combo.damage_type, context.turret)
    then
      if not combat.create_visual_entity(shock_surface, combo.visual_entity, shock_to, shock_from, shock_to, context.force, 18) then
        combat.draw_trail(shock_surface, shock_from, shock_to, combo.trail, combo.color, 2, 18, context.force)
      end
      combat.create_short_effect(shock_surface, combo.short_effect, shock_from)
      combat.play_effect_sound(
        context.state,
        shock_surface,
        combo.sound,
        shock_from,
        combo.sound_key,
        combo.sound_cooldown,
        combo.sound_volume
      )
      return shockburst_damage
    end

    return 0
  end

  function combo_handlers.choking(context)
    local combo = context.combo
    local effect_surface = safe_read(context.target, "surface")
    local effect_position = safe_read(context.target, "position")
    local choking = context.base_damage * combo.status_damage_multiplier
    if
      combat.schedule_status_damage(
        context.turret,
        context.state,
        context.target,
        choking,
        combo.status_damage_type,
        combo.status_duration,
        combo.status_interval,
        combo.status_sprite,
        combo.color
      )
    then
      combat.create_visual_entity(
        effect_surface,
        combo.visual_entity,
        effect_position,
        effect_position,
        effect_position,
        context.force,
        combo.visual_duration
      )
    end

    return 0
  end

  function combo_handlers.static_toxin(context)
    combat.apply_slowdown_sticker(context.target)
    return 0
  end

  function combo_handlers.dirty_blast(context)
    local combo = context.combo
    local splash_surface = safe_read(context.target, "surface")
    local splash_position = safe_read(context.target, "position")
    local entities = splash_surface
        and splash_position
        and splash_surface.find_entities_filtered({
          area = {
            { splash_position.x - combo.radius, splash_position.y - combo.radius },
            { splash_position.x + combo.radius, splash_position.y + combo.radius },
          },
        })
      or {}
    local spread = 0
    for _, nearby in pairs(entities) do
      if spread >= combo.spread_targets then
        break
      end
      if nearby.valid and nearby ~= context.target and safe_read(nearby, "health") and nearby.force ~= context.force then
        combat.schedule_status_damage(
          context.turret,
          context.state,
          nearby,
          context.base_damage * combo.status_damage_multiplier,
          combo.status_damage_type,
          combo.status_duration,
          combo.status_interval,
          combo.status_sprite,
          combo.color
        )
        combat.apply_slowdown_sticker(nearby)
        spread = spread + 1
      end
    end

    return 0
  end

  function service.apply_combo_effects_to_target(turret, state, target, base_damage, force, flags)
    if not target or not target.valid or not flags then
      return 0
    end

    for _, combo_id in ipairs(deps.descriptors.combo_order) do
      local combo = combo_effects[combo_id]
      if combat.combo_descriptor_is_active(state, flags, combo) then
        local handler = combo_handlers[combo_id]
        if handler then
          return handler({
            turret = turret,
            state = state,
            target = target,
            base_damage = base_damage,
            force = force,
            flags = flags,
            combo = combo,
          })
        end
      end
    end

    return 0
  end

  function service.apply_evolution_damage_effects(event, turret, state, base_damage)
    if not event.entity or not event.entity.valid or base_damage <= 0 then
      return
    end

    local force = turret.force
    local target = event.entity
    local target_xp_context = combat.get_entity_xp_context(target)
    local upgrade_damage = 0

    local damage_multiplier = deps.get_specialization_multiplier(state, "damage_multiplier")
    local bonus_damage = deps.get_base_rank(state, "damage") * 0.5 * damage_multiplier
    local shot_damage = base_damage + bonus_damage

    if bonus_damage > 0 and combat.apply_tracked_runtime_damage(target, bonus_damage, force, "physical", turret) then
      upgrade_damage = upgrade_damage + bonus_damage
    end

    local crit_chance = deps.get_crit_chance_fraction(state)
    if combat.chance_roll(crit_chance) then
      local crit_damage = shot_damage * deps.get_crit_damage_fraction(state)
      if combat.apply_tracked_runtime_damage(target, crit_damage, force, "physical", turret) then
        upgrade_damage = upgrade_damage + crit_damage
        combat.draw_crit_feedback(turret, target, force)
      end
    end

    if target.valid then
      local double_shot_chance = deps.get_double_shot_chance(state)
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
      local total_damage = base_damage + upgrade_damage
      combat.apply_shield_on_hit(turret, state, total_damage)
      local lifesteal_rate = deps.get_lifesteal_rate(state)
      if lifesteal_rate > 0 then
        combat.heal_turret(turret, total_damage * lifesteal_rate)
      end
      if upgrade_damage > 0 then
        deps.add_profile_damage(state, upgrade_damage, turret, target_xp_context)
        deps.sync_turret_progression(state)
      end
      return
    end

    local bounce_rank = deps.get_augment_rank(state, "bounce")
    local bounce_chance = deps.apply_luck_to_chance(state, bounce_rank * 0.05)
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

    local total_damage = base_damage + upgrade_damage
    combat.apply_shield_on_hit(turret, state, total_damage)
    local lifesteal_rate = deps.get_lifesteal_rate(state)
    if lifesteal_rate > 0 then
      combat.heal_turret(turret, total_damage * lifesteal_rate)
    end

    if upgrade_damage > 0 then
      deps.add_profile_damage(state, upgrade_damage, turret, target_xp_context)
      deps.sync_turret_progression(state)
    end
  end

  return service
end

return combat_dispatch
