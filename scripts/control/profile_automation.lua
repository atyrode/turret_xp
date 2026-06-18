local profile_automation = {}

local PRESETS = {
  {
    id = "manual",
    locale = "turret-xp.automation-preset-manual",
    base = {},
    augments = {},
  },
  {
    id = "balanced",
    locale = "turret-xp.automation-preset-balanced",
    base = { "damage", "shield", "ammo_regen", "resistance", "crit_chance", "crit_damage" },
    augments = { "repair", "siphon", "luck", "veteran_training", "double_shot", "bounce" },
    elements = { "explosive", "electric" },
  },
  {
    id = "sniper",
    locale = "turret-xp.automation-preset-sniper",
    specialization = "sniper",
    sub_specialization = "sniper_deadeye",
    base = { "damage", "crit_damage", "crit_chance", "shield", "resistance", "ammo_regen" },
    augments = { "luck", "veteran_training", "double_shot", "repair", "siphon", "bounce" },
    elements = { "explosive", "fire" },
  },
  {
    id = "machine_gun",
    locale = "turret-xp.automation-preset-machine-gun",
    specialization = "machine_gun",
    sub_specialization = "machine_sustained",
    base = { "ammo_regen", "damage", "crit_chance", "shield", "resistance", "crit_damage" },
    augments = { "double_shot", "bounce", "luck", "veteran_training", "repair", "siphon" },
    elements = { "electric", "toxic" },
  },
  {
    id = "bulwark",
    locale = "turret-xp.automation-preset-bulwark",
    specialization = "bulwark",
    sub_specialization = "bulwark_bastion",
    base = { "shield", "resistance", "damage", "ammo_regen", "crit_chance", "crit_damage" },
    augments = { "repair", "siphon", "veteran_training", "luck", "double_shot", "bounce" },
    elements = { "electric", "fire" },
  },
  {
    id = "brawler",
    locale = "turret-xp.automation-preset-brawler",
    specialization = "brawler",
    sub_specialization = "brawler_vampire",
    base = { "damage", "shield", "resistance", "crit_chance", "crit_damage", "ammo_regen" },
    augments = { "repair", "siphon", "double_shot", "luck", "veteran_training", "bounce" },
    elements = { "toxic", "fire" },
  },
}

local PRESET_BY_ID = {}
for index, preset in ipairs(PRESETS) do
  preset.index = index
  PRESET_BY_ID[preset.id] = preset
