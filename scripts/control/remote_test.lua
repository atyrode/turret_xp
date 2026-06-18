local profile_labels_module = require("scripts.control.profile_labels")

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
    local retired_label_panel_prefix = "turret-xp-label-panel-"
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
      elseif turret_xp_test_has_prefix(name, retired_label_panel_prefix) then
        counts.label_panels = counts.label_panels + 1
      end
    end

    for name, _ in pairs(prototypes.item) do
      if name ~= BOUND_TURRET_NAME and DOMAIN.is_bound_turret_item_name(name) then
        counts.bound_preview_items = counts.bound_preview_items + 1
      end
    end

    counts.tracked_hidden_variant_total = counts.hidden_turret_variants + counts.bound_preview_items + counts.bound_preview_placeholders

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
    local shield, shield_capacity = normalize_shield_state(state, true)
    local shield_bar_segments = state.shield_bar and state.shield_bar.segments or nil
    local shield_bar_valid = false
    local shield_bar_filled_segments = 0
    if type(shield_bar_segments) == "table" then
      for _, segment in pairs(shield_bar_segments) do
        if type(segment) == "table" and segment.object and segment.object.valid then
          shield_bar_valid = true
          if segment.filled == true then
            shield_bar_filled_segments = shield_bar_filled_segments + 1
          end
        end
      end
    end

    return {
      chip_id = state.chip_id,
      entity_name = current_entity and current_entity.name or nil,
      unit_number = current_entity and current_entity.unit_number or nil,
      position = current_entity and { x = current_entity.position.x, y = current_entity.position.y } or nil,
      custom_name = state.custom_name,
      show_name_label = state.show_name_label == true,
      show_label_level = state.show_label_level == true,
      show_unspent_label = state.show_unspent_label == true,
      label_text = get_profile_label_text(state),
      label_color_preset = state.label_color_preset,
      label_color = copy_serializable(state.label_color or {}),
      label_entity_valid = state.label_entity and state.label_entity.valid or false,
      name_render_valid = state.name_render and state.name_render.valid or false,
      automation_preset = state.automation_preset or "manual",
      automation_enabled = state.automation_enabled == true,
      automation_target = copy_serializable(state.automation_target),
      automation_target_model = profile_automation.target_model(state),
      automation_conflict = state.automation_conflict == true,
      automation_last_spent = state.automation_last_spent or 0,
      shield_bar_valid = shield_bar_valid,
      shield_bar_fill_valid = shield_bar_filled_segments > 0,
      shield_bar_segment_count = type(shield_bar_segments) == "table" and #shield_bar_segments or 0,
      shield_bar_filled_segments = shield_bar_filled_segments,
      bound_turret = state.bound_turret == true,
      last_ammo = copy_serializable(state.last_ammo),
      ammo_productivity_progress = state.ammo_productivity_progress or state.ammo_regen_progress or 0,
      ammo_regen_progress = state.ammo_productivity_progress or state.ammo_regen_progress or 0,
      derived = {
        repair_per_second = get_repair_per_second(state, current_entity),
        ammo_productivity_fraction = get_ammo_productivity_fraction(state),
        effective_ammo_productivity_fraction = get_effective_ammo_productivity_fraction(state),
        ammo_recovery_per_minute = get_ammo_recovery_per_minute(state),
        shield_on_hit_fraction = get_shield_on_hit_fraction(state),
        lifesteal_rate = get_lifesteal_rate(state),
        crit_damage_fraction = get_crit_damage_fraction(state),
        crit_chance_fraction = get_crit_chance_fraction(state),
        double_shot_chance = get_double_shot_chance(state),
        damage_resistance_fraction = get_damage_resistance_fraction(state),
        shield_capacity = shield_capacity,
        shield_recharge_per_second = get_shield_recharge_per_second(state),
      },
      shield = shield,
      xp = state.xp or 0,
      total_xp = state.total_xp or 0,
      level = state.level or 0,
      kills = state.kills or 0,
      kill_credit = state.kill_credit or 0,
      damage = state.damage or 0,
      xp_damage = state.xp_damage or 0,
      xp_kill_credit = state.xp_kill_credit or 0,
      combat_xp_gain_schema = state.combat_xp_gain_schema or 0,
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
      xp_damage = profile.xp_damage or 0,
      xp_kill_credit = profile.xp_kill_credit or 0,
      total_xp = profile.total_xp or 0,
      combat_xp_gain_schema = profile.combat_xp_gain_schema or 0,
      custom_name = profile.custom_name or "",
      show_name_label = profile.show_name_label == true,
      show_label_level = profile.show_label_level == true,
      show_unspent_label = profile.show_unspent_label == true,
      label_text = get_profile_label_text(profile),
      label_display_schema = profile.label_display_schema,
      automation_preset = profile.automation_preset or "manual",
      automation_enabled = profile.automation_enabled == true,
      automation_target = copy_serializable(profile.automation_target),
      automation_target_model = profile_automation.target_model(profile),
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
      "show_unspent_label",
      "label_color",
      "label_color_preset",
      "automation_preset",
      "automation_enabled",
      "automation_target",
      "bound_turret",
      "xp_damage",
      "xp_kill_credit",
      "combat_xp_gain_schema",
      "dev_xp",
      "kills",
      "kill_credit",
      "damage",
      "ammo_productivity_progress",
      "ammo_regen_progress",
      "shield",
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

  local function turret_xp_test_register_methods(target, methods)
    for name, method in pairs(methods) do
      target[name] = method
    end
  end

  local turret_xp_test_remote_methods = {}

  -- Core/profile fixtures.
  turret_xp_test_register_methods(turret_xp_test_remote_methods, {
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
    serialize_profile_snapshot = function(fields)
      return serialize_profile(fields)
    end,
    label_text_sample = function(fields)
      local profile = turret_xp_test_set_profile_fields(create_blank_profile(), fields)
      return {
        text = get_profile_label_text(profile),
        profile = turret_xp_test_profile_summary(profile),
      }
    end,
    set_evolution = function(entity, fields)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local evolution = ensure_evolution_state(state)
      fields = type(fields) == "table" and fields or {}
      local shield_rank_changed = false
      if fields.base then
        for key, value in pairs(fields.base) do
          evolution.base[key] = value
          if key == "shield" then
            shield_rank_changed = true
          end
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
      if shield_rank_changed then
        normalize_shield_state(state, false)
        update_shield_bar_render(entity, state, true)
      end
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
  })

  local function turret_xp_test_policy_from_entity(entity)
    if not is_gun_turret(entity) then
      return nil
    end

    local profile = get_turret_state(entity)
    if profile then
      local policy = profile_automation.policy_from_profile(profile)
      policy.request_core = true
      return copy_serializable(policy)
    end

    return copy_serializable(profile_automation.policy_from_host(get_turret_host(entity, false)))
  end

  local function turret_xp_test_core_request_status(entity)
    ensure_storage()
    local status = core_requester.status(entity)
    local host = get_turret_host(entity, false)
    local requester = host and host.core_requester or nil
    local inventory = nil
    if requester and requester.valid then
      inventory = compat.try("read test core requester inventory", function()
        return requester.get_inventory(defines.inventory.chest)
      end)
    end

    status.host_request_core = host and host.request_core == true or false
    status.has_pending_policy = type(host and host.pending_policy) == "table"
    status.requester_unit_number = requester and requester.valid and requester.unit_number or nil
    status.delivered_count = inventory and inventory.valid and inventory.get_item_count(CHIP_NAME) or 0
    status.active_count = turret_xp_test_table_count(storage.turret_xp.core_requesters)
    return status
  end

  -- Automation, copy-policy, and logistic request fixtures.
  turret_xp_test_register_methods(turret_xp_test_remote_methods, {
    automation_presets = function()
      local ids = {}
      for _, preset in ipairs(profile_automation.presets()) do
        ids[#ids + 1] = preset.id
      end
      return ids
    end,
    apply_automation = function(entity, preset_id, enabled, force)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      if preset_id ~= nil then
        state.automation_preset = profile_automation.preset_by_id(preset_id).id
      end
      if enabled ~= nil then
        state.automation_enabled = enabled == true and state.automation_preset ~= "manual"
      end
      local result = profile_automation.apply_to_profile(entity, state, {
        force = force == true,
      })
      local synced = combat.sync_turret_body_when_idle(entity, state)
      local summary = turret_xp_test_state_summary(synced or entity)
      summary.automation_result = result
      return summary
    end,
    set_core_request = function(entity, enabled)
      core_requester.set_request(entity, enabled == true)
      return turret_xp_test_core_request_status(entity)
    end,
    core_request_status = function(entity)
      return turret_xp_test_core_request_status(entity)
    end,
    insert_requested_core = function(entity, fields)
      local host = is_gun_turret(entity) and get_turret_host(entity, false) or nil
      local requester = host and host.core_requester or nil
      local inventory = requester
          and requester.valid
          and compat.try("read core requester inventory for insert", function()
            return requester.get_inventory(defines.inventory.chest)
          end)
        or nil
      if not inventory or not inventory.valid then
        return {
          inserted = 0,
          status = turret_xp_test_core_request_status(entity),
        }
      end

      local profile = turret_xp_test_set_profile_fields(create_blank_profile(), fields)
      local inserted = inventory.insert(make_chip_item_stack(profile))
      return {
        inserted = inserted or 0,
        status = turret_xp_test_core_request_status(entity),
      }
    end,
    process_core_requests = function(limit)
      return copy_serializable(core_requester.process_requests(limit))
    end,
    policy_from_entity = function(entity)
      return turret_xp_test_policy_from_entity(entity)
    end,
    apply_policy = function(entity, policy)
      local applied = profile_automation.apply_policy_to_host(entity, policy)
      return {
        applied = applied == true,
        state = turret_xp_test_state_summary(entity),
        request = turret_xp_test_core_request_status(entity),
      }
    end,
    paste_policy = function(source, destination)
      local policy = turret_xp_test_policy_from_entity(source)
      local applied = profile_automation.apply_policy_to_host(destination, policy)
      return {
        applied = applied == true,
        policy = copy_serializable(policy),
        state = turret_xp_test_state_summary(destination),
        request = turret_xp_test_core_request_status(destination),
      }
    end,
  })

  local function gui_snapshot_frame_for_player(player, center)
    if not player or not player.valid then
      return nil
    end

    local panel = get_gui_panel(player)
    if not panel or not panel.valid then
      return nil
    end

    local actual_size = panel.actual_size
    if not actual_size then
      return nil
    end

    local width = tonumber(actual_size.width or actual_size.x)
    local height = tonumber(actual_size.height or actual_size.y)
    if not width or not height or width <= 0 or height <= 0 then
      return nil
    end

    local location = panel.location
    local x = location and tonumber(location.x)
    local y = location and tonumber(location.y)
    if center or not x or not y then
      local display = player.display_resolution or {}
      local display_width = tonumber(display.width or display.x) or width
      local display_height = tonumber(display.height or display.y) or height
      x = math.max(0, math.floor((display_width - width) / 2))
      y = math.max(0, math.floor((display_height - height) / 2))
      pcall(function()
        panel.location = { x = x, y = y }
      end)
      location = panel.location
      x = location and tonumber(location.x) or x
      y = location and tonumber(location.y) or y
    end

    return {
      location = {
        x = x,
        y = y,
      },
      actual_size = {
        width = width,
        height = height,
      },
      top_left = {
        x = x,
        y = y,
      },
      bottom_right = {
        x = x + width,
        y = y + height,
      },
    }
  end

  local function last_gui_descendant(element)
    local children = element and element.children or nil
    if not children or #children == 0 then
      return element
    end

    return last_gui_descendant(children[#children])
  end

  local function first_gui_descendant(element)
    local children = element and element.children or nil
    if not children or #children == 0 then
      return element
    end

    return first_gui_descendant(children[1])
  end

  local function find_first_gui_type(parent, gui_type)
    if not parent or not parent.valid then
      return nil
    end

    if parent.type == gui_type then
      return parent
    end

    for _, child in pairs(parent.children or {}) do
      local found = find_first_gui_type(child, gui_type)
      if found then
        return found
      end
    end

    return nil
  end

  local function gui_style_property(element, property)
    if not element or not element.valid or not element.style then
      return nil
    end

    local ok, value = pcall(function()
      return element.style[property]
    end)
    if not ok then
      return nil
    end

    local value_type = type(value)
    if value_type == "string" or value_type == "number" or value_type == "boolean" then
      return value
    end

    return nil
  end

  local function gui_element_name(element)
    local name = element and element.valid and element.name or nil
    if name == "" then
      return nil
    end

    return name
  end

  local function make_fake_gui_element(definition)
    definition = definition or {}
    if definition.type == "checkbox" and type(definition.state) ~= "boolean" then
      error("fake GUI checkbox requires boolean state", 2)
    end

    local element = {
      valid = true,
      type = definition.type or "flow",
      name = definition.name or "",
      caption = definition.caption,
      tooltip = definition.tooltip,
      tags = definition.tags,
      direction = definition.direction,
      state = definition.state,
      value = definition.value,
      selected_index = definition.selected_index,
      items = definition.items,
      visible = definition.visible ~= false,
      enabled = definition.enabled ~= false,
      style = {},
      style_name = definition.style,
      children = {},
    }

    element.add = function(child_definition)
      local child = make_fake_gui_element(child_definition)
      element.children[#element.children + 1] = child
      return child
    end

    for _, child_definition in ipairs(definition.children or {}) do
      element.add(child_definition)
    end

    element.clear = function()
      for _, child in ipairs(element.children) do
        child.valid = false
      end
      element.children = {}
    end

    element.destroy = function()
      element.valid = false
    end

    setmetatable(element, {
      __index = function(parent, key)
        if type(key) ~= "string" then
          return nil
        end
        for _, child in ipairs(parent.children or {}) do
          if child.name == key then
            return child
          end
        end
        return nil
      end,
    })

    return element
  end

  local function make_fake_dispatch_player(entity)
    return {
      valid = true,
      index = 65536,
      opened = entity,
      gui = {
        relative = make_fake_gui_element({ type = "flow" }),
        left = make_fake_gui_element({ type = "flow" }),
        screen = make_fake_gui_element({ type = "flow" }),
      },
      print = function() end,
      create_local_flying_text = function() end,
    }
  end

  local function stats_row_layout_summary(row)
    local children = row and row.children or {}
    local label = children[1]
    local spacer = children[2]
    local value = children[3]
    local summary = {
      label_type = label and label.valid and label.type or nil,
      label_horizontal_align = gui_style_property(label, "horizontal_align"),
      label_maximal_width = gui_style_property(label, "maximal_width"),
      spacer_type = spacer and spacer.valid and spacer.type or nil,
      value_type = value and value.valid and value.type or nil,
      value_name = gui_element_name(value),
      value_horizontal_align = gui_style_property(value, "horizontal_align"),
      value_width = gui_style_property(value, "width"),
      value_minimal_width = gui_style_property(value, "minimal_width"),
      value_maximal_width = gui_style_property(value, "maximal_width"),
      value_children = {},
    }

    for _, child in ipairs(value and value.children or {}) do
      summary.value_children[#summary.value_children + 1] = {
        type = child and child.valid and child.type or nil,
        name = gui_element_name(child),
      }
    end

    local first_child = value and value.children and value.children[1] or nil
    summary.value_first_child_type = first_child and first_child.type or nil
    summary.value_first_child_name = gui_element_name(first_child)
    summary.value_first_child_width = gui_style_property(first_child, "width")
    summary.value_first_child_minimal_width = gui_style_property(first_child, "minimal_width")
    summary.value_first_child_maximal_width = gui_style_property(first_child, "maximal_width")
    summary.value_first_child_left_margin = gui_style_property(first_child, "left_margin")
    summary.value_first_child_horizontal_align = gui_style_property(first_child, "horizontal_align")

    local first_grandchild = first_child and first_child.children and first_child.children[1] or nil
    summary.value_first_grandchild_type = first_grandchild and first_grandchild.valid and first_grandchild.type or nil
    summary.value_first_grandchild_name = gui_element_name(first_grandchild)
    summary.value_first_grandchild_width = gui_style_property(first_grandchild, "width")

    return summary
  end

  local function gui_snapshot_scroll_target(panel, target)
    if target == "stats" then
      return find_gui_element(panel, GUI.stats_scroll)
    end
    if target == "inventory" then
      local inventory = find_gui_element(panel, GUI.inventory_cores)
      return find_first_gui_type(inventory, "scroll-pane")
    end

    return find_gui_element(panel, GUI.evolution)
  end

  local function scroll_gui_snapshot(player, target, position)
    local panel = get_gui_panel(player)
    local scroll = panel and gui_snapshot_scroll_target(panel, target or "evolution") or nil
    if not scroll or not scroll.valid then
      return false
    end

    local anchor = position == "top" and first_gui_descendant(scroll) or last_gui_descendant(scroll)
    if not anchor or not anchor.valid or anchor == scroll then
      return false
    end

    local ok = pcall(function()
      scroll.scroll_to_element(anchor)
    end)
    return ok == true
  end

  -- GUI, compatibility, and prototype inspection fixtures.
  turret_xp_test_register_methods(turret_xp_test_remote_methods, {
    open_gui = function(player, entity)
      if not player or not player.valid or not is_gun_turret(entity) then
        return false
      end

      player.opened = entity
      build_turret_gui(player, entity)
      return true
    end,
    open_gui_standalone = function(player, entity)
      if not player or not player.valid or not is_gun_turret(entity) then
        return false
      end

      build_turret_gui_screen(player, entity)
      return true
    end,
    close_gui = function(player)
      if not player or not player.valid then
        return false
      end

      destroy_gui(player)
      forget_open_turret(player)
      return true
    end,
    open_gui_contract = function(entity)
      if not is_gun_turret(entity) then
        return {
          opened = false,
        }
      end

      local player = make_fake_dispatch_player(entity)
      local root = make_fake_gui_element({ type = "frame", name = GUI.panel })
      add_core_panel(root, "empty")
      update_core_panel(root, player, entity, nil)
      local panel = find_gui_element(root, GUI.core)
      local summary = {
        opened = panel and panel.valid == true or false,
        key = panel and panel.tags and panel.tags.key or nil,
      }
      if storage and storage.turret_xp then
        storage.turret_xp.players[player.index] = nil
        storage.turret_xp.player_settings[player.index] = nil
      end
      return summary
    end,
    gui_snapshot_frame = function(player)
      return gui_snapshot_frame_for_player(player, false)
    end,
    center_gui_snapshot_frame = function(player)
      return gui_snapshot_frame_for_player(player, true)
    end,
    set_gui_snapshot_scroll = function(player, target, position)
      return scroll_gui_snapshot(player, target, position)
    end,
    gui_snapshot_layout = function()
      return {
        panel_width = LAYOUT.panel_max_width,
        panel_body_width = LAYOUT.left_column_width,
        evolution_column_width = LAYOUT.evolution_column_width,
        panel_height = LAYOUT.evolution_outer_height + 72,
        fallback_crop = "center",
      }
    end,
    stats_panel_layout_sample = function(entity)
      if not is_gun_turret(entity) then
        return {
          available = false,
        }
      end

      local state = get_turret_state(entity)
      if not state then
        return {
          available = false,
        }
      end

      local panel = make_fake_gui_element({
        type = "flow",
        name = GUI.panel,
        direction = "vertical",
      })
      panel.add({
        type = "flow",
        name = GUI.stats,
        direction = "vertical",
      })

      local max_health = safe_read(entity, "max_health") or 400
      local health = safe_read(entity, "health") or max_health
      local ok, err = pcall(update_stats_panel, panel, entity, state, "firearm-magazine", 20, "normal", 7, 10, "normal", max_health, health)
      if not ok then
        return {
          available = false,
          error = tostring(err),
        }
      end

      local stats = find_gui_element(panel, GUI.stats)
      local sample = {
        available = stats ~= nil,
        rows = {},
        named_rows = {},
      }

      if stats then
        for _, row in ipairs(stats.children or {}) do
          if row.valid and row.type == "flow" then
            local summary = stats_row_layout_summary(row)
            sample.rows[#sample.rows + 1] = summary

            if summary.value_name == GUI.magazine then
              sample.named_rows.magazine = summary
            elseif summary.value_name == GUI.ammo then
              sample.named_rows.ammo = summary
            elseif summary.value_name == GUI.ammo_productivity then
              sample.named_rows.ammo_productivity = summary
            end
          end
        end
      end

      return sample
    end,
    dispatch_cycle_label_color = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local player = {
        index = 65536,
        opened = entity,
        gui = {
          relative = {},
          left = {},
        },
      }
      remember_open_turret(player, entity)
      dispatch_gui_click_action(player, {}, {
        turret_xp_action = "cycle-label-color",
      })

      local summary = turret_xp_test_state_summary(entity)
      forget_open_turret(player)

      return summary
    end,
    dispatch_toggle_label_level = function(entity, visible)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local player = make_fake_dispatch_player(entity)
      remember_open_turret(player, entity)
      dispatch_gui_checked_state_action(player, {
        element = {
          valid = true,
          state = visible == true,
        },
      }, {
        turret_xp_action = "toggle-label-level",
      })

      local summary = turret_xp_test_state_summary(entity)
      forget_open_turret(player)

      return summary
    end,
    dispatch_toggle_label_unspent = function(entity, visible)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local player = {
        index = -1,
        opened = entity,
        gui = {
          relative = {},
          left = {},
        },
      }
      remember_open_turret(player, entity)
      dispatch_gui_checked_state_action(player, {
        element = {
          valid = true,
          state = visible == true,
        },
      }, {
        turret_xp_action = "toggle-label-unspent",
      })

      local summary = turret_xp_test_state_summary(entity)
      forget_open_turret(player)

      return summary
    end,
    dispatch_toggle_core_request = function(entity, visible)
      if not is_gun_turret(entity) then
        return nil
      end

      local player = make_fake_dispatch_player(entity)
      remember_open_turret(player, entity)
      dispatch_gui_checked_state_action(player, {
        element = {
          valid = true,
          state = visible == true,
        },
      }, {
        turret_xp_action = "toggle-core-request",
      })
      forget_open_turret(player)

      return turret_xp_test_core_request_status(entity)
    end,
    dispatch_select_automation = function(entity, preset_id)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local presets = {}
      local selected_index = 1
      for index, preset in ipairs(profile_automation.presets()) do
        presets[index] = preset.id
        if preset.id == preset_id then
          selected_index = index
        end
      end

      local player = make_fake_dispatch_player(entity)
      remember_open_turret(player, entity)
      dispatch_gui_selection_state_action(player, {
        element = {
          valid = true,
          selected_index = selected_index,
        },
      }, {
        turret_xp_action = "set-automation-preset",
        presets = presets,
      })

      forget_open_turret(player)

      local synced = combat.sync_turret_body_when_idle(entity, state)
      local summary = turret_xp_test_state_summary(synced or entity)
      return summary
    end,
    dispatch_toggle_automation = function(entity, visible)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local player = make_fake_dispatch_player(entity)
      remember_open_turret(player, entity)
      dispatch_gui_checked_state_action(player, {
        element = {
          valid = true,
          state = visible == true,
        },
      }, {
        turret_xp_action = "toggle-automation",
      })

      forget_open_turret(player)

      local synced = combat.sync_turret_body_when_idle(entity, state)
      local summary = turret_xp_test_state_summary(synced or entity)
      return summary
    end,
    dispatch_apply_automation = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local player = make_fake_dispatch_player(entity)
      remember_open_turret(player, entity)
      dispatch_gui_click_action(player, {}, {
        turret_xp_action = "apply-automation",
      })

      forget_open_turret(player)

      local synced = combat.sync_turret_body_when_idle(entity, state)
      local summary = turret_xp_test_state_summary(synced or entity)
      return summary
    end,
    runtime_render_pressure_sample = function(core_count, repeat_updates)
      local counter = {
        text_draw_calls = 0,
        text_property_writes = 0,
        sprite_draw_calls = 0,
        sprite_property_writes = 0,
        destroy_calls = 0,
      }

      local function make_render_object(kind)
        local store = {
          valid = true,
        }
        local object = {}
        setmetatable(object, {
          __index = function(_, key)
            if key == "destroy" then
              return function()
                store.valid = false
                counter.destroy_calls = counter.destroy_calls + 1
              end
            end
            return store[key]
          end,
          __newindex = function(_, key, value)
            counter[kind .. "_property_writes"] = counter[kind .. "_property_writes"] + 1
            store[key] = value
          end,
        })
        return object
      end

      local function normalize_test_profile(profile)
        local shield = profile and profile.shield or nil
        local shield_capacity = profile and profile._test_shield_capacity or nil
        profile = normalize_profile(profile)
        profile.shield = shield
        profile._test_shield_capacity = shield_capacity
        return profile
      end

      local labels = profile_labels_module.new({
        normalize_profile = normalize_test_profile,
        is_gun_turret = function(entity)
          return entity and entity.valid == true
        end,
        rendering_api = function()
          return {
            draw_text = function()
              counter.text_draw_calls = counter.text_draw_calls + 1
              return make_render_object("text")
            end,
            draw_sprite = function()
              counter.sprite_draw_calls = counter.sprite_draw_calls + 1
              return make_render_object("sprite")
            end,
          }
        end,
        label_colors = label_colors,
        game_tick = function()
          return game and game.tick or 0
        end,
        normalize_shield_state = function(profile, fill_if_missing)
          local capacity = tonumber(profile and profile._test_shield_capacity) or 0
          if capacity <= 0 then
            if profile then
              profile.shield = 0
            end
            return 0, 0
          end

          local current = tonumber(profile.shield)
          if current == nil then
            current = fill_if_missing ~= false and capacity or 0
          end
          profile.shield = math.max(0, math.min(capacity, current))
          return profile.shield, capacity
        end,
      })

      local count = math.max(1, math.floor(tonumber(core_count) or 1))
      local repeats = math.max(1, math.floor(tonumber(repeat_updates) or 1))
      local surface = game.surfaces[1]
      local force = game.forces.player
      local entries = {}

      for index = 1, count do
        entries[index] = {
          entity = {
            valid = true,
            unit_number = 100000 + index,
            surface = surface,
            force = force,
          },
          profile = normalize_profile({
            custom_name = "Named turret " .. tostring(index),
            level = 7,
            show_name_label = true,
            show_label_level = true,
            label_color = { 1, 0.86, 0.46 },
            label_color_preset = "gold",
          }),
        }
        entries[index].profile._test_shield_capacity = 100
        entries[index].profile.shield = 50
        labels.update_name_render(entries[index].entity, entries[index].profile)
        labels.update_shield_bar_render(entries[index].entity, entries[index].profile, true)
      end

      local initial_text_draw_calls = counter.text_draw_calls
      local initial_text_property_writes = counter.text_property_writes
      local initial_sprite_draw_calls = counter.sprite_draw_calls
      local initial_sprite_property_writes = counter.sprite_property_writes

      for _ = 1, repeats do
        for _, entry in ipairs(entries) do
          labels.update_name_render(entry.entity, entry.profile)
          labels.update_shield_bar_render(entry.entity, entry.profile, true)
        end
      end

      local no_change_text_draw_calls = counter.text_draw_calls - initial_text_draw_calls
      local no_change_text_property_writes = counter.text_property_writes - initial_text_property_writes
      local no_change_sprite_draw_calls = counter.sprite_draw_calls - initial_sprite_draw_calls
      local no_change_sprite_property_writes = counter.sprite_property_writes - initial_sprite_property_writes

      for _, entry in ipairs(entries) do
        entry.profile.level = entry.profile.level + 1
        entry.profile.shield = entry.profile.shield + 10
        labels.update_name_render(entry.entity, entry.profile)
        labels.update_shield_bar_render(entry.entity, entry.profile, true)
      end

      return {
        core_count = count,
        repeat_updates = repeats,
        initial_text_draw_calls = initial_text_draw_calls,
        initial_sprite_draw_calls = initial_sprite_draw_calls,
        no_change_text_draw_calls = no_change_text_draw_calls,
        no_change_text_property_writes = no_change_text_property_writes,
        no_change_sprite_draw_calls = no_change_sprite_draw_calls,
        no_change_sprite_property_writes = no_change_sprite_property_writes,
        changed_text_draw_calls = counter.text_draw_calls - initial_text_draw_calls - no_change_text_draw_calls,
        changed_text_property_writes = counter.text_property_writes - initial_text_property_writes - no_change_text_property_writes,
        changed_sprite_draw_calls = counter.sprite_draw_calls - initial_sprite_draw_calls - no_change_sprite_draw_calls,
        changed_sprite_property_writes = counter.sprite_property_writes - initial_sprite_property_writes - no_change_sprite_property_writes,
      }
    end,
    runtime_world_pressure_sample = function(surface, core_count, repeat_updates)
      surface = surface or game.surfaces[1]
      local count = math.max(1, math.floor(tonumber(core_count) or 1))
      local repeats = math.max(1, math.floor(tonumber(repeat_updates) or 1))
      local counter = {
        text_property_writes = 0,
        sprite_property_writes = 0,
        destroy_calls = 0,
      }
      ensure_storage()
      local existing_chip_count = turret_xp_test_table_count(storage.turret_xp.chips)
      local existing_feeder_count = turret_xp_test_table_count(storage.turret_xp.feeders)
      local existing_managed_inserter_count = turret_xp_test_table_count(storage.turret_xp.managed_inserters)
      local existing_status_effect_count = #(storage.turret_xp.status_effects or {})
      local existing_pending_visual_count = #(storage.turret_xp.pending_visuals or {})
      local entries = {}

      local function make_render_object(kind)
        local store = {
          valid = true,
        }
        local object = {}
        setmetatable(object, {
          __index = function(_, key)
            if key == "destroy" then
              return function()
                store.valid = false
                counter.destroy_calls = counter.destroy_calls + 1
              end
            end
            return store[key]
          end,
          __newindex = function(_, key, value)
            counter[kind .. "_property_writes"] = counter[kind .. "_property_writes"] + 1
            store[key] = value
          end,
        })
        return object
      end

      local function attach_counted_render_handles(state)
        destroy_name_render(state)
        destroy_shield_bar_render(state)

        state.name_render = make_render_object("text")
        state._name_render_signature = nil
        state.shield_bar = {
          _shield_bar_render_version = 3,
          segments = {},
        }
        for index = 1, 9 do
          state.shield_bar.segments[index] = {
            object = make_render_object("sprite"),
          }
        end
      end

      local function cleanup()
        for _, entry in ipairs(entries) do
          local entity = entry.entity
          local state = entry.state
          if state then
            destroy_name_render(state)
            destroy_shield_bar_render(state)
            feeder.destroy(state, entity and entity.valid and entity.position or nil, false)
          end
          if entity and entity.valid then
            remove_turret_state(entity, true)
            entity.destroy({ raise_destroy = false })
          end
        end
      end

      local ok, result = pcall(function()
        for index = 1, count do
          local row = math.floor((index - 1) / 17)
          local column = (index - 1) % 17
          local entity = surface.create_entity({
            name = BASE_TURRET_NAME,
            position = {
              x = -80 + (column * 2.5),
              y = -80 + (row * 2.5),
            },
            force = "player",
            raise_built = false,
          })
          if not entity or not entity.valid then
            error("failed to create pressure-test turret " .. tostring(index))
          end
          entity.insert({ name = "firearm-magazine", count = 10 })

          local profile = turret_xp_test_set_profile_fields(create_blank_profile(), {
            custom_name = "Pressure core " .. tostring(index),
            level = 7,
            label_color = { 1, 0.86, 0.46 },
            label_color_preset = "gold",
          })
          local state = install_profile_on_turret(entity, profile)
          if not state then
            error("failed to install pressure-test core " .. tostring(index))
          end

          state.show_name_label = true
          state.show_label_level = true
          local evolution = ensure_evolution_state(state)
          evolution.base.shield = 10
          state.shield = 50
          normalize_shield_state(state, false)
          sync_turret_progression(state)
          attach_counted_render_handles(state)
          update_name_render(entity, state)
          update_shield_bar_render(entity, state, true)
          entries[#entries + 1] = {
            entity = entity,
            state = state,
          }
        end

        local initial_text_property_writes = counter.text_property_writes
        local initial_sprite_property_writes = counter.sprite_property_writes

        for _ = 1, repeats do
          apply_passive_evolution_effects()
        end

        local passive_text_property_writes = counter.text_property_writes - initial_text_property_writes
        local passive_sprite_property_writes = counter.sprite_property_writes - initial_sprite_property_writes

        for _, entry in ipairs(entries) do
          sync_turret_progression(entry.state)
          update_name_render(entry.entity, entry.state)
          update_shield_bar_render(entry.entity, entry.state, true)
        end

        return {
          core_count = count,
          repeat_updates = repeats,
          installed_core_count = #entries,
          storage_chip_count_delta = turret_xp_test_table_count(storage.turret_xp.chips) - existing_chip_count,
          feeder_count_delta = turret_xp_test_table_count(storage.turret_xp.feeders) - existing_feeder_count,
          managed_inserter_count_delta = turret_xp_test_table_count(storage.turret_xp.managed_inserters) - existing_managed_inserter_count,
          status_effect_count_delta = #(storage.turret_xp.status_effects or {}) - existing_status_effect_count,
          pending_visual_count_delta = #(storage.turret_xp.pending_visuals or {}) - existing_pending_visual_count,
          initial_text_property_writes = initial_text_property_writes,
          initial_sprite_property_writes = initial_sprite_property_writes,
          passive_text_property_writes = passive_text_property_writes,
          passive_sprite_property_writes = passive_sprite_property_writes,
          direct_refresh_text_property_writes = counter.text_property_writes - initial_text_property_writes - passive_text_property_writes,
          direct_refresh_sprite_property_writes = counter.sprite_property_writes
            - initial_sprite_property_writes
            - passive_sprite_property_writes,
        }
      end)

      cleanup()
      if ok then
        return result
      end
      error(result, 0)
    end,
    dispatch_rank_modifier_sample = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local player = {
        index = -1,
        opened = entity,
        gui = {
          relative = {},
          left = {},
        },
      }
      remember_open_turret(player, entity)
      dispatch_gui_click_action(player, {
        control = true,
      }, {
        turret_xp_action = "allocate-base",
        upgrade = "damage",
      })
      local after_base_add = turret_xp_test_state_summary(entity)
      dispatch_gui_click_action(player, {
        control = true,
      }, {
        turret_xp_action = "deallocate-base",
        upgrade = "damage",
      })
      local after_base_remove = turret_xp_test_state_summary(entity)
      dispatch_gui_click_action(player, {
        control = true,
      }, {
        turret_xp_action = "allocate-augment",
        augment = "luck",
      })
      local after_augment_add = turret_xp_test_state_summary(entity)
      dispatch_gui_click_action(player, {
        control = true,
      }, {
        turret_xp_action = "deallocate-augment",
        augment = "luck",
      })
      local after_augment_remove = turret_xp_test_state_summary(entity)
      forget_open_turret(player)

      return {
        base_after_ctrl_add = after_base_add and after_base_add.evolution.base.damage or 0,
        base_available_after_ctrl_add = after_base_add and after_base_add.evolution.available_core_points or 0,
        base_after_ctrl_remove = after_base_remove and (after_base_remove.evolution.base.damage or 0) or 0,
        base_available_after_ctrl_remove = after_base_remove and after_base_remove.evolution.available_core_points or 0,
        augment_after_ctrl_add = after_augment_add and after_augment_add.evolution.augments.luck or 0,
        augment_available_after_ctrl_add = after_augment_add and after_augment_add.evolution.available_augment_points or 0,
        augment_after_ctrl_remove = after_augment_remove and (after_augment_remove.evolution.augments.luck or 0) or 0,
        augment_available_after_ctrl_remove = after_augment_remove and after_augment_remove.evolution.available_augment_points or 0,
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
        rich_value = rich_value(42, "/s"),
        rich_metric = rich_metric("HP", 400),
        rich_stat = rich_stat_text("Damage +5 x1.2"),
        rich_specialization = rich_specialization_caption("sniper", "Sniper"),
      }
    end,
    inventory_core_picker_sample = function(entity)
      local inventory = game.create_inventory(4)
      local low = turret_xp_test_set_profile_fields(create_blank_profile(), {
        custom_name = "Low",
        level = 3,
        kills = 2,
        damage = 50,
      })
      local high = turret_xp_test_set_profile_fields(create_blank_profile(), {
        custom_name = "High",
        level = 14,
        kills = 1,
        damage = 75,
      })
      local mid = turret_xp_test_set_profile_fields(create_blank_profile(), {
        custom_name = "Mid",
        level = 9,
        kills = 20,
        damage = 500,
      })
      local unnamed = turret_xp_test_set_profile_fields(create_blank_profile(), {
        level = 1,
        kills = 0,
        damage = 0,
      })
      ensure_evolution_state(high).specialization = "sniper"
      ensure_evolution_state(mid).specialization = "machine_gun"

      inventory[1].set_stack(make_chip_item_stack(low))
      inventory[2].set_stack(make_chip_item_stack(high))
      inventory[3].set_stack(make_chip_item_stack(mid))
      inventory[4].set_stack(make_chip_item_stack(unnamed))

      local options = get_core_options_from_inventory(inventory)
      local kill_sorted = get_core_options_from_inventory(inventory, "kills:desc")
      local damage_sorted = get_core_options_from_inventory(inventory, "damage:desc")
      local name_sorted = get_core_options_from_inventory(inventory, "name:asc")
      local name_desc_sorted = get_core_options_from_inventory(inventory, "name:desc")
      local function display_sort_first(sort_mode)
        local display_options = get_core_options_from_inventory(inventory)
        prepare_inventory_core_options_for_display(entity, display_options, sort_mode)
        return display_options[1] and (display_options[1].profile.custom_name or "") or nil
      end

      local only_base = get_core_options_from_inventory(inventory, "level:desc", {
        all = false,
        base = true,
        sniper = false,
        machine_gun = false,
        bulwark = false,
        brawler = false,
      })
      local only_sniper = get_core_options_from_inventory(inventory, "level:desc", {
        all = false,
        base = false,
        sniper = true,
        machine_gun = false,
        bulwark = false,
        brawler = false,
      })
      local all_filter = normalize_core_picker_filters({ all = true })
      local none_filter = normalize_core_picker_filters({
        all = false,
        base = false,
        sniper = false,
        machine_gun = false,
        bulwark = false,
        brawler = false,
      })
      local legacy_all_filter = normalize_core_picker_filters({
        base = true,
        sniper = true,
        machine_gun = true,
        bulwark = true,
        brawler = true,
      })
      local all_filtered = get_core_options_from_inventory(inventory, "level:desc", all_filter)
      local summarized = {}
      for _, option in ipairs(options) do
        summarized[#summarized + 1] = {
          slot = option.index,
          name = option.profile and (option.profile.custom_name or "") or "",
          level = option.profile and option.profile.level or nil,
          specialization = option.profile and option.profile.evolution and option.profile.evolution.specialization or nil,
        }
      end
      local sort_samples = {
        kills = kill_sorted[1] and kill_sorted[1].profile.custom_name or nil,
        damage = damage_sorted[1] and damage_sorted[1].profile.custom_name or nil,
        name = name_sorted[1] and name_sorted[1].profile.custom_name or nil,
        name_desc = name_desc_sorted[1] and name_desc_sorted[1].profile.custom_name or nil,
        name_last = name_sorted[#name_sorted] and (name_sorted[#name_sorted].profile.custom_name or "") or nil,
        display_level_asc = display_sort_first("level:asc"),
        display_level_desc = display_sort_first("level:desc"),
        display_name_asc = display_sort_first("name:asc"),
        display_name_desc = display_sort_first("name:desc"),
        display_specialization_asc = display_sort_first("specialization:asc"),
        display_specialization_desc = display_sort_first("specialization:desc"),
        display_hp_asc = display_sort_first("hp:asc"),
        display_hp_desc = display_sort_first("hp:desc"),
        display_attack_asc = display_sort_first("attack:asc"),
        display_range_asc = display_sort_first("range:asc"),
      }
      local filter_samples = {
        all_count = #all_filtered,
        all_filter_enabled = all_filter.all == true,
        none_filter_enabled = none_filter.all == true,
        legacy_all_filter_enabled = legacy_all_filter.all == true,
        base_count = #only_base,
        base_first = only_base[1] and (only_base[1].profile.custom_name or "") or nil,
        sniper_count = #only_sniper,
        sniper_first = only_sniper[1] and (only_sniper[1].profile.custom_name or "") or nil,
      }

      storage.turret_xp.player_settings[-22] = nil
      storage.turret_xp.players[-22] = nil
      local prefs_player = {
        index = -22,
        opened = entity,
        gui = {
          relative = {},
          left = {},
        },
        get_main_inventory = function()
          return inventory
        end,
      }
      remember_open_turret(prefs_player, entity)
      set_core_picker_sort(prefs_player, "name")
      set_core_picker_filter(prefs_player, "sniper", true)
      local persisted_before_close = {
        sort = get_core_picker_sort(prefs_player),
        filters = get_core_picker_filters(prefs_player),
      }
      forget_open_turret(prefs_player)
      remember_open_turret(prefs_player, entity)
      local persisted_after_reopen = {
        sort = get_core_picker_sort(prefs_player),
        filters = get_core_picker_filters(prefs_player),
      }
      forget_open_turret(prefs_player)

      local player = {
        index = -2,
        opened = entity,
        gui = {
          relative = {},
          left = {},
        },
        get_main_inventory = function()
          return inventory
        end,
        print = function() end,
        create_local_flying_text = function() end,
      }
      remember_open_turret(player, entity)
      install_core_from_inventory(player, 2)
      local installed = turret_xp_test_state_summary(entity)
      local remaining = get_core_options_from_inventory(inventory)
      local remaining_names = {}
      for _, option in ipairs(remaining) do
        remaining_names[#remaining_names + 1] = option.profile and (option.profile.custom_name or "") or ""
      end
      forget_open_turret(player)
      inventory.destroy()

      return {
        options = summarized,
        sort_samples = sort_samples,
        filter_samples = filter_samples,
        persisted_preferences = {
          before_close = persisted_before_close,
          after_reopen = persisted_after_reopen,
        },
        installed = installed,
        remaining_names = remaining_names,
      }
    end,
    stats_formula_samples = function(fields, reference_health)
      local state = copy_serializable(fields or {})
      ensure_evolution_state(state)
      reference_health = tonumber(reference_health) or 400

      return {
        damage_multiplier = get_specialization_multiplier(state, "damage_multiplier"),
        crit_chance_fraction = get_crit_chance_fraction(state),
        crit_damage_fraction = get_crit_damage_fraction(state),
        double_shot_chance = get_double_shot_chance(state),
        damage_resistance_fraction = get_damage_resistance_fraction(state),
        shield_on_hit_fraction = get_shield_on_hit_fraction(state),
        repair_base_per_second = get_repair_base_per_second_for_health(state, reference_health),
        repair_per_second = get_repair_per_second_for_health(state, reference_health),
        capped_luck_chance = apply_luck_to_chance(state, 2),
        ammo_productivity_fraction = get_ammo_productivity_fraction(state),
        effective_ammo_productivity_fraction = get_effective_ammo_productivity_fraction(state),
        ammo_recovery_per_minute = get_ammo_recovery_per_minute(state),
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
    placement_prototypes = function()
      local gun_item = prototypes.item[BASE_TURRET_NAME]
      local bound_item = prototypes.item[BOUND_TURRET_NAME]
      local placeholder_entity = prototypes.entity[BOUND_TURRET_PLACEHOLDER_NAME]
      local preview_name = DOMAIN.bound_turret_item_name(get_bound_turret_variant_id("sniper", 0))
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
        sniper_bound_item = preview_item and preview_item.name or nil,
        sniper_bound_place_result = preview_item and preview_item.place_result and preview_item.place_result.name or nil,
        sniper_bound_preview_range = preview_attack_parameters and preview_attack_parameters.range or nil,
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
    attach_stale_label_entity = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      local ok, label_entity = pcall(function()
        return entity.surface.create_entity({
          name = "display-panel",
          position = entity.position,
          force = entity.force,
          raise_built = false,
          create_build_effect_smoke = false,
        })
      end)
      if not ok or not label_entity then
        return nil
      end

      state.label_entity = label_entity
      update_name_render(entity, state)
      local summary = turret_xp_test_state_summary(entity)
      summary.stale_label_entity_valid = label_entity.valid
      return summary
    end,
  })

  -- Combat and passive-effect fixtures.
  turret_xp_test_register_methods(turret_xp_test_remote_methods, {
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
    award_damage_xp = function(entity, amount, target_context)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      add_profile_damage(state, amount or 0, entity, target_context)
      sync_turret_progression(state)
      return turret_xp_test_state_summary(entity)
    end,
    award_kill_credit_xp = function(entity, credit, target_context)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      add_profile_kill_credit(state, credit or 0, entity, target_context)
      sync_turret_progression(state)
      return turret_xp_test_state_summary(entity)
    end,
    combat_xp_multiplier_samples = function()
      local ground_turret = { valid = true, surface = {} }
      local travelling_platform_turret = {
        valid = true,
        surface = {
          platform = {
            paused = false,
            space_connection = {},
            speed = 1,
          },
        },
      }
      local stopped_platform_turret = {
        valid = true,
        surface = {
          platform = {
            paused = false,
            space_location = {},
            speed = 0,
          },
        },
      }
      local asteroid_context = {
        name = "small-metallic-asteroid",
        type = "asteroid",
        max_health = 100,
        force_name = "enemy",
      }
      local biter_context = {
        name = "small-biter",
        type = "unit",
        max_health = 15,
        force_name = "enemy",
      }
      local training_state = create_blank_profile()
      ensure_evolution_state(training_state).augments.veteran_training = 2
      local base_state = create_blank_profile()
      local travelling_multiplier = get_travelling_asteroid_xp_multiplier()
      local stopped_multiplier = get_stopped_asteroid_xp_multiplier()

      return {
        travelling_asteroid_setting = travelling_multiplier,
        stopped_asteroid_setting = stopped_multiplier,
        platform_surface = combat.get_surface_combat_xp_multiplier(travelling_platform_turret),
        old_stacked_platform_asteroid = combat.get_surface_combat_xp_multiplier(travelling_platform_turret) * travelling_multiplier,
        ground_biter_damage = get_combat_xp_multiplier_details(ground_turret, biter_context, "damage"),
        platform_biter_damage = get_combat_xp_multiplier_details(travelling_platform_turret, biter_context, "damage"),
        travelling_platform_asteroid_damage = get_combat_xp_multiplier_details(travelling_platform_turret, asteroid_context, "damage"),
        travelling_platform_asteroid_kill = get_combat_xp_multiplier_details(travelling_platform_turret, asteroid_context, "kill"),
        stopped_platform_asteroid_damage = get_combat_xp_multiplier_details(stopped_platform_turret, asteroid_context, "damage"),
        travelling_modifier_summary = get_gui_xp_modifier_summary(travelling_platform_turret, training_state),
        stopped_modifier_summary = get_gui_xp_modifier_summary(stopped_platform_turret, nil),
        ground_modifier_summary = get_gui_xp_modifier_summary(ground_turret, base_state),
        ground_training_modifier_summary = get_gui_xp_modifier_summary(ground_turret, training_state),
        trained_travelling_platform_asteroid_damage = get_combat_xp_multiplier_details(
          travelling_platform_turret,
          asteroid_context,
          "damage",
          training_state
        ),
      }
    end,
    asteroid_xp_balance_sample = function()
      local xp_settings = get_xp_settings()
      local travel_multiplier = get_travelling_asteroid_xp_multiplier()
      local stopped_multiplier = get_stopped_asteroid_xp_multiplier()
      local old_stacked_multiplier = COMBAT_CONSTANTS.space_xp_multiplier * travel_multiplier

      local function scenario(entries, multiplier)
        local total_xp = 0
        local total_count = 0
        local rows = {}

        for _, entry in ipairs(entries) do
          local count = math.max(0, math.floor(tonumber(entry.count) or 0))
          local health = tonumber(entry.health) or 0
          local xp_each = ((health * xp_settings.xp_per_damage) + xp_settings.xp_per_kill_credit) * multiplier
          total_xp = total_xp + (xp_each * count)
          total_count = total_count + count
          rows[#rows + 1] = {
            name = entry.name,
            count = count,
            health = health,
            xp_each = xp_each,
          }
        end

        return {
          total_xp = total_xp,
          count = total_count,
          average_xp_per_asteroid = total_count > 0 and (total_xp / total_count) or 0,
          rows = rows,
        }
      end

      local trip_entries = {
        { name = "small-metallic-asteroid", count = 30, health = 100 },
        { name = "medium-metallic-asteroid", count = 6, health = 400 },
        { name = "big-metallic-asteroid", count = 1, health = 2000 },
      }
      local stationary_entries = {
        { name = "small-metallic-asteroid", count = 10, health = 100 },
      }

      return {
        travel_multiplier = travel_multiplier,
        stopped_multiplier = stopped_multiplier,
        old_stacked_multiplier = old_stacked_multiplier,
        level_1_required = xp_required(0),
        level_2_required = xp_required(1),
        trip = scenario(trip_entries, travel_multiplier),
        old_stacked_trip = scenario(trip_entries, old_stacked_multiplier),
        stationary = scenario(stationary_entries, stopped_multiplier),
        old_stacked_stationary = scenario(stationary_entries, old_stacked_multiplier),
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
    apply_passive = function(ticks)
      local count = math.max(1, math.floor(tonumber(ticks) or 1))
      for _ = 1, count do
        apply_passive_evolution_effects()
      end
      return true
    end,
    apply_shield_recharge = function(ticks)
      apply_shield_recharge_effects(math.max(1, math.floor(tonumber(ticks) or SHIELD_RECHARGE_TICKS)))
      return true
    end,
    remember_loaded_ammo = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      combat.remember_loaded_ammo(entity, state)
      return turret_xp_test_state_summary(entity)
    end,
    apply_ammo_productivity = function(entity)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      state._ammo_productivity_last_tick = nil
      combat.apply_ammo_productivity(entity, state)
      return turret_xp_test_state_summary(entity)
    end,
    age_shield_damage = function(entity, ticks)
      local state = is_gun_turret(entity) and get_turret_state(entity) or nil
      if not state then
        return nil
      end

      state._shield_last_damage_tick = (game and game.tick or 0) - math.max(0, math.floor(tonumber(ticks) or 0))
      return turret_xp_test_state_summary(entity)
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
  })

  -- Element feeder fixtures.
  turret_xp_test_register_methods(turret_xp_test_remote_methods, {
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
    feeder_refresh_stats = function()
      ensure_storage()
      return copy_serializable(feeder.get_last_refresh_stats() or {})
    end,
  })

  -- Bound turret item fixtures.
  turret_xp_test_register_methods(turret_xp_test_remote_methods, {
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
        destroy_shield_bar_render(state)
        feeder.destroy(state, entity.position, true)
        remove_turret_state(entity, true)
      end
    end,
  })

  remote.add_interface("turret_xp_test", turret_xp_test_remote_methods)
end
