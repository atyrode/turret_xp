local combat_application = require("scripts.control.combat_application")
local combat_budget = require("scripts.control.combat_budget")
local combat_dispatch = require("scripts.control.combat_dispatch")
local combat_effect_descriptors = require("scripts.control.combat_effect_descriptors")
local combat_scheduler = require("scripts.control.combat_scheduler")
local combat_targeting = require("scripts.control.combat_targeting")
local combat_visuals = require("scripts.control.combat_visuals")

local SHIELD_HEALTH_BAR_NUDGE = 0.01

local function copy_exports(target, source, names)
  for _, name in ipairs(names) do
    target[name] = source[name]
  end
end

return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  combat = combat or {}

  local function storage_root()
    return storage and storage.turret_xp or nil
  end

  local function ensured_storage_root()
    ensure_storage()
    return storage.turret_xp
  end

  local function game_tick()
    return game and game.tick or 0
  end

  local descriptors = combat_effect_descriptors.new(COMBAT_CONSTANTS)
  local effect_budget = combat_budget.new({
    ensure_storage = ensure_storage,
    get_storage = storage_root,
    get_tick = game_tick,
    get_limits = function()
      return COMBAT_CONSTANTS.effect_budget
    end,
  })

  function combat.get_effect_budget_snapshot()
    return effect_budget.snapshot()
  end

  function combat.reset_effect_budget()
    effect_budget.reset()
  end

  function combat.reserve_effect_budget(bucket_name, surface, cost)
    if bucket_name == "status_effect_ticks" then
      return effect_budget.reserve_global(bucket_name, cost)
    end

    return effect_budget.reserve_surface(surface, bucket_name, cost)
  end

  function combat.get_effect_descriptor_snapshot()
    return descriptors.snapshot()
  end

  local application = combat_application.new({
    compat = compat,
    feeder = feeder,
    inventory_defines = defines.inventory,
    safe_read = safe_read,
    is_gun_turret = is_gun_turret,
    get_loaded_ammo_snapshot = get_loaded_ammo_snapshot,
    get_base_rank = get_base_rank,
    get_effective_ammo_productivity_fraction = get_effective_ammo_productivity_fraction,
    get_shield_on_hit_fraction = get_shield_on_hit_fraction,
    normalize_shield_state = normalize_shield_state,
    update_shield_bar_render = update_shield_bar_render,
    get_damage_resistance_fraction = get_damage_resistance_fraction,
    shield_bar_visible_for_damage = shield_bar_visible_for_damage,
    get_shield_recharge_per_second = get_shield_recharge_per_second,
    shield_recharge_ticks = SHIELD_RECHARGE_TICKS,
    shield_recharge_delay_ticks = SHIELD_RECHARGE_DELAY_TICKS,
    shield_health_bar_nudge = SHIELD_HEALTH_BAR_NUDGE,
    game_tick = game_tick,
    ensure_storage = ensure_storage,
    storage_root = ensured_storage_root,
    get_turret_state = get_turret_state,
    turret_key = turret_key,
    entity_tracking_key = entity_tracking_key,
  })
  copy_exports(combat, application, {
    "remember_loaded_ammo",
    "insert_recovered_ammo",
    "add_productivity_ammo",
    "apply_ammo_productivity",
    "apply_ammo_regeneration",
    "apply_shield_on_hit",
    "apply_damage_resistance",
    "apply_shield_absorption",
    "recharge_shield",
    "apply_runtime_damage",
    "record_scripted_damage_contribution",
    "apply_tracked_runtime_damage",
    "heal_turret",
  })

  local targeting = combat_targeting.new({
    safe_read = safe_read,
    entity_tracking_key = entity_tracking_key,
    ensure_evolution_state = ensure_evolution_state,
  })
  copy_exports(combat, targeting, {
    "chance_roll",
    "get_distance",
    "find_nearby_enemy",
    "get_active_elements",
    "has_element_pair",
    "combo_descriptor_is_active",
  })

  local visuals = combat_visuals.new({
    combat_constants = COMBAT_CONSTANTS,
    effect_budget = effect_budget,
    safe_read = safe_read,
    ensure_storage = ensure_storage,
    storage_root = storage_root,
    game_tick = game_tick,
    get_surface = function(index)
      return game and game.get_surface(index) or nil
    end,
    game_surfaces = function()
      return game and game.surfaces or nil
    end,
    rendering = function()
      return rendering
    end,
    entity_prototypes = function()
      return prototypes and prototypes.entity or nil
    end,
  })
  copy_exports(combat, visuals, {
    "draw_attack_line",
    "has_entity_prototype",
    "track_visual_entity",
    "create_visual_entity",
    "draw_trail",
    "play_effect_sound",
    "copy_position",
    "offset_toward_perpendicular",
    "draw_readable_bullet_trail",
    "draw_double_shot_feedback",
    "draw_crit_feedback",
    "draw_bounce_feedback",
    "schedule_attack_line",
    "process_pending_visuals",
    "cleanup_visual_entities",
    "destroy_existing_visual_entities",
    "draw_effect_sprite",
    "create_short_effect",
  })

  local scheduler = combat_scheduler.new({
    effect_budget = effect_budget,
    safe_read = safe_read,
    ensure_storage = ensure_storage,
    storage_root = storage_root,
    is_gun_turret = is_gun_turret,
    game_tick = game_tick,
    force_by_name = function(name)
      return game and game.forces and game.forces[name] or nil
    end,
    get_entity_xp_context = function(entity)
      return combat.get_entity_xp_context(entity)
    end,
    apply_tracked_runtime_damage = function(...)
      return combat.apply_tracked_runtime_damage(...)
    end,
    add_profile_damage = add_profile_damage,
    apply_shield_on_hit = function(...)
      return combat.apply_shield_on_hit(...)
    end,
    get_lifesteal_rate = get_lifesteal_rate,
    heal_turret = function(...)
      return combat.heal_turret(...)
    end,
    sync_turret_progression = sync_turret_progression,
    draw_effect_sprite = function(...)
      return combat.draw_effect_sprite(...)
    end,
    draw_attack_line = function(...)
      return combat.draw_attack_line(...)
    end,
  })
  copy_exports(combat, scheduler, {
    "schedule_status_damage",
    "apply_slowdown_sticker",
    "process_status_effects",
  })

  local dispatch = combat_dispatch.new({
    combat = combat,
    descriptors = descriptors,
    safe_read = safe_read,
    game_tick = game_tick,
    entity_tracking_key = entity_tracking_key,
    get_element_rank = get_element_rank,
    get_element_effect_summary_for_rank = get_element_effect_summary_for_rank,
    element_is_powered = element_is_powered,
    apply_luck_to_chance = apply_luck_to_chance,
    get_specialization_multiplier = get_specialization_multiplier,
    get_base_rank = get_base_rank,
    get_crit_chance_fraction = get_crit_chance_fraction,
    get_crit_damage_fraction = get_crit_damage_fraction,
    get_double_shot_chance = get_double_shot_chance,
    get_augment_rank = get_augment_rank,
    get_lifesteal_rate = get_lifesteal_rate,
    add_profile_damage = add_profile_damage,
    sync_turret_progression = sync_turret_progression,
  })
  copy_exports(combat, dispatch, {
    "get_element_effect_multiplier",
    "get_element_proc_chance",
    "get_electric_arc_count",
    "get_element_effect_summary",
    "draw_element_feedback",
    "apply_element_effects_to_target",
    "apply_combo_effects_to_target",
    "apply_evolution_damage_effects",
  })
  get_element_effect_summary = combat.get_element_effect_summary

  function apply_passive_evolution_effects()
    ensure_storage()

    for _, state in pairs(storage.turret_xp.chips) do
      ensure_evolution_state(state)
      local entity = state.entity
      if is_gun_turret(entity) then
        entity = combat.sync_turret_body_when_idle(entity, state)
        auto_feed_open_turret(state)
        combat.remember_loaded_ammo(entity, state)
        local repair_per_second = get_repair_per_second(state, entity)
        if repair_per_second > 0 then
          local max_health = safe_read(entity, "max_health")
          local health = safe_read(entity, "health")
          if max_health and health and health > 0 and health < max_health then
            entity.health = math.min(max_health, health + (repair_per_second * (REFRESH_TICKS / 60)))
          end
        end
        update_name_render(entity, state)
        update_shield_bar_render(entity, state, false)
      elseif entity and not entity.valid then
        destroy_name_render(state)
        destroy_shield_bar_render(state)
        state.entity = nil
      end
    end
  end

  function apply_shield_recharge_effects(ticks)
    ensure_storage()

    local elapsed_ticks = math.max(1, math.floor(tonumber(ticks) or SHIELD_RECHARGE_TICKS))
    for _, state in pairs(storage.turret_xp.chips) do
      local entity = state.entity
      if is_gun_turret(entity) then
        combat.recharge_shield(entity, state, elapsed_ticks)
      end
    end
  end
end
