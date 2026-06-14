return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M
  local DEFAULT_CORE_PICKER_SORT = "level:desc"

  function ensure_storage()
    storage.turret_xp = storage.turret_xp or {}
    storage.turret_xp.turrets = storage.turret_xp.turrets or {}
    storage.turret_xp.chips = storage.turret_xp.chips or {}
    storage.turret_xp.next_chip_id = storage.turret_xp.next_chip_id or 1
    storage.turret_xp.players = storage.turret_xp.players or {}
    storage.turret_xp.player_settings = storage.turret_xp.player_settings or {}
    storage.turret_xp.targets = storage.turret_xp.targets or {}
    storage.turret_xp.feeders = storage.turret_xp.feeders or {}
    storage.turret_xp.feeder_refresh = storage.turret_xp.feeder_refresh or {}
    storage.turret_xp.managed_inserters = storage.turret_xp.managed_inserters or {}
    storage.turret_xp.pending_bound_mined = storage.turret_xp.pending_bound_mined or {}
    storage.turret_xp.pending_visuals = storage.turret_xp.pending_visuals or {}
    storage.turret_xp.visual_entities = storage.turret_xp.visual_entities or {}
    storage.turret_xp.status_effects = storage.turret_xp.status_effects or {}
    storage.turret_xp.combat_effect_budget = storage.turret_xp.combat_effect_budget or {}
  end

  function ensure_player_settings(player)
    ensure_storage()
    local settings_table = storage.turret_xp.player_settings[player.index]
    if type(settings_table) ~= "table" then
      settings_table = {}
      storage.turret_xp.player_settings[player.index] = settings_table
    end

    return settings_table
  end

  function dev_controls_enabled(player)
    return player and ensure_player_settings(player).dev_controls == true
  end

  function compat_diagnostics_enabled()
    if script.active_mods["turret_xp_headless_tests"] then
      return true
    end

    if not storage or not storage.turret_xp or not storage.turret_xp.player_settings then
      return false
    end

    for _, settings_table in pairs(storage.turret_xp.player_settings) do
      if type(settings_table) == "table" and settings_table.dev_controls == true then
        return true
      end
    end

    return false
  end

  function unlock_core_recipes_for_existing_tech()
    if not game or not game.forces then
      return
    end

    for _, force in pairs(game.forces) do
      local recipe = force.recipes[CHIP_NAME]
      if recipe then
        local technology = force.technologies["military"]
        if not technology or technology.researched then
          recipe.enabled = true
        end
      end
    end
  end

  function ensure_player_state(player)
    ensure_storage()
    local player_state = storage.turret_xp.players[player.index]
    if type(player_state) ~= "table" then
      player_state = {}
      storage.turret_xp.players[player.index] = player_state
    end

    return player_state
  end

  function normalize_core_picker_sort(sort_mode)
    local mode = tostring(sort_mode or "")
    if mode == "none" or mode == "" then
      return "none"
    end

    local field, direction = string.match(mode, "^([^:]+):([^:]+)$")
    field = field or mode
    if field ~= "level" and field ~= "name" and field ~= "specialization" and field ~= "hp" and field ~= "attack" and field ~= "range" then
      return "none"
    end

    if direction ~= "asc" and direction ~= "desc" then
      direction = (field == "name" or field == "specialization") and "asc" or "desc"
    end

    return field .. ":" .. direction
  end

  function default_core_picker_sort_direction(field)
    return (field == "name" or field == "specialization") and "asc" or "desc"
  end

  function next_core_picker_sort(current_sort, field)
    field = tostring(field or "")
    if field ~= "level" and field ~= "name" and field ~= "specialization" and field ~= "hp" and field ~= "attack" and field ~= "range" then
      return "none"
    end

    local current = normalize_core_picker_sort(current_sort)
    local current_field, current_direction = string.match(current, "^([^:]+):([^:]+)$")
    local default_direction = default_core_picker_sort_direction(field)
    if current_field ~= field then
      return field .. ":" .. default_direction
    end

    if current_direction == default_direction then
      return field .. ":" .. (default_direction == "asc" and "desc" or "asc")
    end

    return "none"
  end

  function get_core_picker_sort(player)
    local settings_table = ensure_player_settings(player)
    local player_state = ensure_player_state(player)
    if settings_table.core_picker_sort == nil and player_state.core_picker_sort ~= nil then
      settings_table.core_picker_sort = player_state.core_picker_sort
      player_state.core_picker_sort = nil
    end

    local sort = normalize_core_picker_sort(settings_table.core_picker_sort or DEFAULT_CORE_PICKER_SORT)
    if sort == "none" then
      return DEFAULT_CORE_PICKER_SORT
    end
    return sort
  end

  function set_core_picker_sort(player, sort_field)
    local settings_table = ensure_player_settings(player)
    local current_sort = normalize_core_picker_sort(settings_table.core_picker_sort or DEFAULT_CORE_PICKER_SORT)
    if current_sort == "none" then
      current_sort = DEFAULT_CORE_PICKER_SORT
    end
    settings_table.core_picker_sort = next_core_picker_sort(current_sort, sort_field)
    return settings_table.core_picker_sort
  end

  local function core_picker_filter_is_known(filter_id)
    if filter_id == "all" then
      return true
    end

    if filter_id == "base" then
      return true
    end

    return SPECIALIZATION_BY_ID[filter_id] ~= nil
  end

  local function core_picker_default_filters()
    local filters = {
      all = true,
      base = false,
    }
    for _, specialization in ipairs(SPECIALIZATIONS) do
      filters[specialization.id] = false
    end
    return filters
  end

  local function core_picker_filter_categories()
    local categories = { "base" }
    for _, specialization in ipairs(SPECIALIZATIONS) do
      categories[#categories + 1] = specialization.id
    end
    return categories
  end

  function normalize_core_picker_filters(filters)
    if type(filters) ~= "table" then
      return core_picker_default_filters()
    end

    local normalized = {
      all = filters.all == true,
      base = filters.base == true,
    }
    local any_enabled = normalized.base
    local legacy_all_enabled = filters.base ~= false
    for _, specialization in ipairs(SPECIALIZATIONS) do
      local enabled = filters[specialization.id] == true
      normalized[specialization.id] = enabled
      any_enabled = any_enabled or enabled
      legacy_all_enabled = legacy_all_enabled and filters[specialization.id] ~= false
    end

    if filters.all == true or (filters.all == nil and legacy_all_enabled) or not any_enabled then
      return core_picker_default_filters()
    end

    return normalized
  end

  function core_picker_filters_key(filters)
    local normalized = normalize_core_picker_filters(filters)
    local parts = {
      "all=" .. tostring(normalized.all == true),
      "base=" .. tostring(normalized.base == true),
    }
    for _, specialization in ipairs(SPECIALIZATIONS) do
      parts[#parts + 1] = specialization.id .. "=" .. tostring(normalized[specialization.id] == true)
    end
    return table.concat(parts, ";")
  end

  function get_core_picker_filters(player)
    local settings_table = ensure_player_settings(player)
    local player_state = ensure_player_state(player)
    if settings_table.core_picker_filters == nil and player_state.core_picker_filters ~= nil then
      settings_table.core_picker_filters = player_state.core_picker_filters
      player_state.core_picker_filters = nil
    end

    return normalize_core_picker_filters(settings_table.core_picker_filters)
  end

  function set_core_picker_filter(player, filter_id, enabled)
    local settings_table = ensure_player_settings(player)
    local filters = normalize_core_picker_filters(settings_table.core_picker_filters)

    if filter_id == "all" then
      settings_table.core_picker_filters = core_picker_default_filters()
      return settings_table.core_picker_filters
    end

    if core_picker_filter_is_known(filter_id) then
      if filters.all == true then
        filters = {
          all = false,
        }
        for _, category in ipairs(core_picker_filter_categories()) do
          filters[category] = false
        end
      end
      filters.all = false
      filters[filter_id] = enabled == true
    end
    settings_table.core_picker_filters = normalize_core_picker_filters(filters)
    return settings_table.core_picker_filters
  end

  function is_gun_turret(entity)
    return entity and entity.valid and (entity.name == BASE_TURRET_NAME or DOMAIN.is_specialized_turret_name(entity.name))
  end

  function is_bound_turret_item_name(name)
    return DOMAIN.is_bound_turret_item_name(name)
  end

  function is_bound_turret_placeholder(entity)
    local name = entity and entity.valid and entity.name or nil
    return DOMAIN.is_bound_turret_placeholder_name(name)
  end

  function get_sub_specialization_variant_segment(specialization_id, sub_specialization_id)
    return DOMAIN.get_sub_specialization_variant_segment(specialization_id, sub_specialization_id)
  end

  function get_specialized_turret_name(specialization_id, range_rank, health_rank, sub_specialization_id)
    return DOMAIN.specialized_turret_name(specialization_id, range_rank, health_rank, sub_specialization_id)
  end

  function get_bound_turret_variant_id(specialization_id, range_rank, sub_specialization_id)
    return DOMAIN.bound_turret_variant_id(specialization_id, range_rank, sub_specialization_id)
  end

  function get_bound_turret_item_name(profile)
    local evolution = profile and ensure_evolution_state(profile) or nil
    local variant_id = evolution and get_bound_turret_variant_id(evolution.specialization, 0, evolution.sub_specialization) or nil
    local name = DOMAIN.bound_turret_item_name(variant_id)
    if name ~= BOUND_TURRET_NAME and prototypes and prototypes.item and not prototypes.item[name] then
      return BOUND_TURRET_NAME
    end

    return name
  end

  function combat.for_each_specialized_turret_name(callback)
    DOMAIN.for_each_specialized_turret_name(callback)
  end

  function combat.entity_prototype_exists(name)
    return compat.prototype_exists(prototypes.entity, name, "entity prototype")
  end

  function combat.sync_force_turret_attack_modifiers(force)
    if not force or not force.valid then
      return
    end

    local base_modifier = compat.try("read base turret attack modifier", function()
      return force.get_turret_attack_modifier(BASE_TURRET_NAME)
    end)
    if base_modifier == nil then
      return
    end

    combat.for_each_specialized_turret_name(function(variant_name)
      if combat.entity_prototype_exists(variant_name) then
        compat.try("sync turret attack modifier", function()
          force.set_turret_attack_modifier(variant_name, base_modifier or 0)
        end)
      end
    end)
  end

  function combat.sync_all_turret_attack_modifiers()
    if not game or not game.forces then
      return
    end

    for _, force in pairs(game.forces) do
      combat.sync_force_turret_attack_modifiers(force)
    end
  end

  function turret_key(entity)
    if entity.unit_number then
      return tostring(entity.unit_number)
    end

    return table.concat({
      tostring(entity.surface.index),
      string.format("%.2f", entity.position.x),
      string.format("%.2f", entity.position.y),
    }, ":")
  end

  function entity_tracking_key(entity)
    if not entity or not entity.valid then
      return nil
    end

    if entity.unit_number then
      return tostring(entity.unit_number)
    end

    return table.concat({
      tostring(entity.surface.index),
      entity.name,
      string.format("%.2f", entity.position.x),
      string.format("%.2f", entity.position.y),
    }, ":")
  end

  function combat.get_entity_xp_context(entity)
    if not entity then
      return nil
    end

    local valid = safe_read(entity, "valid")
    if valid == false then
      return nil
    end

    local force = safe_read(entity, "force")
    return {
      name = safe_read(entity, "name"),
      type = safe_read(entity, "type"),
      max_health = safe_read(entity, "max_health"),
      force_name = force and safe_read(force, "name") or safe_read(entity, "force_name"),
    }
  end

  function combat.target_kill_credit_multiplier(context)
    if not context then
      return 1
    end

    local entity_type = context.type
    local entity_name = context.name or ""
    local max_health = tonumber(context.max_health) or 0

    if entity_type == "asteroid" or entity_type == "asteroid-chunk" then
      return COMBAT_CONSTANTS.asteroid_xp_multiplier
    end

    if entity_type == "unit" then
      if max_health <= 25 then
        return 0.25
      elseif max_health <= 100 then
        return 0.5
      elseif max_health <= 400 then
        return 1
      elseif max_health <= 1000 then
        return 1.5
      end

      return 2.5
    end

    if entity_type == "unit-spawner" then
      return 4
    end

    if entity_type == "turret" and string.find(entity_name, "worm%-turret") then
      return 2
    end

    if context.force_name == "enemy" then
      return 0.5
    end

    return 0.25
  end

  function combat.target_damage_xp_multiplier(context)
    if not context then
      return 1
    end

    local entity_type = context.type
    local entity_name = context.name or ""

    if entity_type == "asteroid" or entity_type == "asteroid-chunk" then
      return COMBAT_CONSTANTS.asteroid_xp_multiplier
    end

    if entity_type == "unit-spawner" then
      return 0.5
    end

    if entity_type == "turret" and string.find(entity_name, "worm%-turret") then
      return 0.75
    end

    if entity_type == "unit" then
      return 1
    end

    if context.force_name == "enemy" then
      return 0.5
    end

    return 0.25
  end

  function get_setting(name, fallback)
    local setting = settings.global[name]
    if setting == nil or setting.value == nil then
      return fallback
    end

    return setting.value
  end
end