end

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
    automation_preset = policy.automation_preset,
    automation_enabled = policy.automation_enabled == true,
    automation_target = copy_serializable(policy.automation_target),
    show_name_label = policy.show_name_label == true,
    show_label_level = policy.show_label_level == true,
    show_unspent_label = policy.show_unspent_label == true,
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
        positive_rank(target.level) > 0
        or table_has_content(target.base)
        or table_has_content(target.augments)
        or table_has_content(target.elements)
        or target.specialization ~= nil
        or target.sub_specialization ~= nil
      )
  end

  local function normalize_target(target)
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
      augments = copy_rank_targets(target.augments, augment_by_id),
      elements = elements,
      element_mastery = copy_element_rank_targets(target.element_mastery, elements),
      specialization = specialization,
      sub_specialization = sub_specialization,
    }

    return target_has_content(normalized) and normalized or nil
  end

  local function target_from_profile(profile)
    profile = deps.normalize_profile(profile)
    local evolution = deps.ensure_evolution_state(profile)
    return normalize_target({
      level = profile.level or 0,
      base = evolution.base or {},
      augments = evolution.augments or {},
      elements = evolution.elements or {},
      element_mastery = evolution.element_mastery or {},
      specialization = evolution.specialization,
      sub_specialization = evolution.sub_specialization,
    })
  end

  function service.presets()
    return PRESETS
  end

  function service.preset_by_id(id)
    return PRESET_BY_ID[id] or PRESET_BY_ID.manual
  end

  function service.preset_index(id)
    return service.preset_by_id(id).index
  end

  function service.preset_id_by_index(index)
    index = math.max(1, math.floor(tonumber(index) or 1))
    return (PRESETS[index] or PRESETS[1]).id
  end

  function service.normalize_profile(profile)
    if not profile then
      return nil
    end

    if not PRESET_BY_ID[profile.automation_preset] then
      profile.automation_preset = "manual"
    end
    profile.automation_target = normalize_target(profile.automation_target)
    profile.automation_enabled = profile.automation_enabled == true
      and (profile.automation_preset ~= "manual" or profile.automation_target ~= nil)
    return profile
  end

  function service.target_from_profile(profile)
    return target_from_profile(profile)
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
    local target = normalize_target(profile and profile.automation_target)
    if not target then
      return nil
    end

    local core = rank_list(deps.base_upgrades, target.base)
    local augments = rank_list(deps.augments, target.augments)
    local choice = target_choice_name(target)
    local elements = target_elements_name(target)
    local tooltip = { "turret-xp.automation-target-tooltip-header" }

    if choice and choice ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.automation-target-tooltip-specialization", choice } }
    end
    if elements and elements ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.automation-target-tooltip-elements", elements } }
    end
    if core and core ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.automation-target-tooltip-core", core } }
    end
    if augments and augments ~= "" then
      tooltip = { "", tooltip, "\n", { "turret-xp.automation-target-tooltip-augments", augments } }
    end

    return {
      level = target.level or 0,
      choice = choice,
      elements = elements,
      core = core,
      augments = augments,
      tooltip = tooltip,
    }
  end

  function service.policy_from_profile(profile)
    profile = service.normalize_profile(deps.normalize_profile(profile))
    local target = target_from_profile(profile)
    return copy_policy({
      automation_preset = profile.automation_preset or "manual",
      automation_enabled = profile.automation_enabled == true or target ~= nil,
      automation_target = target,
      show_name_label = profile.show_name_label == true,
      show_label_level = profile.show_label_level == true,
      show_unspent_label = profile.show_unspent_label == true,
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

  local function spend_rank(state, definitions, ranks, available, ids, target_ranks)
    local changed = false
    local spent = 0
    local by_id = {}
    for _, definition in ipairs(definitions or {}) do
      by_id[definition.id] = definition
    end

    while available > 0 do
      local spent_this_pass = false
      for _, id in ipairs(ids or {}) do
        local definition = by_id[id]
        if definition then
          local rank = math.max(0, math.floor(tonumber(ranks[id]) or 0))
          local max_rank = definition.max_rank or math.huge
          if target_ranks then
            max_rank = math.min(max_rank, positive_rank(target_ranks[id]))
          end
          if rank < max_rank then
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
      if not spent_this_pass then
        break
      end
    end

    return changed, spent
  end

  local function target_rank_ids(definitions, ranks)
    local ids = {}
    ranks = type(ranks) == "table" and ranks or {}
    for _, definition in ipairs(definitions or {}) do
      if positive_rank(ranks[definition.id]) > 0 then
        ids[#ids + 1] = definition.id
      end
    end
    return ids
  end

  local function apply_target_to_profile(entity, profile, target)
    target = normalize_target(target)
    if not target then
      return { changed = false, conflict = false, spent = 0 }
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

    local base_ids = target_rank_ids(deps.base_upgrades, target.base)
    local base_changed, base_spent =
      spend_rank(profile, deps.base_upgrades, evolution.base, deps.get_available_skill_points(profile), base_ids, target.base)
    changed = changed or base_changed
    spent = spent + base_spent

    if deps.has_level(profile, deps.gates.augments) then
      local augment_ids = target_rank_ids(deps.augments, target.augments)
      local augment_changed, augment_spent =
        spend_rank(profile, deps.augments, evolution.augments, deps.get_available_augment_points(profile), augment_ids, target.augments)
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
      return target_result
    end

    local preset = service.preset_by_id(profile.automation_preset)
    if preset.id == "manual" then
      return { changed = false, conflict = false, spent = 0 }
    end

    local changed = false
    local conflict = false
    local spent = 0
    local evolution = deps.ensure_evolution_state(profile)

    if preset.specialization and deps.has_level(profile, deps.gates.specialization) then
      if not evolution.specialization then
        evolution.specialization = preset.specialization
        evolution.sub_specialization = nil
        changed = true
        deps.mark_turret_body_sync_pending(profile)
      elseif evolution.specialization ~= preset.specialization then
        conflict = true
      end
    end

    if preset.sub_specialization and deps.has_level(profile, deps.gates.sub_specialization) then
      local sub = deps.sub_specialization_by_id[preset.sub_specialization]
      if sub and evolution.specialization == sub.parent then
        if not evolution.sub_specialization then
          evolution.sub_specialization = preset.sub_specialization
          changed = true
          deps.mark_turret_body_sync_pending(profile)
        elseif evolution.sub_specialization ~= preset.sub_specialization then
          conflict = true
        end
      end
    end

    local base_changed, base_spent =
      spend_rank(profile, deps.base_upgrades, evolution.base, deps.get_available_skill_points(profile), preset.base)
    changed = changed or base_changed
    spent = spent + base_spent

    if deps.has_level(profile, deps.gates.augments) then
      local augment_changed, augment_spent =
        spend_rank(profile, deps.augments, evolution.augments, deps.get_available_augment_points(profile), preset.augments)
      changed = changed or augment_changed
      spent = spent + augment_spent
    end

    for slot, element_id in ipairs(preset.elements or {}) do
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

    profile.automation_conflict = conflict == true
    profile.automation_last_spent = spent
    return {
      changed = changed,
      conflict = conflict,
      spent = spent,
    }
  end

  function service.apply_policy_to_profile(entity, profile, policy)
    if not profile or type(policy) ~= "table" then
      return false
    end

    local visual_changed = false
    if policy.automation_preset and PRESET_BY_ID[policy.automation_preset] then
      profile.automation_preset = policy.automation_preset
    end
    local target = normalize_target(policy.automation_target)
    if target then
      profile.automation_target = target
      profile.automation_enabled = policy.automation_enabled ~= false
    else
      profile.automation_target = nil
      profile.automation_enabled = policy.automation_enabled == true and profile.automation_preset ~= "manual"
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
