local gui_runtime_module = {}

function gui_runtime_module.new(deps)
  local get_gui_panel = deps.get_gui_panel
  local get_turret_state = deps.get_turret_state
  local sync_turret_progression = deps.sync_turret_progression
  local get_loaded_ammo = deps.get_loaded_ammo
  local get_entity_quality_name = deps.get_entity_quality_name
  local safe_read = deps.safe_read
  local get_max_health_for_quality = deps.get_max_health_for_quality
  local update_focused_panel = deps.update_focused_panel
  local update_shield_bar_render = deps.update_shield_bar_render
  local profile_automation = deps.profile_automation

  local service = {}

  local function gui_mode_for_state(state)
    return state and "installed" or "empty"
  end

  local function panel_mode(panel)
    return (panel.tags or {}).turret_xp_mode or "installed"
  end

  local function get_turret_gui_context(entity)
    local live_state = get_turret_state(entity)
    local display_state = profile_automation.build_preview_profile(live_state) or live_state
    local build_mode = display_state and display_state._build_mode_preview == true
    local build_target = build_mode and profile_automation.target_model(live_state) or nil
    local progression = live_state and sync_turret_progression(live_state) or nil
    local required = progression and progression.required or 1
    local progress = progression and required > 0 and math.min(1, progression.xp / required) or 0
    if build_mode then
      local live_level = live_state and live_state.level or 0
      local required_level = build_target and build_target.level or 0
      progression = {
        level = live_level,
        xp = 0,
        required = required_level,
      }
      required = required_level
      progress = required_level > 0 and math.min(1, live_level / required_level) or 1
    end
    local ammo_name, ammo_count, ammo_quality, ammo_in_magazine, ammo_magazine_size = get_loaded_ammo(entity)
    local quality_name = get_entity_quality_name(entity)
    local live_max_health = safe_read(entity, "max_health")
    local live_health = safe_read(entity, "health") or live_max_health
    local max_health = get_max_health_for_quality(entity, quality_name, display_state) or live_max_health
    local health = live_health or max_health
    if live_state and live_max_health and live_max_health > 0 and max_health and health then
      health = math.max(1, math.min(max_health, max_health * (health / live_max_health)))
    end

    return {
      state = display_state,
      live_state = live_state,
      build_mode = build_mode,
      build_target = build_target,
      progression = progression,
      required = required,
      progress = progress,
      ammo_name = ammo_name,
      ammo_count = ammo_count,
      ammo_quality = ammo_quality,
      ammo_in_magazine = ammo_in_magazine,
      ammo_magazine_size = ammo_magazine_size,
      quality_name = quality_name,
      max_health = max_health,
      health = health,
      player = nil,
    }
  end

  local function update_focused_turret_gui(panel, player, entity, context)
    context.player = player
    if not update_focused_panel(panel, player, entity, context) then
      return false
    end
    if context.live_state and not context.build_mode then
      update_shield_bar_render(entity, context.live_state, true)
    end
    return true
  end

  function service.update_turret_gui_stats(player, entity)
    local panel = get_gui_panel(player)
    if not panel then
      return false
    end

    local context = get_turret_gui_context(entity)
    if not context.live_state then
      return panel_mode(panel) == "empty"
    end

    return update_focused_turret_gui(panel, player, entity, context)
  end

  function service.update_turret_gui(player, entity, _evolution_anchor)
    local panel = get_gui_panel(player)
    if not panel then
      return false
    end

    local context = get_turret_gui_context(entity)
    if panel_mode(panel) ~= gui_mode_for_state(context.live_state) then
      return false
    end

    if not context.live_state then
      return true
    end

    return update_focused_turret_gui(panel, player, entity, context)
  end

  return service
end

return gui_runtime_module
