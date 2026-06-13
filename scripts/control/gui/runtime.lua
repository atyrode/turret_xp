local gui_runtime_module = {}

function gui_runtime_module.new(deps)
  local GUI = deps.GUI
  local get_gui_panel = deps.get_gui_panel
  local get_turret_state = deps.get_turret_state
  local sync_turret_progression = deps.sync_turret_progression
  local get_loaded_ammo = deps.get_loaded_ammo
  local get_entity_quality_name = deps.get_entity_quality_name
  local safe_read = deps.safe_read
  local get_max_health_for_quality = deps.get_max_health_for_quality
  local set_gui_caption = deps.set_gui_caption
  local set_gui_progress = deps.set_gui_progress
  local format_number = deps.format_number
  local update_core_panel = deps.update_core_panel
  local update_stats_panel = deps.update_stats_panel
  local update_evolution_panel = deps.update_evolution_panel
  local update_shield_bar_render = deps.update_shield_bar_render

  local service = {}

  local function get_turret_gui_context(entity)
    local state = get_turret_state(entity)
    local progression = state and sync_turret_progression(state) or nil
    local required = progression and progression.required or 1
    local progress = progression and required > 0 and math.min(1, progression.xp / required) or 0
    local ammo_name, ammo_count, ammo_quality, ammo_in_magazine, ammo_magazine_size = get_loaded_ammo(entity)
    local quality_name = get_entity_quality_name(entity)
    local live_max_health = safe_read(entity, "max_health")
    local live_health = safe_read(entity, "health") or live_max_health
    local max_health = get_max_health_for_quality(entity, quality_name, state) or live_max_health
    local health = live_health or max_health
    if state and live_max_health and live_max_health > 0 and max_health and health then
      health = math.max(1, math.min(max_health, max_health * (health / live_max_health)))
    end

    return {
      state = state,
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
    }
  end

  local function update_turret_gui_progress_and_stats(panel, entity, context)
    local state = context.state
    if state then
      set_gui_caption(panel, GUI.level, { "turret-xp.level", context.progression.level })
      set_gui_caption(
        panel,
        GUI.xp,
        { "turret-xp.xp-progress", format_number(context.progression.xp, 0), format_number(context.required, 0) }
      )
    else
      set_gui_caption(panel, GUI.level, { "turret-xp.no-core-level" })
      set_gui_caption(panel, GUI.xp, { "turret-xp.no-core-xp" })
    end
    set_gui_progress(panel, GUI.xp_bar, context.progress)
    set_gui_caption(panel, GUI.xp_percent, state and { "turret-xp.level-progress-suffix", format_number(context.progress * 100, 0) } or "")

    update_stats_panel(
      panel,
      entity,
      state,
      context.ammo_name,
      context.ammo_count,
      context.ammo_quality,
      context.ammo_in_magazine,
      context.ammo_magazine_size,
      context.quality_name,
      context.max_health,
      context.health
    )
    if state then
      update_shield_bar_render(entity, state, true)
    end
  end

  function service.update_turret_gui_stats(player, entity)
    local panel = get_gui_panel(player)
    if not panel then
      return false
    end

    local context = get_turret_gui_context(entity)
    update_turret_gui_progress_and_stats(panel, entity, context)
    return true
  end

  function service.update_turret_gui(player, entity, evolution_anchor)
    local panel = get_gui_panel(player)
    if not panel then
      return false
    end

    local context = get_turret_gui_context(entity)

    update_core_panel(panel, player, entity, context.state)
    update_turret_gui_progress_and_stats(panel, entity, context)
    update_evolution_panel(panel, entity, context.state, context.ammo_name, evolution_anchor)

    return true
  end

  return service
end

return gui_runtime_module
