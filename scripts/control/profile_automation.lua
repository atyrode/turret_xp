local profile_automation = {}

local function copy_serializable(value)
  if type(value) ~= "table" then
    return value
  end

  local result = {}
  for key, child in pairs(value) do
    result[key] = copy_serializable(child)
  end
  return result
end

local function positive_rank(value)
  return math.max(0, math.floor(tonumber(value) or 0))
end

local function table_has_content(values)
  if type(values) ~= "table" then
    return false
  end

  for _, value in pairs(values) do
    if type(value) == "table" then
      if table_has_content(value) then
        return true
      end
    elseif value ~= nil and value ~= false and value ~= 0 and value ~= "" then
      return true
    end
  end
  return false
end

local function copy_policy(policy)
  if type(policy) ~= "table" then
    return nil
  end

  return {
    automation_enabled = policy.automation_enabled == true,
    automation_target = copy_serializable(policy.automation_target),
    show_name_label = policy.show_name_label == true,
    show_label_level = policy.show_label_level == true,
    show_unspent_label = policy.show_unspent_label == true,
    bound_turret = policy.bound_turret == true,
    request_core = policy.request_core == true,
    label_color = type(policy.label_color) == "table" and {
      policy.label_color[1],
      policy.label_color[2],
      policy.label_color[3],
    } or nil,
    label_color_preset = policy.label_color_preset,
  }
end

