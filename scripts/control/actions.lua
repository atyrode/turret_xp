local actions_module = {}

function actions_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local GATES = deps.GATES
  local BASE_UPGRADE_BY_ID = deps.BASE_UPGRADE_BY_ID
  local ELEMENT_BY_ID = deps.ELEMENT_BY_ID
  local SPECIALIZATION_BY_ID = deps.SPECIALIZATION_BY_ID
  local SUB_SPECIALIZATION_BY_ID = deps.SUB_SPECIALIZATION_BY_ID
  local AUGMENT_BY_ID = deps.AUGMENT_BY_ID
  local ELEMENT_FREE_RANK = deps.ELEMENT_FREE_RANK
  local FEEDER_CONSUME_LIMIT = deps.FEEDER_CONSUME_LIMIT
  local feeder = deps.feeder
  local combat = deps.combat
  local get_open_turret_state = deps.get_open_turret_state
  local refresh_open_turret = deps.refresh_open_turret
  local create_blank_profile = deps.create_blank_profile
  local insert_chip_item = deps.insert_chip_item
  local get_remembered_turret = deps.get_remembered_turret
  local spill_chip_item = deps.spill_chip_item
  local sanitize_core_name = deps.sanitize_core_name
  local update_name_render = deps.update_name_render
  local get_gui_panel = deps.get_gui_panel
  local find_gui_element = deps.find_gui_element
  local core_panel_key = deps.core_panel_key
  local find_matching_label_color_preset = deps.find_matching_label_color_preset
  local set_style = deps.set_style
  local evolution_anchor_name = deps.evolution_anchor_name
  local get_available_skill_points = deps.get_available_skill_points
  local get_available_augment_points = deps.get_available_augment_points
  local ensure_evolution_state = deps.ensure_evolution_state
  local normalize_shield_state = deps.normalize_shield_state
  local update_shield_bar_render = deps.update_shield_bar_render
  local destroy_shield_bar_render = deps.destroy_shield_bar_render
  local sync_turret_progression = deps.sync_turret_progression
  local is_gun_turret = deps.is_gun_turret
  local has_level = deps.has_level
  local get_unique_active_element_ids = deps.get_unique_active_element_ids
  local get_element_remaining_requirement = deps.get_element_remaining_requirement
  local add_element_material_progress = deps.add_element_material_progress
  local xp_required = deps.xp_required

  local function opened_turret_action(player, mutator)
    local entity, state = get_open_turret_state(player)
    if not state then
      return false
    end

    local anchor, should_refresh = mutator(entity, state)
    if should_refresh ~= false then
      refresh_open_turret(player, entity, anchor)
    end
    return true
  end

  local function dev_create_core(player)
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

  local function update_core_name_from_textfield(player, element)
    if not element or not element.valid or element.name ~= GUI.core_name then
      return
    end

    opened_turret_action(player, function(entity, state)
      state.custom_name = sanitize_core_name(element.text)
      if state.custom_name ~= element.text then
        element.text = state.custom_name
      end
      update_name_render(entity, state)
      return nil, false
    end)
  end

  local function set_core_label_visibility(player, visible)
    opened_turret_action(player, function(entity, state)
      state.show_name_label = visible == true
      update_name_render(entity, state)
    end)
  end

  local function update_label_color_preview(player, state)
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
    local swatch = find_gui_element(panel, GUI.core_color_swatch)
    if swatch then
      set_style(swatch, "color", color)
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

  local function set_label_color_channel(player, channel, value)
    local index = channel == "r" and 1 or channel == "g" and 2 or channel == "b" and 3 or nil
    if not index then
      return
    end

    opened_turret_action(player, function(entity, state)
      state.label_color = state.label_color or { 1, 0.86, 0.46 }
      state.label_color[index] = math.max(0, math.min(255, tonumber(value) or 0)) / 255
      state.label_color_preset = "custom"
      update_name_render(entity, state)
      update_label_color_preview(player, state)
      return nil, false
    end)
  end

  local function cycle_label_color(player)
    opened_turret_action(player, function(entity, state)
      local presets = COLOR.label_presets
      local next_index = 1
      local current_preset = find_matching_label_color_preset(state)
      for index, preset in ipairs(presets) do
        if current_preset and preset.id == current_preset.id then
          next_index = (index % #presets) + 1
          break
        end
      end
      state.label_color = {
        presets[next_index].color[1],
        presets[next_index].color[2],
        presets[next_index].color[3],
      }
      state.label_color_preset = presets[next_index].id
      update_name_render(entity, state)
      update_label_color_preview(player, state)
      return nil, false
    end)
  end

  local function allocate_base_upgrade(player, upgrade_id, amount)
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

  local function deallocate_base_upgrade(player, upgrade_id, amount)
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

  local function reset_base_upgrades_state(state)
    ensure_evolution_state(state).base = {}
    state.shield = 0
    destroy_shield_bar_render(state)
    sync_turret_progression(state)
    combat.mark_turret_body_sync_pending(state)
  end

  local function reset_specialization_state(state)
    local evolution = ensure_evolution_state(state)
    evolution.specialization = nil
    evolution.sub_specialization = nil
    combat.mark_turret_body_sync_pending(state)
  end

  local function reset_augments_state(state)
    ensure_evolution_state(state).augments = {}
    sync_turret_progression(state)
    combat.mark_turret_body_sync_pending(state)
  end

  local function reset_element_slot_state(entity, state, slot, spill)
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

  local function assign_element_rank(state, slot, element_id, rank)
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

  local function ensure_element_material_input(entity, state, element_id, slot)
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

  local function reset_base_upgrades(player)
    opened_turret_action(player, function(_, state)
      reset_base_upgrades_state(state)
      return evolution_anchor_name("base", "damage")
    end)
  end

  local function choose_specialization(player, specialization_id)
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

  local function choose_sub_specialization(player, sub_specialization_id)
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

  local function reset_sub_specialization(player)
    opened_turret_action(player, function(_, state)
      ensure_evolution_state(state).sub_specialization = nil
      combat.mark_turret_body_sync_pending(state)
      return evolution_anchor_name("sub-specialization", "choice")
    end)
  end

  local function reset_specialization(player)
    opened_turret_action(player, function(_, state)
      reset_specialization_state(state)
      return evolution_anchor_name("specialization", "sniper")
    end)
  end

  local function allocate_augment(player, augment_id, amount)
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

  local function deallocate_augment(player, augment_id, amount)
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

  local function reset_augments(player)
    opened_turret_action(player, function(_, state)
      reset_augments_state(state)
      return evolution_anchor_name("augment", "bounce")
    end)
  end

  local function reset_evolution_state(entity, state, spill)
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

  local function reset_evolution(player)
    opened_turret_action(player, function(entity, state)
      reset_evolution_state(entity, state, true)
    end)
  end

  local function reset_element_slot(player, slot)
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

  local function pick_element(player, slot, element_id)
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

  local function auto_feed_element_progress(state)
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

  local function complete_next_element_rank(state)
    for _, element_id in ipairs(get_unique_active_element_ids(state)) do
      local requirement = get_element_remaining_requirement(state, element_id)
      if requirement and requirement.remaining > 0 then
        add_element_material_progress(state, element_id, requirement.remaining)
        return true
      end
    end

    return false
  end

  local function auto_feed_open_turret(state)
    if not state then
      return false
    end

    feeder.route_contents(state)
    local changed_progress = auto_feed_element_progress(state)
    feeder.route_contents(state)
    return changed_progress
  end

  local function dev_complete_next_element_rank(player)
    opened_turret_action(player, function(entity, state)
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
    end)
  end

  local function add_dev_levels(player, levels)
    opened_turret_action(player, function(_, state)
      levels = math.floor(tonumber(levels) or 1)
      if levels == 0 then
        return
      end

      sync_turret_progression(state)

      local target_level = math.max(0, (state.level or 0) + levels)
      local needed_total = 0
      for level = 0, target_level - 1 do
        needed_total = needed_total + xp_required(level)
      end

      if levels > 0 then
        state.dev_xp = (state.dev_xp or 0) + math.max(0, needed_total - (state.total_xp or 0))
      else
        local combat_xp = math.max(0, (state.total_xp or 0) - (state.dev_xp or 0))
        state.dev_xp = math.max(0, needed_total - combat_xp)
      end
      sync_turret_progression(state)
    end)
  end

  local function dev_reset_core(player)
    opened_turret_action(player, function(entity, state)
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
    end)
  end

  return {
    opened_turret_action = opened_turret_action,
    dev_create_core = dev_create_core,
    update_core_name_from_textfield = update_core_name_from_textfield,
    set_core_label_visibility = set_core_label_visibility,
    update_label_color_preview = update_label_color_preview,
    set_label_color_channel = set_label_color_channel,
    cycle_label_color = cycle_label_color,
    allocate_base_upgrade = allocate_base_upgrade,
    deallocate_base_upgrade = deallocate_base_upgrade,
    reset_base_upgrades_state = reset_base_upgrades_state,
    reset_specialization_state = reset_specialization_state,
    reset_augments_state = reset_augments_state,
    reset_element_slot_state = reset_element_slot_state,
    assign_element_rank = assign_element_rank,
    ensure_element_material_input = ensure_element_material_input,
    reset_base_upgrades = reset_base_upgrades,
    choose_specialization = choose_specialization,
    choose_sub_specialization = choose_sub_specialization,
    reset_sub_specialization = reset_sub_specialization,
    reset_specialization = reset_specialization,
    allocate_augment = allocate_augment,
    deallocate_augment = deallocate_augment,
    reset_augments = reset_augments,
    reset_evolution_state = reset_evolution_state,
    reset_evolution = reset_evolution,
    reset_element_slot = reset_element_slot,
    pick_element = pick_element,
    auto_feed_element_progress = auto_feed_element_progress,
    complete_next_element_rank = complete_next_element_rank,
    auto_feed_open_turret = auto_feed_open_turret,
    dev_complete_next_element_rank = dev_complete_next_element_rank,
    add_dev_levels = add_dev_levels,
    dev_reset_core = dev_reset_core,
  }
end

return actions_module
