return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  function turret_xp_test_inventory_counts(inventory)
    local counts = {}
    if not inventory or not inventory.valid then
      return counts
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read then
        counts[stack.name] = (counts[stack.name] or 0) + stack.count
      end
    end

    return counts
  end

  function turret_xp_test_table_count(values)
    local count = 0
    for _, _ in pairs(values or {}) do
      count = count + 1
    end
    return count
  end

  function turret_xp_test_inserter_summary(inserter)
    if not inserter or not inserter.valid then
      return {
        valid = false,
      }
    end

    ensure_storage()
    local unit_number = safe_read(inserter, "unit_number")
    local count = feeder.get_inserter_filter_slot_count(inserter)
    local filters = {}
    for index = 1, count do
      local ok, filter = pcall(function()
        return inserter.get_filter(index)
      end)
      if ok then
        filters[index] = feeder.filter_name(filter)
      end
    end

    local drop_target = safe_read(inserter, "drop_target")
    local pickup_position = safe_read(inserter, "pickup_position")
    local drop_position = safe_read(inserter, "drop_position")
    return {
      valid = true,
      unit_number = unit_number,
      filter_count = count,
      filters = filters,
      managed = unit_number and storage.turret_xp.managed_inserters[unit_number] ~= nil or false,
      drop_target_name = drop_target and drop_target.valid and drop_target.name or nil,
      drop_target_unit_number = drop_target and drop_target.valid and drop_target.unit_number or nil,
      pickup_position = pickup_position and { x = pickup_position.x, y = pickup_position.y } or nil,
      drop_position = drop_position and { x = drop_position.x, y = drop_position.y } or nil,
    }
  end

  function turret_xp_test_as_array(value)
    if not value then
      return {}
    end

    if value[1] ~= nil then
      return value
    end

    return { value }
  end

  function turret_xp_test_collect_projectile_ranges_from_ammo_type(ammo_type)
    local ranges = {}
    for _, item in pairs(turret_xp_test_as_array(ammo_type and ammo_type.action)) do
      for _, delivery in pairs(turret_xp_test_as_array(item and item.action_delivery)) do
        if delivery.type == "projectile" then
          local max_range = tonumber(delivery.max_range) or 1000
          local range_deviation = math.max(0, tonumber(delivery.range_deviation) or 0)
          ranges[#ranges + 1] = {
            max_range = max_range,
            range_deviation = range_deviation,
            minimum_effective_range = max_range * math.max(0.1, 1 - (range_deviation / 2)),
          }
        end
      end
    end
    return ranges
  end

  function turret_xp_test_max_generated_turret_range()
    local max_range = 0
    for name, prototype in pairs(prototypes.entity) do
      local attack_parameters = prototype.attack_parameters
      local range = attack_parameters and attack_parameters.range or nil
      if
        type(range) == "number"
        and (name == BASE_TURRET_NAME or string.sub(name, 1, #SPECIALIZED_TURRET_PREFIX) == SPECIALIZED_TURRET_PREFIX)
        and range > max_range
      then
        max_range = range
      end
    end
    return max_range
  end

  function turret_xp_test_has_prefix(name, prefix)
    return type(name) == "string" and type(prefix) == "string" and string.sub(name, 1, #prefix) == prefix
  end

  function turret_xp_test_prototype_budget()
    local counts = {
      hidden_turret_variants = 0,
      bound_preview_items = 0,
      bound_preview_placeholders = 0,
      label_panels = 0,
      tracked_hidden_variant_total = 0,
    }

    for name, _ in pairs(prototypes.entity) do
      if turret_xp_test_has_prefix(name, SPECIALIZED_TURRET_PREFIX) then
        counts.hidden_turret_variants = counts.hidden_turret_variants + 1
      elseif turret_xp_test_has_prefix(name, BOUND_TURRET_PLACEHOLDER_VARIANT_PREFIX) then
        counts.bound_preview_placeholders = counts.bound_preview_placeholders + 1
      elseif turret_xp_test_has_prefix(name, LABEL_PANEL_PREFIX) then
        counts.label_panels = counts.label_panels + 1
      end
    end

    for name, _ in pairs(prototypes.item) do
      if name ~= BOUND_TURRET_NAME and DOMAIN.is_bound_turret_item_name(name) then
        counts.bound_preview_items = counts.bound_preview_items + 1
      end
    end

    counts.tracked_hidden_variant_total = counts.hidden_turret_variants
      + counts.bound_preview_items
      + counts.bound_preview_placeholders
      + counts.label_panels

    return counts
  end

  function turret_xp_test_state_summary(entity)
    local state = is_gun_turret(entity) and get_turret_state(entity) or nil
    if not state then
      return nil
    end

    local evolution = ensure_evolution_state(state)
    local feeder_entity = state.feeder
    local feeder_inventory = feeder.get_inventory(feeder_entity)
    local current_entity = is_gun_turret(state.entity) and state.entity or entity
    local attack_parameters = get_attack_parameters(current_entity)
    local turret_inventory = feeder.get_entity_inventory(current_entity, defines.inventory.turret_ammo)

    return {
      chip_id = state.chip_id,
      entity_name = current_entity and current_entity.name or nil,
      unit_number = current_entity and current_entity.unit_number or nil,
      position = current_entity and { x = current_entity.position.x, y = current_entity.position.y } or nil,
      custom_name = state.custom_name,
      show_name_label = state.show_name_label == true,
      show_label_level = state.show_label_level ~= false,
      label_color_preset = state.label_color_preset,
      label_color = copy_serializable(state.label_color or {}),
      label_entity_valid = state.label_entity and state.label_entity.valid or false,
      name_render_valid = state.name_render and state.name_render.valid or false,
      bound_turret = state.bound_turret == true,
      last_ammo = copy_serializable(state.last_ammo),
      ammo_regen_progress = state.ammo_regen_progress or 0,
      derived = {
        repair_per_second = get_repair_per_second(state, current_entity),
        ammo_recovery_per_minute = get_ammo_recovery_per_minute(state),
        lifesteal_rate = get_lifesteal_rate(state),
        crit_damage_fraction = get_crit_damage_fraction(state),
        crit_chance_fraction = get_crit_chance_fraction(state),
        double_shot_chance = get_double_shot_chance(state),
        damage_resistance_fraction = get_damage_resistance_fraction(state),
      },
      xp = state.xp or 0,
      total_xp = state.total_xp or 0,
      level = state.level or 0,
      kills = state.kills or 0,
      kill_credit = state.kill_credit or 0,
      damage = state.damage or 0,
      xp_damage = state.xp_damage or 0,
      xp_kill_credit = state.xp_kill_credit or 0,
      dev_xp = state.dev_xp or 0,
      required_xp = state.required_xp or 0,
      attack_range = attack_parameters and attack_parameters.range or nil,
      attack_cooldown = attack_parameters and attack_parameters.cooldown or nil,
      attack_damage_modifier = attack_parameters and (attack_parameters.damage_modifier or 1) or nil,
      max_health = safe_read(current_entity, "max_health"),
      turret_ammo = turret_xp_test_inventory_counts(turret_inventory),
      evolution = {
        base = copy_serializable(evolution.base or {}),
        augments = copy_serializable(evolution.augments or {}),
        elements = {
          evolution.elements and evolution.elements[1] or nil,
          evolution.elements and evolution.elements[2] or nil,
        },
        unique_elements = get_unique_active_element_ids(state),
        element_mastery = copy_serializable(evolution.element_mastery or {}),
        specialization = evolution.specialization,
        sub_specialization = evolution.sub_specialization,
        element_project = copy_serializable(evolution.element_project),
        available_core_points = get_available_skill_points(state),
        available_augment_points = get_available_augment_points(state),
      },
      feeder = {
        valid = feeder_entity and feeder_entity.valid or false,
        unit_number = feeder_entity and feeder_entity.valid and feeder_entity.unit_number or nil,
        counts = turret_xp_test_inventory_counts(feeder_inventory),
        allowed_items = feeder.allowed_item_names(state),
        needs_input = feeder.needs_input(state),
        should_exist = feeder.should_exist(state),
      },
      status_effect_count = #(storage.turret_xp.status_effects or {}),
    }
  end

  function turret_xp_test_profile_summary(profile)
    profile = normalize_profile(copy_serializable(profile or {}))
    local evolution = ensure_evolution_state(profile)

    return {
      level = profile.level or 0,
      kills = profile.kills or 0,
      damage = profile.damage or 0,
      skills = copy_serializable(profile.skills or {}),
      evolution = {
        base = copy_serializable(evolution.base or {}),
        augments = copy_serializable(evolution.augments or {}),
        elements = {
          evolution.elements and evolution.elements[1] or nil,
          evolution.elements and evolution.elements[2] or nil,
        },
        unique_elements = get_unique_active_element_ids(profile),
        element_mastery = copy_serializable(evolution.element_mastery or {}),
        specialization = evolution.specialization,
        sub_specialization = evolution.sub_specialization,
        element_project = copy_serializable(evolution.element_project),
        migrated_legacy_skills = evolution.migrated_legacy_skills == true,
      },
    }
  end

  function turret_xp_test_set_profile_fields(profile, fields)
    if type(fields) ~= "table" then
      return profile
    end

    for _, key in ipairs({
      "chip_id",
      "chip_quality",
      "custom_name",
      "show_name_label",
      "show_label_level",
      "label_color",
      "label_color_preset",
      "bound_turret",
      "xp_damage",
      "xp_kill_credit",
      "dev_xp",
      "kills",
      "kill_credit",
      "damage",
    }) do
      if fields[key] ~= nil then
        profile[key] = copy_serializable(fields[key])
      end
    end

    if fields.level then
      local target_level = math.max(0, math.floor(tonumber(fields.level) or 0))
      local total = 0
      for level = 0, target_level - 1 do
        total = total + xp_required(level)
      end
      profile.dev_xp = total
    end

    return normalize_profile(profile)
  end

  remote.add_interface("turret_xp_test", {
    install_core = function(entity, fields)
      local profile = turret_xp_test_set_profile_fields(create_blank_profile(), fields)
      local installed = install_profile_on_turret(entity, profile)
      if installed then
        local synced = combat.sync_turret_body_when_idle(entity, installed)
        return turret_xp_test_state_summary(synced or entity)
      end

      return nil
    end,

    get_state = function(entity)
      return turret_xp_test_state_summary(entity)
    end,

    selection_overlay = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local text = build_selection_overlay_text(entity, state)
      local result = {
        no_player = true,
        updated = false,
        render_valid = false,
        time_to_live = 0,
        title = text and text[3] or nil,
      }
      local player = game.players[1]
      if not player then
        return result
      end

      local updated = update_selection_overlay(player, entity, state)
      ensure_storage()
      local entry = storage.turret_xp.selection_overlays[player.index]
      result.no_player = false
      result.updated = updated == true
      result.render_valid = entry and entry.render and entry.render.valid or false
      result.time_to_live = entry and entry.render and entry.render.valid and entry.render.time_to_live or 0
      return result
    end,

    record_damage_contribution = function(target, turret, damage, final_health)
      record_damage_contribution({
        entity = target,
        final_health = final_health,
      }, turret, damage or 0)
      ensure_storage()
      return {
        target_entry_count = turret_xp_test_table_count(storage.turret_xp.targets),
      }
    end,

    award_recorded_kill_credit = function(target, killing_turret)
      local credited_turret = award_kill_credit(target, killing_turret)
      award_visible_kill(credited_turret)
      ensure_storage()
      return {
        credited_unit_number = credited_turret and credited_turret.valid and credited_turret.unit_number or nil,
        target_entry_count = turret_xp_test_table_count(storage.turret_xp.targets),
      }
    end,

    layout = function()
      return copy_serializable(LAYOUT)
    end,

    gui_support_samples = function()
      return {
        percent = format_percent(0.125, 1),
        color = color_to_rich_string(COLOR.bonus),
        rich_number = rich_number("+5"),
        rich_stat = rich_stat_text("Damage +5 x1.2"),
      }
    end,

    compat_samples = function(entity)
      local turret_inventory = feeder.get_entity_inventory(entity, defines.inventory.turret_ammo)
      return {
        nil_read_fallback = safe_read(nil, "missing", "fallback"),
        entity_quality = quality_name_from_entity(entity, "normal"),
        inventory_valid = turret_inventory and turret_inventory.valid or false,
        platform_inventory_present = get_platform_hub_inventory(entity) ~= nil,
        base_prototype_exists = combat.entity_prototype_exists(BASE_TURRET_NAME),
        missing_prototype_exists = combat.entity_prototype_exists("turret-xp-missing-prototype") == true,
        diagnostics_enabled = compat_diagnostics_enabled(),
      }
    end,

    combat_budget_samples = function(surface)
      surface = surface or game.surfaces[1]
      combat.reset_effect_budget()
      local limits = combat.get_effect_budget_snapshot().limits
      local accepted_lines = 0
      for index = 1, limits.render_lines_per_surface_tick + 2 do
        if combat.draw_attack_line(surface, { x = -40, y = index * 0.05 }, { x = -39, y = index * 0.05 }, { 1, 1, 1 }, 1, 1) then
          accepted_lines = accepted_lines + 1
        end
      end

      local accepted_status_ticks = 0
      for _ = 1, limits.status_effect_ticks_per_tick + 2 do
        if combat.reserve_effect_budget("status_effect_ticks", surface) then
          accepted_status_ticks = accepted_status_ticks + 1
        end
      end

      local snapshot = combat.get_effect_budget_snapshot()
      combat.reset_effect_budget()
      return {
        descriptors = combat.get_effect_descriptor_snapshot(),
        limits = limits,
        accepted_lines = accepted_lines,
        accepted_status_ticks = accepted_status_ticks,
        skipped = snapshot.skipped or {},
      }
    end,

    prototype_budget = function()
      return turret_xp_test_prototype_budget()
    end,

    apply_passive = function(ticks)
      local count = math.max(1, math.floor(tonumber(ticks) or 1))
      for _ = 1, count do
        apply_passive_evolution_effects()
      end
      return true
    end,

    placement_prototypes = function()
      local gun_item = prototypes.item[BASE_TURRET_NAME]
      local bound_item = prototypes.item[BOUND_TURRET_NAME]
      local placeholder_entity = prototypes.entity[BOUND_TURRET_PLACEHOLDER_NAME]
      local preview_name = DOMAIN.bound_turret_item_name(get_bound_turret_variant_id("sniper", 3))
      local preview_item = prototypes.item[preview_name]
      local preview_entity = preview_item and preview_item.place_result or nil
      local base_attack_parameters = placeholder_entity and placeholder_entity.attack_parameters or nil
      local preview_attack_parameters = preview_entity and preview_entity.attack_parameters or nil
      local range_3_body_name = get_specialized_turret_name(nil, 3, 0)
      local health_2_body_name = get_specialized_turret_name(nil, 0, 2)
      local sniper_deadeye_body_name = get_specialized_turret_name("sniper", 0, 0, "sniper_deadeye")
      local sniper_overwatch_range_3_body_name = get_specialized_turret_name("sniper", 3, 0, "sniper_overwatch")
      local invalid_sub_body_name = get_specialized_turret_name("machine_gun", 0, 0, "sniper_deadeye")
      local sniper_deadeye_bound_item_name = DOMAIN.bound_turret_item_name(get_bound_turret_variant_id("sniper", 0, "sniper_deadeye"))
      local sniper_deadeye_bound_item = prototypes.item[sniper_deadeye_bound_item_name]
      return {
        gun_turret_place_result = gun_item and gun_item.place_result and gun_item.place_result.name or nil,
        bound_turret_place_result = bound_item and bound_item.place_result and bound_item.place_result.name or nil,
        placeholder_exists = placeholder_entity ~= nil,
        base_bound_preview_range = base_attack_parameters and base_attack_parameters.range or nil,
        sniper_range_3_bound_item = preview_item and preview_item.name or nil,
        sniper_range_3_bound_place_result = preview_item and preview_item.place_result and preview_item.place_result.name or nil,
        sniper_range_3_bound_preview_range = preview_attack_parameters and preview_attack_parameters.range or nil,
        range_3_body_name = range_3_body_name,
        range_3_body_exists = prototypes.entity[range_3_body_name] ~= nil,
        health_2_body_name = health_2_body_name,
        health_2_body_exists = prototypes.entity[health_2_body_name] ~= nil,
        sniper_deadeye_body_name = sniper_deadeye_body_name,
        sniper_deadeye_body_exists = prototypes.entity[sniper_deadeye_body_name] ~= nil,
        sniper_overwatch_range_3_body_name = sniper_overwatch_range_3_body_name,
        sniper_overwatch_range_3_body_exists = prototypes.entity[sniper_overwatch_range_3_body_name] ~= nil,
        invalid_sub_body_name = invalid_sub_body_name,
        sniper_deadeye_bound_item = sniper_deadeye_bound_item and sniper_deadeye_bound_item.name or nil,
        sniper_deadeye_bound_place_result = sniper_deadeye_bound_item
            and sniper_deadeye_bound_item.place_result
            and sniper_deadeye_bound_item.place_result.name
          or nil,
      }
    end,

    ammo_range_compat = function(ammo_name)
      local ammo = prototypes.item[ammo_name]
      if not ammo then
        return nil
      end

      local player_ammo_type = ammo.get_ammo_type("player")
      local turret_ammo_type = ammo.get_ammo_type("turret")
      return {
        max_turret_xp_range = turret_xp_test_max_generated_turret_range(),
        player = turret_xp_test_collect_projectile_ranges_from_ammo_type(player_ammo_type),
        turret = turret_xp_test_collect_projectile_ranges_from_ammo_type(turret_ammo_type),
      }
    end,

    set_profile = function(entity, fields)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      turret_xp_test_set_profile_fields(state, fields)
      update_name_render(entity, state)
      local synced = combat.sync_turret_body_when_idle(entity, state)
      return turret_xp_test_state_summary(synced or entity)
    end,

    normalize_profile_snapshot = function(fields)
      return turret_xp_test_profile_summary(fields)
    end,

    deserialize_profile_snapshot = function(data)
      return turret_xp_test_profile_summary(deserialize_profile(data))
    end,

    set_evolution = function(entity, fields)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local evolution = ensure_evolution_state(state)
      fields = type(fields) == "table" and fields or {}
      if fields.base then
        for key, value in pairs(fields.base) do
          evolution.base[key] = value
        end
      end
      if fields.augments then
        for key, value in pairs(fields.augments) do
          evolution.augments[key] = value
        end
      end
      if fields.elements then
        evolution.elements = {
          fields.elements[1],
          fields.elements[2],
        }
      end
      if fields.element_mastery then
        evolution.element_mastery = copy_serializable(fields.element_mastery)
      end
      if fields.specialization ~= nil then
        evolution.specialization = fields.specialization
      end
      if fields.sub_specialization ~= nil then
        evolution.sub_specialization = fields.sub_specialization
      end
      if fields.element_project ~= nil then
        evolution.element_project = copy_serializable(fields.element_project)
      end

      ensure_evolution_state(state)
      sync_turret_progression(state)
      local synced = combat.sync_turret_body_when_idle(entity, state)
      feeder.ensure(synced or entity, state)
      return turret_xp_test_state_summary(synced or entity)
    end,

    reset_evolution_section = function(entity, section, value)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      if section == "base" then
        reset_base_upgrades_state(state)
      elseif section == "augments" then
        reset_augments_state(state)
      elseif section == "specialization" then
        reset_specialization_state(state)
      elseif section == "sub-specialization" then
        ensure_evolution_state(state).sub_specialization = nil
        combat.mark_turret_body_sync_pending(state)
      elseif section == "element-slot" then
        reset_element_slot_state(entity, state, value, false)
      else
        return turret_xp_test_state_summary(entity)
      end

      ensure_evolution_state(state)
      local synced = combat.sync_turret_body_when_idle(entity, state)
      feeder.ensure(synced or entity, state)
      return turret_xp_test_state_summary(synced or entity)
    end,

    reset_evolution = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      reset_evolution_state(entity, state, false)
      ensure_evolution_state(state)
      local synced = combat.sync_turret_body_when_idle(entity, state)
      feeder.ensure(synced or entity, state)
      return turret_xp_test_state_summary(synced or entity)
    end,

    pick_element = function(entity, slot, element_id)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      local element = ELEMENT_BY_ID[element_id]
      if not state or not element then
        return nil
      end

      local evolution = ensure_evolution_state(state)
      slot = math.floor(tonumber(slot) or 1)
      if slot ~= 1 and slot ~= 2 then
        slot = 1
      end
      if not evolution.elements[slot] then
        assign_element_rank(state, slot, element_id, ELEMENT_FREE_RANK)
      elseif evolution.elements[slot] == element_id then
        ensure_element_material_input(entity, state, element_id, slot)
      end
      feeder.ensure(entity, state)
      return turret_xp_test_state_summary(entity)
    end,

    insert_feeder = function(entity, stack)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local feeder_entity = feeder.ensure(entity, state)
      local inventory = feeder.get_inventory(feeder_entity)
      local inserted = 0
      if inventory and stack then
        inserted = inventory.insert(stack)
      end

      local summary = turret_xp_test_state_summary(entity)
      summary.inserted = inserted
      return summary
    end,

    route_feeder = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      auto_feed_open_turret(state)
      return turret_xp_test_state_summary(state.entity or entity)
    end,

    schedule_status_damage = function(entity, target, amount, damage_type, duration_ticks, interval_ticks)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state or not target or not target.valid then
        return nil
      end

      combat.schedule_status_damage(
        entity,
        state,
        target,
        amount,
        damage_type,
        duration_ticks,
        interval_ticks,
        "virtual-signal/signal-skull",
        { 0.42, 0.92, 0.28 }
      )
      return turret_xp_test_state_summary(entity)
    end,

    manage_inserter_filters = function(entity, inserter)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state or not inserter or not inserter.valid then
        return nil
      end

      local applied = feeder.apply_inserter_filters(inserter, state)
      local count = feeder.get_inserter_filter_slot_count(inserter)
      local filters = {}
      for index = 1, count do
        local ok, filter = pcall(function()
          return inserter.get_filter(index)
        end)
        if ok then
          filters[index] = feeder.filter_name(filter)
        end
      end

      return {
        applied = applied,
        filters = filters,
      }
    end,

    update_feeder_inserters = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      feeder.ensure(entity, state)
      feeder.update_nearby_inserters(entity, state)
      return turret_xp_test_state_summary(entity)
    end,

    inserter_state = function(inserter)
      return turret_xp_test_inserter_summary(inserter)
    end,

    restore_inserter_filters = function(inserter)
      if not inserter or not inserter.valid then
        return nil
      end

      feeder.restore_inserter_filters(inserter)
      return turret_xp_test_inserter_summary(inserter)
    end,

    feeder_inserter_probe = function(entity, inserter)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state or not inserter or not inserter.valid then
        return nil
      end

      local allowed_items = feeder.get_allowed_items(state)
      local filter_count = feeder.get_inserter_filter_slot_count(inserter)
      local has_filter, has_allowed_filter = feeder.inserter_filters_match_allowed(inserter, allowed_items, filter_count)
      return {
        points_at_turret = feeder.inserter_points_at_turret(inserter, entity, state.feeder),
        has_source_item = feeder.inserter_source_has_allowed_item(inserter, allowed_items),
        has_filter = has_filter,
        has_allowed_filter = has_allowed_filter,
        allowed_items = feeder.allowed_item_names(state),
      }
    end,

    feeder_owner = function(unit_number)
      ensure_storage()
      return storage.turret_xp.feeders[unit_number]
    end,

    set_bound = function(entity, bound)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      state.bound_turret = bound == true
      return turret_xp_test_state_summary(entity)
    end,

    mine_bound_turret = function(entity, buffer)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return {
          converted = false,
          counts = turret_xp_test_inventory_counts(buffer),
        }
      end

      if state.bound_turret then
        remember_bound_turret_mining(entity, state, snapshot_turret_item_state(entity))
      end

      return {
        converted = finish_bound_turret_mining(entity, buffer),
        counts = turret_xp_test_inventory_counts(buffer),
      }
    end,

    mine_bound_turret_with_vanilla_returns = function(entity, buffer, external_inventory)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return {
          converted = false,
          counts = turret_xp_test_inventory_counts(buffer),
          external_counts = turret_xp_test_inventory_counts(external_inventory),
          post_pre_mine_ammo = {},
        }
      end

      if state.bound_turret then
        remember_bound_turret_mining(entity, state, snapshot_turret_item_state(entity))
      end

      local post_pre_mine_snapshot = snapshot_turret_item_state(entity)
      if buffer and buffer.valid then
        buffer.insert({
          name = BASE_TURRET_NAME,
          count = 1,
        })
      end
      if external_inventory and external_inventory.valid then
        for _, ammo in ipairs(post_pre_mine_snapshot.ammo or {}) do
          external_inventory.insert({
            name = ammo.name,
            count = ammo.count,
            quality = ammo.quality or "normal",
          })
        end
      end

      return {
        converted = finish_bound_turret_mining(entity, buffer),
        counts = turret_xp_test_inventory_counts(buffer),
        external_counts = turret_xp_test_inventory_counts(external_inventory),
        post_pre_mine_ammo = copy_serializable(post_pre_mine_snapshot.ammo or {}),
      }
    end,

    make_chip_stack = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      return state and make_chip_item_stack(state) or nil
    end,

    make_bound_turret_stack = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      return make_bound_turret_item_stack(state, snapshot_turret_item_state(entity))
    end,

    make_legacy_bound_turret_stack = function(fields)
      local profile = turret_xp_test_set_profile_fields(create_blank_profile(), fields or {})
      profile.bound_turret = true
      local serialized = serialize_profile(profile)
      return {
        name = BOUND_TURRET_NAME,
        count = 1,
        quality = serialized.chip_quality or "normal",
        tags = {
          [PROFILE_TAG] = serialized,
        },
        custom_description = bound_turret_description(serialized),
      }
    end,

    read_bound_turret_stack = function(stack)
      local profile, turret_snapshot = read_bound_turret_stack(stack)
      if not profile then
        return nil
      end

      return {
        profile = serialize_profile(profile),
        turret = copy_serializable(turret_snapshot or {}),
      }
    end,

    install_bound_turret_stack = function(entity, stack)
      local profile, turret_snapshot = read_bound_turret_stack(stack)
      if not profile then
        return nil
      end

      entity = replace_bound_turret_placeholder(entity, turret_snapshot)
      if not is_gun_turret(entity) then
        return nil
      end

      local installed = install_profile_on_turret(entity, profile)
      if not installed then
        return nil
      end

      local synced = combat.sync_turret_body_when_idle(entity, installed)
      restore_turret_item_state(synced or entity, turret_snapshot)
      return turret_xp_test_state_summary(synced or entity)
    end,

    cleanup_entity = function(entity)
      if is_gun_turret(entity) then
        local state = get_turret_state(entity)
        destroy_name_render(state)
        feeder.destroy(state, entity.position, true)
        remove_turret_state(entity, true)
      end
    end,
  })
end