function profile_automation.new(deps)
  local service = {}

  local function definition_map(definitions)
    local by_id = {}
    for _, definition in ipairs(definitions or {}) do
      by_id[definition.id] = definition
    end
    return by_id
  end

  local base_by_id = definition_map(deps.base_upgrades)
  local augment_by_id = definition_map(deps.augments)

  local function copy_rank_targets(source, by_id)
    if type(source) ~= "table" then
      return {}
    end

    local result = {}
    for id, value in pairs(source) do
      local definition = by_id[id]
      local rank = positive_rank(value)
      if definition and rank > 0 then
        if definition.max_rank then
          rank = math.min(rank, definition.max_rank)
        end
        result[id] = rank
      end
    end
    return result
  end

  local function copy_infinite_targets(source, by_id)
    if type(source) ~= "table" then
      return {}
    end

    local result = {}
    for id, value in pairs(source) do
      if by_id[id] and value == true then
        result[id] = true
      end
    end
    return result
  end

  local function copy_element_target(source)
    if type(source) ~= "table" then
      return {}
    end

    local result = {}
    for slot = 1, 2 do
      local element_id = source[slot]
      if deps.element_by_id[element_id] then
        result[slot] = element_id
      end
    end
    return result
  end

  local function copy_element_rank_targets(source, elements)
    if type(source) ~= "table" then
      return {}
    end

    local result = {}
    for slot = 1, 2 do
      local element_id = elements and elements[slot]
      local mastery = element_id and source[element_id] or nil
      local rank = mastery and positive_rank(mastery.rank) or 0
      if element_id and rank > 0 then
        result[element_id] = {
          rank = rank,
        }
      end
    end
    return result
  end

  local function target_has_content(target)
    return type(target) == "table"
      and (
        table_has_content(target.base)
        or table_has_content(target.base_infinite)
        or table_has_content(target.augments)
        or table_has_content(target.augment_infinite)
        or table_has_content(target.elements)
        or target.specialization ~= nil
        or target.sub_specialization ~= nil
      )
  end

  local function total_ranks(definitions, ranks)
    local total = 0
    ranks = type(ranks) == "table" and ranks or {}
    for _, definition in ipairs(definitions or {}) do
      total = total + positive_rank(ranks[definition.id])
    end
    return total
  end

  local function level_for_augment_points(points)
    points = positive_rank(points)
    if points <= 0 then
      return 0
    end

    return deps.gates.augments + ((points - 1) * 10)
  end

  local function augment_points_for_level(level)
    level = positive_rank(level)
    if level < deps.gates.augments then
      return 0
    end

    return 1 + math.floor((level - deps.gates.augments) / 10)
  end

  local function merged_rank_total(definitions, live_ranks, target_ranks)
    local total = 0
    live_ranks = type(live_ranks) == "table" and live_ranks or {}
    target_ranks = type(target_ranks) == "table" and target_ranks or {}
    for _, definition in ipairs(definitions or {}) do
      total = total + math.max(positive_rank(live_ranks[definition.id]), positive_rank(target_ranks[definition.id]))
    end
    return total
  end

  local function has_infinite_targets(target)
    return table_has_content(target and target.base_infinite) or table_has_content(target and target.augment_infinite)
  end

  local function required_level_for_target(target, profile)
    if type(target) ~= "table" then
      return 0
    end

    local evolution = profile and deps.ensure_evolution_state(profile) or nil
    local base_points = evolution and merged_rank_total(deps.base_upgrades, evolution.base, target.base)
      or total_ranks(deps.base_upgrades, target.base)
    local augment_points = evolution and merged_rank_total(deps.augments, evolution.augments, target.augments)
      or total_ranks(deps.augments, target.augments)
    local level = base_points
    level = math.max(level, level_for_augment_points(augment_points))
    if target.specialization or (evolution and evolution.specialization) then
      level = math.max(level, deps.gates.specialization)
    end
    if target.sub_specialization or (evolution and evolution.sub_specialization) then
      level = math.max(level, deps.gates.sub_specialization)
    end
    if (target.elements and target.elements[1]) or (evolution and evolution.elements and evolution.elements[1]) then
      level = math.max(level, deps.gates.first_element)
    end
    if (target.elements and target.elements[2]) or (evolution and evolution.elements and evolution.elements[2]) then
      level = math.max(level, deps.gates.second_element)
    end
    return level
  end

  local function normalize_target(target, allow_empty, profile)
    if type(target) ~= "table" then
      return nil
    end

    local elements = copy_element_target(target.elements)
    local specialization = deps.specialization_by_id and deps.specialization_by_id[target.specialization] and target.specialization or nil
    local sub_specialization = nil
    if target.sub_specialization and deps.sub_specialization_by_id[target.sub_specialization] then
      local sub = deps.sub_specialization_by_id[target.sub_specialization]
      if not specialization or sub.parent == specialization then
        sub_specialization = target.sub_specialization
        specialization = specialization or sub.parent
      end
    end

    local normalized = {
      schema = 1,
      level = positive_rank(target.level),
      base = copy_rank_targets(target.base, base_by_id),
      base_infinite = copy_infinite_targets(target.base_infinite, base_by_id),
      augments = copy_rank_targets(target.augments, augment_by_id),
      augment_infinite = copy_infinite_targets(target.augment_infinite, augment_by_id),
      elements = elements,
      element_mastery = copy_element_rank_targets(target.element_mastery, elements),
      specialization = specialization,
      sub_specialization = sub_specialization,
    }
    normalized.level = required_level_for_target(normalized, profile)

    return (allow_empty == true or target_has_content(normalized)) and normalized or nil
  end

  local function empty_target()
    return normalize_target({
      base = {},
      base_infinite = {},
      augments = {},
      augment_infinite = {},
      elements = {},
      element_mastery = {},
    }, true)
  end

  local function target_from_profile(profile, allow_empty)
    profile = deps.normalize_profile(profile)
    local evolution = deps.ensure_evolution_state(profile)
    return normalize_target({
      base = evolution.base or {},
      base_infinite = profile.automation_target and profile.automation_target.base_infinite or {},
      augments = evolution.augments or {},
      augment_infinite = profile.automation_target and profile.automation_target.augment_infinite or {},
      elements = evolution.elements or {},
      element_mastery = evolution.element_mastery or {},
      specialization = evolution.specialization,
      sub_specialization = evolution.sub_specialization,
    }, allow_empty)
  end

  local function target_to_preview_profile(profile, target)
    target = normalize_target(target, true, profile)
    if not profile or not target then
      return nil
    end

    local preview = deps.normalize_profile(copy_serializable(profile))
    local evolution = deps.ensure_evolution_state(preview)
    evolution.base = copy_serializable(target.base or {})
    evolution.augments = copy_serializable(target.augments or {})
    evolution.elements = copy_serializable(target.elements or {})
    evolution.element_mastery = copy_serializable(target.element_mastery or {})
    evolution.specialization = target.specialization
    evolution.sub_specialization = target.sub_specialization
    evolution.element_project = nil
    preview.level = target.level or 0
    preview.xp = 0
    preview.required_xp = 0
    preview._build_mode_preview = true
    preview._build_infinite = {
      base = copy_serializable(target.base_infinite or {}),
      augments = copy_serializable(target.augment_infinite or {}),
    }
    preview._build_auto = profile.automation_enabled == true
    preview.automation_target = copy_serializable(target)
    preview.automation_enabled = profile.automation_enabled == true
    return preview
  end

  function service.normalize_profile(profile)
    if not profile then
      return nil
    end

    local target_can_be_empty = profile.automation_enabled == true or profile.build_mode == true
    profile.automation_target = normalize_target(profile.automation_target, target_can_be_empty, profile)
    if profile.build_mode == true then
      profile.automation_target = profile.automation_target or empty_target()
    end
    profile.automation_enabled = profile.automation_enabled == true and target_has_content(profile.automation_target)
    return profile
  end

  function service.target_from_profile(profile)
    return target_from_profile(profile)
  end

  function service.empty_target()
    return empty_target()
  end

  function service.normalize_target(target, allow_empty, profile)
    return normalize_target(target, allow_empty, profile)
  end

  function service.reconcile_profile_target(profile)
    if not profile then
      return nil
    end

    local target_can_be_empty = profile.automation_enabled == true or profile.build_mode == true
    profile.automation_target = normalize_target(profile.automation_target, target_can_be_empty, profile)
    if profile.build_mode == true then
      profile.automation_target = profile.automation_target or empty_target()
    end
    profile.automation_enabled = profile.automation_enabled == true and target_has_content(profile.automation_target)
    return profile.automation_target
  end

  function service.required_level_for_target(target)
    return required_level_for_target(normalize_target(target, true))
  end

  function service.set_build_mode(profile, enabled)
    if not profile then
      return nil
    end

    if enabled == true then
      profile.build_mode = true
      profile.automation_enabled = false
      profile.automation_target = normalize_target(profile.automation_target, true, profile)
        or target_from_profile(profile, true)
        or empty_target()
    else
      profile.build_mode = false
      profile.automation_target = normalize_target(profile.automation_target, true, profile)
      if not target_has_content(profile.automation_target) then
        profile.automation_target = nil
        profile.automation_enabled = false
      end
    end

    return profile.automation_target
  end

  function service.ensure_build_target(profile)
    if not profile then
      return nil
    end

    profile.automation_target = normalize_target(profile.automation_target, true, profile)
      or target_from_profile(profile, true)
      or empty_target()
    return profile.automation_target
  end

  function service.build_mode_active(profile)
    return profile and profile.build_mode == true and normalize_target(profile.automation_target, true) ~= nil
  end

  function service.build_preview_profile(profile)
    if not service.build_mode_active(profile) then
      return nil
    end

    return target_to_preview_profile(profile, profile.automation_target)
  end

  function service.target_has_content(target)
    return target_has_content(normalize_target(target))
  end

  local function rank_list(definitions, ranks)
    ranks = type(ranks) == "table" and ranks or {}
    local parts = {}
    for _, definition in ipairs(definitions or {}) do
      local rank = positive_rank(ranks[definition.id])
      if rank > 0 then
        parts[#parts + 1] = definition.name .. " " .. rank
      end
    end
    return table.concat(parts, ", ")
  end

  local function infinite_rank_list(definitions, ranks)
    ranks = type(ranks) == "table" and ranks or {}
    local parts = {}
    for _, definition in ipairs(definitions or {}) do
      if ranks[definition.id] == true then
        parts[#parts + 1] = definition.name
      end
    end
    return table.concat(parts, ", ")
  end

  local function target_choice_name(target)
    if not target then
      return nil
    end

    local specialization = target.specialization and deps.specialization_by_id[target.specialization] or nil
    local sub_specialization = target.sub_specialization and deps.sub_specialization_by_id[target.sub_specialization] or nil
    if specialization and sub_specialization then
      return specialization.name .. " / " .. sub_specialization.name
    end
    if specialization then
      return specialization.name
    end
    return nil
  end

  local function target_elements_name(target)
    local parts = {}
    for _, element_id in ipairs((target and target.elements) or {}) do
      local element = deps.element_by_id[element_id]
      if element then
        local rank = target.element_mastery
            and target.element_mastery[element_id]
            and positive_rank(target.element_mastery[element_id].rank)
          or 0
        parts[#parts + 1] = rank > 0 and (element.name .. " " .. rank) or element.name
      end
    end
    return table.concat(parts, ", ")
  end

  function service.target_model(profile)
    local target = normalize_target(profile and profile.automation_target, profile and profile.build_mode == true, profile)
    if not target then
      return nil
    end

    local core = rank_list(deps.base_upgrades, target.base)
    local augments = rank_list(deps.augments, target.augments)
    local core_infinite = infinite_rank_list(deps.base_upgrades, target.base_infinite)
    local augment_infinite = infinite_rank_list(deps.augments, target.augment_infinite)
    local choice = target_choice_name(target)
    local elements = target_elements_name(target)
    local tooltip = { "turret-xp.build-target-tooltip-header" }

    if choice and choice ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.build-target-tooltip-specialization", choice } }
    end
    if elements and elements ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.build-target-tooltip-elements", elements } }
    end
    if core and core ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.build-target-tooltip-core", core } }
    end
    if core_infinite and core_infinite ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.build-target-tooltip-core-forever", core_infinite } }
    end
    if augments and augments ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.build-target-tooltip-augments", augments } }
    end
    if augment_infinite and augment_infinite ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.build-target-tooltip-augments-forever", augment_infinite } }
    end

    return {
      level = target.level or 0,
      open_ended = has_infinite_targets(target),
      core_points = total_ranks(deps.base_upgrades, target.base),
      core_total = target.level or 0,
      augment_points = total_ranks(deps.augments, target.augments),
      augment_total = augment_points_for_level(target.level or 0),
      core_infinite = core_infinite,
      augment_infinite = augment_infinite,
      choice = choice,
      elements = elements,
      core = core,
      augments = augments,
      tooltip = tooltip,
    }
  end

  function service.policy_from_profile(profile)
    profile = service.normalize_profile(deps.normalize_profile(profile))
    local planned_target = normalize_target(profile.automation_target)
    local target = planned_target or target_from_profile(profile)
    return copy_policy({
      automation_enabled = profile.automation_enabled == true or target ~= nil,
      automation_target = target,
      show_name_label = profile.show_name_label == true,
      show_label_level = profile.show_label_level == true,
      show_unspent_label = profile.show_unspent_label == true,
      bound_turret = profile.bound_turret == true,
      label_color = profile.label_color,
      label_color_preset = profile.label_color_preset,
    })
  end

  function service.policy_from_host(host)
    if not host then
      return nil
    end

    return copy_policy(host.pending_policy or {
      request_core = host.request_core == true,
    })
  end

  local function assign_element_rank(state, slot, element_id)
    local evolution = deps.ensure_evolution_state(state)
    if not deps.element_by_id[element_id] or (slot ~= 1 and slot ~= 2) then
      return false
    end
    if evolution.elements[slot] == element_id then
      return false
    end
    if evolution.elements[slot] then
      return false, true
    end

    evolution.elements[slot] = element_id
    evolution.element_mastery[element_id] = evolution.element_mastery[element_id] or {}
    local mastery = evolution.element_mastery[element_id]
    mastery.rank = math.max(mastery.rank or 0, deps.element_free_rank)
    mastery.delivered = math.max(0, math.floor(tonumber(mastery.delivered) or 0))
    mastery.fuel = nil
    mastery.burn_remaining = nil
    return true
  end

  local function spend_target_ranks(state, definitions, ranks, available, target_ranks, infinite_targets)
    local changed = false
    local spent = 0
    target_ranks = type(target_ranks) == "table" and target_ranks or {}
    infinite_targets = type(infinite_targets) == "table" and infinite_targets or {}

    local function spend_pass(infinite_only)
      local spent_this_pass = false
      for _, definition in ipairs(definitions or {}) do
        local id = definition.id
        local finite_target = positive_rank(target_ranks[id])
        local infinite = infinite_targets[id] == true
        if (not infinite_only and finite_target > 0) or (infinite_only and infinite) then
          local rank = math.max(0, math.floor(tonumber(ranks[id]) or 0))
          local max_rank = definition.max_rank or math.huge
          local target_cap = infinite_only and max_rank or math.min(max_rank, finite_target)
          if rank < target_cap then
            ranks[id] = rank + 1
            available = available - 1
            spent = spent + 1
            changed = true
            spent_this_pass = true
            if available <= 0 then
              break
            end
          end
        end
      end
      return spent_this_pass
    end

    while available > 0 and spend_pass(false) do
    end
    while available > 0 and spend_pass(true) do
    end

    return changed, spent
  end

  local function target_satisfied(profile, target)
    target = normalize_target(target)
    if not target then
      return true
    end
    if has_infinite_targets(target) then
      return false
    end

    local evolution = deps.ensure_evolution_state(profile)
    local function ranks_satisfied(definitions, live_ranks, target_ranks)
      live_ranks = type(live_ranks) == "table" and live_ranks or {}
      target_ranks = type(target_ranks) == "table" and target_ranks or {}
      for _, definition in ipairs(definitions or {}) do
        local id = definition.id
        if positive_rank(live_ranks[id]) < positive_rank(target_ranks[id]) then
          return false
        end
      end
      return true
    end

    if not ranks_satisfied(deps.base_upgrades, evolution.base, target.base) then
      return false
    end
    if not ranks_satisfied(deps.augments, evolution.augments, target.augments) then
      return false
    end
    if target.specialization and evolution.specialization ~= target.specialization then
      return false
    end
    if target.sub_specialization and evolution.sub_specialization ~= target.sub_specialization then
      return false
    end
    for slot, element_id in ipairs(target.elements or {}) do
      if element_id and evolution.elements[slot] ~= element_id then
        return false
      end
    end

    return true
  end

  function service.target_unfinished(profile)
    local target = normalize_target(profile and profile.automation_target, false, profile)
    return target ~= nil and target_satisfied(profile, target) == false
  end

  local function apply_target_to_profile(entity, profile, target)
    target = normalize_target(target)
    if not target then
      return { changed = false, conflict = false, spent = 0, satisfied = true }
    end

    local changed = false
    local conflict = false
    local spent = 0
    local evolution = deps.ensure_evolution_state(profile)

    if target.specialization and deps.has_level(profile, deps.gates.specialization) then
      if not evolution.specialization then
        evolution.specialization = target.specialization
        evolution.sub_specialization = nil
        changed = true
        deps.mark_turret_body_sync_pending(profile)
      elseif evolution.specialization ~= target.specialization then
        conflict = true
      end
    end

    if target.sub_specialization and deps.has_level(profile, deps.gates.sub_specialization) then
      local sub = deps.sub_specialization_by_id[target.sub_specialization]
      if sub and evolution.specialization == sub.parent then
        if not evolution.sub_specialization then
          evolution.sub_specialization = target.sub_specialization
          changed = true
          deps.mark_turret_body_sync_pending(profile)
        elseif evolution.sub_specialization ~= target.sub_specialization then
          conflict = true
        end
      end
    end

    local base_changed, base_spent = spend_target_ranks(
      profile,
      deps.base_upgrades,
      evolution.base,
      deps.get_available_skill_points(profile),
      target.base,
      target.base_infinite
    )
    changed = changed or base_changed
    spent = spent + base_spent

    if deps.has_level(profile, deps.gates.augments) then
      local augment_changed, augment_spent = spend_target_ranks(
        profile,
        deps.augments,
        evolution.augments,
        deps.get_available_augment_points(profile),
        target.augments,
        target.augment_infinite
      )
      changed = changed or augment_changed
      spent = spent + augment_spent
    end

    for slot, element_id in ipairs(target.elements or {}) do
      local gate = slot == 1 and deps.gates.first_element or deps.gates.second_element
      if deps.has_level(profile, gate) and (slot == 1 or evolution.elements[1]) then
        local element_changed, element_conflict = assign_element_rank(profile, slot, element_id)
        changed = changed or element_changed
        conflict = conflict or element_conflict == true
      end
    end

    if changed then
      deps.normalize_shield_state(profile, false)
      deps.sync_turret_progression(profile)
      if deps.is_gun_turret(entity) then
        deps.ensure_feeder(entity, profile)
        deps.update_name_render(entity, profile)
        deps.update_shield_bar_render(entity, profile, false)
      end
    end

    return {
      changed = changed,
      conflict = conflict,
      spent = spent,
      satisfied = target_satisfied(profile, target),
    }
  end

  function service.apply_to_profile(entity, profile, options)
    profile = service.normalize_profile(profile)
    options = options or {}
    if not profile or (profile.automation_enabled ~= true and options.force ~= true) then
      return { changed = false, conflict = false, spent = 0 }
    end

    if profile.automation_target then
      local target_result = apply_target_to_profile(entity, profile, profile.automation_target)
      profile.automation_conflict = target_result.conflict == true
      profile.automation_last_spent = target_result.spent or 0
      if profile.automation_enabled == true and target_result.satisfied == true then
        profile.automation_enabled = false
      end
      service.reconcile_profile_target(profile)
      return target_result
    end

    return { changed = false, conflict = false, spent = 0 }
  end

  function service.apply_policy_to_profile(entity, profile, policy)
    if not profile or type(policy) ~= "table" then
      return false
    end

    local visual_changed = false
    local target = normalize_target(policy.automation_target)
    if target then
      profile.automation_target = target
      profile.automation_enabled = policy.automation_enabled ~= false
      profile.build_mode = false
    else
      profile.automation_target = nil
      profile.automation_enabled = false
    end
    if policy.show_name_label ~= nil then
      profile.show_name_label = policy.show_name_label == true
      visual_changed = true
    end
    if policy.show_label_level ~= nil then
      profile.show_label_level = policy.show_label_level == true
      visual_changed = true
    end
    if policy.show_unspent_label ~= nil then
      profile.show_unspent_label = policy.show_unspent_label == true
      visual_changed = true
    end
    if type(policy.label_color) == "table" then
      profile.label_color = { policy.label_color[1], policy.label_color[2], policy.label_color[3] }
      profile.label_color_preset = policy.label_color_preset or "custom"
      visual_changed = true
    end
    if policy.bound_turret ~= nil then
      profile.bound_turret = policy.bound_turret == true
    end

    service.apply_to_profile(entity, profile, { force = profile.automation_enabled == true })
    if visual_changed and deps.is_gun_turret(entity) then
      deps.normalize_profile(profile)
      deps.update_name_render(entity, profile)
    end
    return true
  end

  function service.apply_pending_policy(entity, profile, host)
    if not host or type(host.pending_policy) ~= "table" then
      return false
    end

    local policy = copy_policy(host.pending_policy)
    host.pending_policy = nil
    return service.apply_policy_to_profile(entity, profile, policy)
  end

  function service.apply_policy_to_host(entity, policy)
    if not deps.is_gun_turret(entity) or type(policy) ~= "table" then
      return false
    end

    local host = deps.get_turret_host(entity, true)
    local profile = deps.get_turret_state(entity)
    if profile then
      return service.apply_policy_to_profile(entity, profile, policy)
    end

    host.pending_policy = copy_policy(policy)
    host.request_core = policy.request_core == true
    if deps.core_requester and host.request_core then
      deps.core_requester.ensure(entity)
    end
    return true
  end

  return service
end

return profile_automation
