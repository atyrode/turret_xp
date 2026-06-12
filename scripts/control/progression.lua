local legacy_migrations = require("scripts.control.migrations")

return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  local legacy_migration_service = nil

  local function get_legacy_migration_service()
    if not legacy_migration_service then
      legacy_migration_service = legacy_migrations.new({
        element_by_id = ELEMENT_BY_ID,
        element_free_rank = ELEMENT_FREE_RANK,
        get_element_requirements = get_element_requirements,
        advance_element_mastery_if_ready = advance_element_mastery_if_ready,
      })
    end

    return legacy_migration_service
  end

  function get_xp_settings()
    return {
      xp_per_damage = math.max(0, get_setting(SETTINGS.xp_per_damage, DEFAULTS.xp_per_damage)),
      xp_per_kill_credit = math.max(0, get_setting(SETTINGS.xp_per_kill_credit, DEFAULTS.xp_per_kill_credit)),
      level_base_xp = math.max(1, get_setting(SETTINGS.level_base_xp, DEFAULTS.level_base_xp)),
      level_growth = math.max(1.01, get_setting(SETTINGS.level_growth, DEFAULTS.level_growth)),
    }
  end

  function ensure_xp_counters(state)
    if not state then
      return
    end

    state.damage = state.damage or 0
    state.kill_credit = state.kill_credit or state.kills or 0
    if state.xp_damage == nil then
      state.xp_damage = state.damage
    end
    if state.xp_kill_credit == nil then
      state.xp_kill_credit = state.kill_credit
    end
  end

  function combat.get_surface_combat_xp_multiplier(turret)
    local surface = turret and turret.valid and safe_read(turret, "surface") or nil
    local platform = surface and safe_read(surface, "platform") or nil
    return platform and COMBAT_CONSTANTS.space_xp_multiplier or 1
  end

  function get_combat_xp_multiplier(turret, target_context, channel)
    local context = combat.get_entity_xp_context(target_context) or target_context
    local target_multiplier = channel == "kill" and combat.target_kill_credit_multiplier(context)
      or combat.target_damage_xp_multiplier(context)

    return combat.get_surface_combat_xp_multiplier(turret) * target_multiplier
  end

  function add_profile_damage(state, amount, turret, target_context)
    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0 then
      return
    end

    ensure_xp_counters(state)
    state.damage = (state.damage or 0) + amount
    state.xp_damage = (state.xp_damage or 0) + (amount * get_combat_xp_multiplier(turret, target_context, "damage"))
  end

  function add_profile_kill_credit(state, credit, turret, target_context)
    credit = math.max(0, tonumber(credit) or 0)
    if credit <= 0 then
      return
    end

    ensure_xp_counters(state)
    state.kill_credit = (state.kill_credit or state.kills or 0) + credit
    state.xp_kill_credit = (state.xp_kill_credit or 0) + (credit * get_combat_xp_multiplier(turret, target_context, "kill"))
  end

  function get_element_requirement_count(element, next_rank)
    next_rank = math.max(1, math.floor(tonumber(next_rank) or 1))
    if next_rank <= ELEMENT_FREE_RANK then
      return 0
    end

    local paid_rank = next_rank - ELEMENT_FREE_RANK
    return math.max(1, math.floor((element.base_requirement or 100) * (paid_rank ^ 1.45) + 0.5))
  end

  function get_element_requirements(element, next_rank)
    if not element then
      return {}
    end

    local count = get_element_requirement_count(element, next_rank)
    if count <= 0 then
      return {}
    end

    return {
      {
        name = element.resource,
        count = count,
      },
    }
  end

  function ensure_evolution_state(state)
    state.evolution = state.evolution or {}
    local evolution = state.evolution
    evolution.base = evolution.base or {}
    evolution.augments = evolution.augments or {}
    evolution.elements = evolution.elements or {}
    evolution.element_mastery = evolution.element_mastery or {}
    local migrations = get_legacy_migration_service()
    migrations.normalize_legacy_element_slots(evolution)
    migrations.migrate_moved_base_upgrades(evolution)
    migrations.migrate_legacy_base_xp_upgrade(evolution)

    for _, upgrade in ipairs(BASE_UPGRADES) do
      evolution.base[upgrade.id] = math.max(0, math.floor(tonumber(evolution.base[upgrade.id]) or 0))
      if upgrade.max_rank then
        evolution.base[upgrade.id] = math.min(upgrade.max_rank, evolution.base[upgrade.id])
      end
    end

    for _, augment in ipairs(AUGMENTS) do
      evolution.augments[augment.id] = math.max(0, math.floor(tonumber(evolution.augments[augment.id]) or 0))
      if augment.max_rank then
        evolution.augments[augment.id] = math.min(augment.max_rank, evolution.augments[augment.id])
      end
    end
    migrations.remove_retired_augments(evolution)

    if evolution.specialization and not SPECIALIZATION_BY_ID[evolution.specialization] then
      evolution.specialization = nil
    end
    if evolution.sub_specialization then
      local sub_specialization = SUB_SPECIALIZATION_BY_ID[evolution.sub_specialization]
      if not sub_specialization or sub_specialization.parent ~= evolution.specialization then
        evolution.sub_specialization = nil
      end
    end

    for slot = 1, 2 do
      local element_id = evolution.elements[slot]
      if element_id and not ELEMENT_BY_ID[element_id] then
        evolution.elements[slot] = nil
      end
    end

    for _, element in ipairs(ELEMENTS) do
      local mastery = evolution.element_mastery[element.id]
      if type(mastery) ~= "table" then
        mastery = {
          rank = 0,
          delivered = 0,
        }
        evolution.element_mastery[element.id] = mastery
      end
      mastery.rank = math.max(0, math.floor(tonumber(mastery.rank) or 0))
      mastery.delivered = math.max(0, math.floor(tonumber(mastery.delivered) or 0))
      migrations.normalize_legacy_element_mastery(mastery)
    end

    migrations.migrate_legacy_element_project(state, evolution)
    migrations.migrate_legacy_skills(state, evolution)
    migrations.migrate_legacy_base_xp_upgrade(evolution)

    return evolution
  end

  function get_base_rank(state, upgrade_id)
    if not state then
      return 0
    end

    local evolution = ensure_evolution_state(state)
    return evolution.base[upgrade_id] or 0
  end

  function get_shield_capacity(state)
    return get_base_rank(state, "shield") * SHIELD_PER_RANK
  end

  function normalize_shield_state(state, fill_if_missing)
    if not state then
      return 0, 0
    end

    local capacity = get_shield_capacity(state)
    if capacity <= 0 then
      state.shield = 0
      return 0, 0
    end

    local current = tonumber(state.shield)
    if current == nil then
      current = fill_if_missing ~= false and capacity or 0
    end

    state.shield = math.max(0, math.min(capacity, current))
    return state.shield, capacity
  end

  function get_shield_recharge_per_second(state)
    local capacity = get_shield_capacity(state)
    if capacity <= 0 then
      return 0
    end

    return math.max(1, capacity * SHIELD_RECHARGE_FRACTION_PER_SECOND)
  end

  function get_augment_rank(state, augment_id)
    if not state then
      return 0
    end

    local evolution = ensure_evolution_state(state)
    return evolution.augments[augment_id] or 0
  end

  function get_element_rank(state, element_id)
    if not state or not ELEMENT_BY_ID[element_id] then
      return 0
    end

    local mastery = ensure_evolution_state(state).element_mastery[element_id]
    return mastery and mastery.rank or 0
  end

  function get_unique_active_element_ids(state)
    local evolution = ensure_evolution_state(state)
    local unique = {}
    local seen = {}
    for slot = 1, 2 do
      local element_id = evolution.elements[slot]
      if element_id and ELEMENT_BY_ID[element_id] and not seen[element_id] then
        seen[element_id] = true
        unique[#unique + 1] = element_id
      end
    end
    return unique
  end

  function element_is_powered(state, element_id)
    if not state or not ELEMENT_BY_ID[element_id] then
      return false
    end

    local mastery = ensure_evolution_state(state).element_mastery[element_id]
    return mastery and (mastery.rank or 0) > 0
  end

  function get_element_next_rank(state, element_id)
    return get_element_rank(state, element_id) + 1
  end

  function get_element_progress(state, element_id)
    if not state or not ELEMENT_BY_ID[element_id] then
      return 0, 0, nil
    end

    local evolution = ensure_evolution_state(state)
    local mastery = evolution.element_mastery[element_id]
    if not mastery or (mastery.rank or 0) <= 0 then
      return 0, 0, nil
    end

    local next_rank = (mastery.rank or ELEMENT_FREE_RANK) + 1
    local requirements = get_element_requirements(ELEMENT_BY_ID[element_id], next_rank)
    local requirement = requirements[1]
    if not requirement then
      mastery.delivered = 0
      return 0, 0, nil
    end

    mastery.delivered = math.max(0, math.floor(tonumber(mastery.delivered) or 0))
    return math.min(mastery.delivered, requirement.count), requirement.count, requirement
  end

  function get_element_remaining_requirement(state, element_id)
    local delivered, required, requirement = get_element_progress(state, element_id)
    if not requirement then
      return nil
    end

    return {
      name = requirement.name,
      count = requirement.count,
      delivered = delivered,
      remaining = math.max(0, required - delivered),
    }
  end

  function advance_element_mastery_if_ready(state, element_id)
    if not state or not ELEMENT_BY_ID[element_id] then
      return false
    end

    local evolution = ensure_evolution_state(state)
    local mastery = evolution.element_mastery[element_id]
    if not mastery or (mastery.rank or 0) <= 0 then
      return false
    end

    local changed = false
    while true do
      local next_rank = (mastery.rank or ELEMENT_FREE_RANK) + 1
      local requirements = get_element_requirements(ELEMENT_BY_ID[element_id], next_rank)
      local requirement = requirements[1]
      if not requirement or requirement.count <= 0 then
        mastery.delivered = 0
        break
      end
      mastery.delivered = math.max(0, math.floor(tonumber(mastery.delivered) or 0))
      if mastery.delivered < requirement.count then
        break
      end

      mastery.delivered = mastery.delivered - requirement.count
      mastery.rank = (mastery.rank or ELEMENT_FREE_RANK) + 1
      changed = true
    end

    return changed
  end

  function add_element_material_progress(state, element_id, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 or not state or not ELEMENT_BY_ID[element_id] then
      return false
    end

    local evolution = ensure_evolution_state(state)
    local mastery = evolution.element_mastery[element_id]
    if not mastery or (mastery.rank or 0) <= 0 then
      return false
    end

    mastery.delivered = math.max(0, math.floor(tonumber(mastery.delivered) or 0)) + amount
    advance_element_mastery_if_ready(state, element_id)
    return true
  end

  function get_spent_core_points(state)
    if not state then
      return 0
    end

    local evolution = ensure_evolution_state(state)
    local spent = 0

    for _, upgrade in ipairs(BASE_UPGRADES) do
      spent = spent + (evolution.base[upgrade.id] or 0)
    end

    return spent
  end

  function get_spent_augment_points(state)
    if not state then
      return 0
    end

    local evolution = ensure_evolution_state(state)
    local spent = 0

    for _, augment in ipairs(AUGMENTS) do
      spent = spent + (evolution.augments[augment.id] or 0)
    end

    return spent
  end

  function get_available_skill_points(state)
    if not state then
      return 0
    end

    return math.max(0, (state.level or 0) - get_spent_core_points(state))
  end

  function get_total_augment_points(state)
    if not state or (state.level or 0) < GATES.augments then
      return 0
    end

    return 1 + math.floor(((state.level or 0) - GATES.augments) / 10)
  end

  function get_available_augment_points(state)
    return math.max(0, get_total_augment_points(state) - get_spent_augment_points(state))
  end

  function xp_required(level)
    local xp_settings = get_xp_settings()
    local growth_per_level = math.max(0.01, xp_settings.level_growth - 1)
    level = math.max(0, math.floor(tonumber(level) or 0))
    return math.max(1, math.floor((xp_settings.level_base_xp * (1 + (level * growth_per_level))) + 0.5))
  end

  function progression_from_total_xp(total_xp)
    local level = 0
    local remaining_xp = math.max(0, total_xp or 0)
    local required_xp = xp_required(level)

    while remaining_xp >= required_xp and level < 10000 do
      remaining_xp = remaining_xp - required_xp
      level = level + 1
      required_xp = xp_required(level)
    end

    return level, remaining_xp, required_xp
  end

  function show_level_up_flying_text(state, level)
    local entity = state and state.entity or nil
    if not entity or not entity.valid then
      return
    end

    local surface = entity.surface
    if not surface then
      return
    end

    local position = {
      entity.position.x,
      entity.position.y - 1.35,
    }

    for _, player in pairs(game.connected_players) do
      if player.valid and player.surface == surface and player.force == entity.force then
        player.create_local_flying_text({
          position = position,
          text = { "turret-xp.level-up-flying-text", level },
          color = { r = 1, g = 0.86, b = 0.36 },
          time_to_live = 120,
        })
      end
    end
  end

  function sync_turret_progression(state)
    state.kill_credit = state.kill_credit or state.kills or 0
    ensure_xp_counters(state)
    ensure_evolution_state(state)

    local xp_settings = get_xp_settings()
    local veteran_training_rank = get_augment_rank(state, "veteran_training")
    local combat_xp = ((state.xp_damage or state.damage or 0) * xp_settings.xp_per_damage)
      + ((state.xp_kill_credit or state.kill_credit or 0) * xp_settings.xp_per_kill_credit)
    local total_xp = (combat_xp * (1 + (veteran_training_rank * 0.05))) + (state.dev_xp or 0)
    local settings_key = tostring(xp_settings.xp_per_damage)
      .. ":"
      .. tostring(xp_settings.xp_per_kill_credit)
      .. ":"
      .. tostring(xp_settings.level_base_xp)
      .. ":"
      .. tostring(xp_settings.level_growth)
      .. ":"
      .. tostring(veteran_training_rank)
    local cached_total_xp = state._progress_total_xp
    local cached_level = state.level
    local level
    local xp
    local required

    if state._progress_settings_key == settings_key and cached_total_xp and total_xp >= cached_total_xp and state.level and state.xp then
      level = math.max(0, math.floor(tonumber(state.level) or 0))
      xp = math.max(0, (tonumber(state.xp) or 0) + (total_xp - cached_total_xp))
      required = math.max(1, math.floor(tonumber(state.required_xp) or xp_required(level)))

      while xp >= required and level < 10000 do
        xp = xp - required
        level = level + 1
        required = xp_required(level)
      end
    else
      level, xp, required = progression_from_total_xp(total_xp)
    end

    state.total_xp = total_xp
    state.level = level
    state.xp = xp
    state.required_xp = required
    state._progress_total_xp = total_xp
    state._progress_settings_key = settings_key

    if cached_total_xp and total_xp > cached_total_xp and cached_level and level > cached_level then
      show_level_up_flying_text(state, level)
    end

    return {
      total_xp = total_xp,
      level = level,
      xp = xp,
      required = required,
    }
  end
end
