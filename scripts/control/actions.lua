return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  function dev_create_core(player)
    local profile = create_blank_profile()
    if not insert_chip_item(player, profile) then
      local entity = get_remembered_turret(player) or player.character
      if entity and entity.valid then
        spill_chip_item(entity, profile)
      end
    end

    local entity = get_remembered_turret(player)
    if entity then
      refresh_open_turret(player, entity)
    end
  end

  function update_core_name_from_textfield(player, element)
    if not element or not element.valid or element.name ~= GUI.core_name then
      return
    end

    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    state.custom_name = sanitize_core_name(element.text)
    if state.custom_name ~= element.text then
      element.text = state.custom_name
    end
    update_name_render(entity, state)
  end

  function set_core_label_visibility(player, visible)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    state.show_name_label = visible == true
    update_name_render(entity, state)
    refresh_open_turret(player, entity)
  end

  function update_label_color_preview(player, state)
    local panel = get_gui_panel(player)
    if not panel or not state then
      return
    end

    local core_panel = find_gui_element(panel, GUI.core)
    if core_panel then
      core_panel.tags = {
        key = core_panel_key(player, state),
      }
    end

    local color = state.label_color or { 1, 0.86, 0.46 }
    local preview = find_gui_element(panel, GUI.core_color_preview)
    if preview then
      local preset = find_matching_label_color_preset(state)
      preview.caption = preset and preset.name or "Custom"
      set_style(preview, "font_color", color)
    end

    local values = {
      { name = GUI.core_color_r_value, slider = GUI.core_color_r, value = color[1] or 0 },
      { name = GUI.core_color_g_value, slider = GUI.core_color_g, value = color[2] or 0 },
      { name = GUI.core_color_b_value, slider = GUI.core_color_b, value = color[3] or 0 },
    }
    for _, entry in ipairs(values) do
      local raw_value = math.floor(math.max(0, math.min(1, entry.value)) * 255 + 0.5)
      local label = find_gui_element(panel, entry.name)
      if label then
        label.caption = tostring(raw_value)
      end
      local slider = find_gui_element(panel, entry.slider)
      if slider then
        pcall(function()
          slider.slider_value = raw_value
        end)
      end
    end
  end

  function set_label_color_channel(player, channel, value)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    local index = channel == "r" and 1 or channel == "g" and 2 or channel == "b" and 3 or nil
    if not index then
      return
    end

    state.label_color = state.label_color or { 1, 0.86, 0.46 }
    state.label_color[index] = math.max(0, math.min(255, tonumber(value) or 0)) / 255
    state.label_color_preset = "custom"
    update_name_render(entity, state)
    update_label_color_preview(player, state)
  end

  function allocate_base_upgrade(player, upgrade_id, amount)
    local upgrade = BASE_UPGRADE_BY_ID[upgrade_id]
    if not upgrade then
      return
    end
    local anchor = evolution_anchor_name("base", upgrade_id)
    amount = math.max(1, math.floor(tonumber(amount) or 1))

    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    local available = get_available_skill_points(state)
    if available < 1 then
      refresh_open_turret(player, entity, anchor)
      return
    end

    amount = math.min(amount, available)
    local evolution = ensure_evolution_state(state)
    local rank = evolution.base[upgrade_id] or 0
    if upgrade.max_rank and rank >= upgrade.max_rank then
      refresh_open_turret(player, entity, anchor)
      return
    end

    if upgrade.max_rank then
      amount = math.min(amount, math.max(0, upgrade.max_rank - rank))
    end
    if amount <= 0 then
      refresh_open_turret(player, entity, anchor)
      return
    end

    evolution.base[upgrade_id] = rank + amount
    if upgrade_id == "shield" then
      normalize_shield_state(state, false)
      update_shield_bar_render(entity, state, true)
    end
    sync_turret_progression(state)
    refresh_open_turret(player, entity, anchor)
  end

  function deallocate_base_upgrade(player, upgrade_id, amount)
    if not BASE_UPGRADE_BY_ID[upgrade_id] then
      return
    end
    local anchor = evolution_anchor_name("base", upgrade_id)
    amount = math.max(1, math.floor(tonumber(amount) or 1))

    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    local evolution = ensure_evolution_state(state)
    local rank = evolution.base[upgrade_id] or 0
    if rank <= 0 then
      refresh_open_turret(player, entity, anchor)
      return
    end

    local new_rank = math.max(0, rank - math.min(amount, rank))
    if new_rank == 0 then
      evolution.base[upgrade_id] = nil
    else
      evolution.base[upgrade_id] = new_rank
    end
    if upgrade_id == "shield" then
      normalize_shield_state(state, false)
      update_shield_bar_render(entity, state, true)
    end
    sync_turret_progression(state)
    refresh_open_turret(player, entity, anchor)
  end

  function reset_base_upgrades_state(state)
    ensure_evolution_state(state).base = {}
    state.shield = 0
    destroy_shield_bar_render(state)
    sync_turret_progression(state)
    combat.mark_turret_body_sync_pending(state)
  end

  function reset_specialization_state(state)
    local evolution = ensure_evolution_state(state)
    evolution.specialization = nil
    evolution.sub_specialization = nil
    combat.mark_turret_body_sync_pending(state)
  end

  function reset_augments_state(state)
    ensure_evolution_state(state).augments = {}
    sync_turret_progression(state)
    combat.mark_turret_body_sync_pending(state)
  end

  function reset_element_slot_state(entity, state, slot, spill)
    slot = math.floor(tonumber(slot) or 0)
    if slot ~= 1 and slot ~= 2 then
      return false
    end

    local evolution = ensure_evolution_state(state)
    if slot == 1 then
      evolution.elements = {}
      evolution.element_mastery = {}
      evolution.element_project = nil
    else
      local removed = evolution.elements[2]
      evolution.elements[2] = nil
      if evolution.element_project and evolution.element_project.slot == 2 then
        evolution.element_project = nil
      end
      if removed and evolution.elements[1] ~= removed then
        evolution.element_mastery[removed] = nil
      end
    end

    feeder.destroy(state, entity and entity.position or nil, spill == true)
    ensure_evolution_state(state)
    normalize_shield_state(state, false)
    update_shield_bar_render(entity, state, false)
    sync_turret_progression(state)
    if is_gun_turret(entity) then
      feeder.ensure(entity, state)
    end
    return true
  end

  function assign_element_rank(state, slot, element_id, rank)
    local evolution = ensure_evolution_state(state)
    local element = ELEMENT_BY_ID[element_id]
    if not element or (slot ~= 1 and slot ~= 2) then
      return false
    end

    local was_active_elsewhere = false
    for other_slot = 1, 2 do
      if other_slot ~= slot and evolution.elements[other_slot] == element_id then
        was_active_elsewhere = true
        break
      end
    end

    local previous_element = evolution.elements[slot]
    if previous_element and previous_element ~= element_id then
      local still_active = false
      for other_slot = 1, 2 do
        if other_slot ~= slot and evolution.elements[other_slot] == previous_element then
          still_active = true
          break
        end
      end
      if not still_active then
        evolution.element_mastery[previous_element] = {
          rank = 0,
          delivered = 0,
        }
      end
    end

    evolution.elements[slot] = element_id
    local mastery = evolution.element_mastery[element_id]
    if not mastery then
      mastery = {}
      evolution.element_mastery[element_id] = mastery
    end
    if was_active_elsewhere then
      mastery.rank = math.max(rank or ELEMENT_FREE_RANK, mastery.rank or 0, ELEMENT_FREE_RANK)
      mastery.delivered = math.max(0, math.floor(tonumber(mastery.delivered) or 0))
    else
      mastery.rank = math.max(rank or ELEMENT_FREE_RANK, ELEMENT_FREE_RANK)
      mastery.delivered = 0
    end
    mastery.fuel = nil
    mastery.burn_remaining = nil
    return true
  end

  function ensure_element_material_input(entity, state, element_id, slot)
    local element = ELEMENT_BY_ID[element_id]
    if not element then
      return false
    end

    local evolution = ensure_evolution_state(state)
    local mastery = evolution.element_mastery[element_id]
    if not mastery or (mastery.rank or 0) <= 0 then
      return false
    end

    if is_gun_turret(entity) then
      feeder.ensure(entity, state)
    end
    return true
  end

  function reset_base_upgrades(player)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    reset_base_upgrades_state(state)
    refresh_open_turret(player, entity, evolution_anchor_name("base", "damage"))
  end

  function choose_specialization(player, specialization_id)
    if not SPECIALIZATION_BY_ID[specialization_id] then
      return
    end
    local anchor = evolution_anchor_name("specialization", specialization_id)

    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    if not has_level(state, GATES.specialization) then
      refresh_open_turret(player, entity, anchor)
      return
    end

    local evolution = ensure_evolution_state(state)
    if evolution.specialization then
      refresh_open_turret(player, entity, anchor)
      return
    end

    evolution.specialization = specialization_id
    evolution.sub_specialization = nil
    combat.mark_turret_body_sync_pending(state)
    refresh_open_turret(player, entity, anchor)
  end

  function choose_sub_specialization(player, sub_specialization_id)
    local sub_specialization = SUB_SPECIALIZATION_BY_ID[sub_specialization_id]
    if not sub_specialization then
      return
    end
    local anchor = evolution_anchor_name("sub-specialization", sub_specialization_id)

    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    if not has_level(state, GATES.sub_specialization) then
      refresh_open_turret(player, entity, anchor)
      return
    end

    local evolution = ensure_evolution_state(state)
    if evolution.specialization ~= sub_specialization.parent or evolution.sub_specialization then
      refresh_open_turret(player, entity, anchor)
      return
    end

    evolution.sub_specialization = sub_specialization_id
    combat.mark_turret_body_sync_pending(state)
    refresh_open_turret(player, entity, anchor)
  end

  function reset_sub_specialization(player)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    ensure_evolution_state(state).sub_specialization = nil
    combat.mark_turret_body_sync_pending(state)
    refresh_open_turret(player, entity, evolution_anchor_name("sub-specialization", "choice"))
  end

  function reset_specialization(player)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    reset_specialization_state(state)
    refresh_open_turret(player, entity, evolution_anchor_name("specialization", "sniper"))
  end

  function allocate_augment(player, augment_id, amount)
    local augment = AUGMENT_BY_ID[augment_id]
    if not augment then
      return
    end
    local anchor = evolution_anchor_name("augment", augment_id)
    amount = math.max(1, math.floor(tonumber(amount) or 1))

    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    if not has_level(state, GATES.augments) then
      refresh_open_turret(player, entity, anchor)
      return
    end

    local available = get_available_augment_points(state)
    if available < 1 then
      refresh_open_turret(player, entity, anchor)
      return
    end

    local evolution = ensure_evolution_state(state)
    local rank = evolution.augments[augment_id] or 0
    if augment.max_rank and rank >= augment.max_rank then
      refresh_open_turret(player, entity, anchor)
      return
    end

    local remaining_to_max = augment.max_rank and math.max(0, augment.max_rank - rank) or amount
    amount = math.min(amount, available, remaining_to_max)
    evolution.augments[augment_id] = rank + amount
    sync_turret_progression(state)
    refresh_open_turret(player, entity, anchor)
  end

  function deallocate_augment(player, augment_id, amount)
    if not AUGMENT_BY_ID[augment_id] then
      return
    end
    local anchor = evolution_anchor_name("augment", augment_id)
    amount = math.max(1, math.floor(tonumber(amount) or 1))

    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    local evolution = ensure_evolution_state(state)
    local rank = evolution.augments[augment_id] or 0
    if rank <= 0 then
      refresh_open_turret(player, entity, anchor)
      return
    end

    local new_rank = math.max(0, rank - math.min(amount, rank))
    if new_rank == 0 then
      evolution.augments[augment_id] = nil
    else
      evolution.augments[augment_id] = new_rank
    end
    sync_turret_progression(state)
    refresh_open_turret(player, entity, anchor)
  end

  function reset_augments(player)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    reset_augments_state(state)
    refresh_open_turret(player, entity, evolution_anchor_name("augment", "bounce"))
  end

  function reset_evolution_state(entity, state, spill)
    if not state then
      return
    end

    local evolution = ensure_evolution_state(state)
    evolution.base = {}
    evolution.augments = {}
    evolution.specialization = nil
    evolution.sub_specialization = nil
    evolution.elements = {}
    evolution.element_mastery = {}
    evolution.element_project = nil

    feeder.destroy(state, entity and entity.position or nil, spill == true)
    ensure_evolution_state(state)
    sync_turret_progression(state)
    combat.mark_turret_body_sync_pending(state)
    if is_gun_turret(entity) then
      feeder.ensure(entity, state)
    end
  end

  function reset_evolution(player)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    reset_evolution_state(entity, state, true)
    refresh_open_turret(player, entity)
  end

  function reset_element_slot(player, slot)
    slot = math.floor(tonumber(slot) or 0)
    if slot ~= 1 and slot ~= 2 then
      return
    end

    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    local evolution = ensure_evolution_state(state)
    reset_element_slot_state(entity, state, slot, true)
    refresh_open_turret(
      player,
      entity,
      evolution_anchor_name("element", slot == 1 and "explosive" or (evolution.elements[1] or "explosive"), slot)
    )
  end

  function pick_element(player, slot, element_id)
    slot = math.floor(tonumber(slot) or 0)
    if (slot ~= 1 and slot ~= 2) or not ELEMENT_BY_ID[element_id] then
      return
    end
    local anchor = evolution_anchor_name("element", element_id, slot)

    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    if slot == 1 and not has_level(state, GATES.first_element) then
      refresh_open_turret(player, entity, anchor)
      return
    end

    if slot == 2 and (not has_level(state, GATES.second_element) or not ensure_evolution_state(state).elements[1]) then
      refresh_open_turret(player, entity, anchor)
      return
    end

    local evolution = ensure_evolution_state(state)
    if evolution.elements[slot] then
      refresh_open_turret(player, entity, anchor)
      return
    end

    assign_element_rank(state, slot, element_id, ELEMENT_FREE_RANK)
    ensure_evolution_state(state)
    feeder.ensure(entity, state)
    refresh_open_turret(player, entity, anchor)
  end

  function auto_feed_element_progress(state)
    local changed = false
    for _, element_id in ipairs(get_unique_active_element_ids(state)) do
      local requirement = get_element_remaining_requirement(state, element_id)
      local needed = requirement and math.max(0, requirement.remaining or 0) or 0
      if needed > 0 then
        local removed = feeder.remove_items(state, requirement.name, math.min(needed, FEEDER_CONSUME_LIMIT))
        if removed > 0 then
          add_element_material_progress(state, element_id, removed)
          changed = true
        end
      end
    end

    return changed
  end

  function complete_next_element_rank(state)
    for _, element_id in ipairs(get_unique_active_element_ids(state)) do
      local requirement = get_element_remaining_requirement(state, element_id)
      if requirement and requirement.remaining > 0 then
        add_element_material_progress(state, element_id, requirement.remaining)
        return true
      end
    end

    return false
  end

  function auto_feed_open_turret(state)
    if not state then
      return false
    end

    feeder.route_contents(state)
    local changed_progress = auto_feed_element_progress(state)
    feeder.route_contents(state)
    return changed_progress
  end

  function dev_complete_next_element_rank(player)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    if not complete_next_element_rank(state) then
      local evolution = ensure_evolution_state(state)
      for _, element_id in ipairs(evolution.elements or {}) do
        local element = ELEMENT_BY_ID[element_id]
        local mastery = element and evolution.element_mastery[element_id] or nil
        if mastery and (mastery.rank or 0) > 0 then
          mastery.rank = (mastery.rank or ELEMENT_FREE_RANK) + 1
          mastery.delivered = 0
          break
        end
      end
    end

    feeder.ensure(entity, state)
    refresh_open_turret(player, entity)
  end

  function add_dev_levels(player, levels)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    levels = math.max(1, math.floor(tonumber(levels) or 1))
    sync_turret_progression(state)
    local target_level = (state.level or 0) + levels
    local needed_total = 0
    for level = 0, target_level - 1 do
      needed_total = needed_total + xp_required(level)
    end

    state.dev_xp = (state.dev_xp or 0) + math.max(0, needed_total - (state.total_xp or 0))
    sync_turret_progression(state)
    refresh_open_turret(player, entity)
  end

  function dev_reset_core(player)
    local entity, state = get_open_turret_state(player)
    if not state then
      return
    end

    state.xp = 0
    state.total_xp = 0
    state.level = 0
    state.kills = 0
    state.kill_credit = 0
    state.damage = 0
    state.xp_damage = 0
    state.xp_kill_credit = 0
    state.dev_xp = 0
    state.skills = nil
    state.evolution = {}
    state.required_xp = nil
    state._progress_total_xp = nil
    state._progress_settings_key = nil
    feeder.destroy(state, entity.position, false)
    ensure_evolution_state(state)
    sync_turret_progression(state)
    combat.mark_turret_body_sync_pending(state)

    refresh_open_turret(player, entity)
  end
end
