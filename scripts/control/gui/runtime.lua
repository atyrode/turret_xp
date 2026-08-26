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
  local find_gui_element = deps.find_gui_element
  local set_gui_caption = deps.set_gui_caption
  local set_gui_progress = deps.set_gui_progress
  local format_number = deps.format_number
  local get_gui_xp_modifier_summary = deps.get_gui_xp_modifier_summary
  local update_core_panel = deps.update_core_panel
  local update_build_panel = deps.update_build_panel
  local update_stats_panel = deps.update_stats_panel
  local update_evolution_panel = deps.update_evolution_panel
  local update_shield_bar_render = deps.update_shield_bar_render
  local profile_automation = deps.profile_automation
  local set_element_style = deps.set_element_style

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
    }
  end

  local function apply_build_mode_styles(panel, build_mode)
    set_element_style(
      find_gui_element(panel, GUI.xp_panel),
      build_mode and "turret_xp_left_section_frame_build_mode" or "turret_xp_left_section_frame"
    )
    set_element_style(find_gui_element(panel, GUI.stats_header), "subheader_frame")
    set_element_style(find_gui_element(panel, GUI.evolution_summary), "subheader_frame")
  end

  local function update_xp_modifier_summary(panel, entity, state)
    local modifiers = find_gui_element(panel, GUI.xp_modifiers)
    if not modifiers then
      return
    end

    local summary = state and get_gui_xp_modifier_summary(entity, state) or nil
    modifiers.visible = summary and summary.visible == true or false
    modifiers.caption = summary and summary.caption or ""
    modifiers.tooltip = summary and summary.tooltip or nil
  end

  local function update_turret_gui_progress_and_stats(panel, entity, context)
    local state = context.state
    apply_build_mode_styles(panel, context.build_mode == true)
    if state then
      if context.build_mode then
        set_gui_caption(panel, GUI.level, { "turret-xp.level", context.progression.level })
        set_gui_caption(
          panel,
          GUI.xp,
          context.build_target and context.build_target.open_ended and { "turret-xp.build-xp-open-ended", context.required }
            or { "turret-xp.build-xp", context.required }
        )
        set_gui_caption(panel, GUI.xp_percent, "")
      else
        set_gui_caption(panel, GUI.level, { "turret-xp.level", context.progression.level })
        set_gui_caption(
          panel,
          GUI.xp,
          { "turret-xp.xp-progress", format_number(context.progression.xp, 0), format_number(context.required, 0) }
        )
        set_gui_caption(panel, GUI.xp_percent, {
          "turret-xp.level-progress-suffix",
          format_number(context.progress * 100, 0),
        })
      end
    else
      set_gui_caption(panel, GUI.level, { "turret-xp.no-core-level" })
      set_gui_caption(panel, GUI.xp, { "turret-xp.no-core-xp" })
      set_gui_caption(panel, GUI.xp_percent, "")
    end
    set_gui_progress(panel, GUI.xp_bar, context.progress)
    update_xp_modifier_summary(panel, entity, state)

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
    if context.live_state and not context.build_mode then
      update_shield_bar_render(entity, context.live_state, true)
    end
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

    update_turret_gui_progress_and_stats(panel, entity, context)
    return true
  end

  function service.update_turret_gui(player, entity, evolution_anchor)
    local panel = get_gui_panel(player)
    if not panel then
      return false
    end

    local context = get_turret_gui_context(entity)
    if panel_mode(panel) ~= gui_mode_for_state(context.live_state) then
      return false
    end

    update_core_panel(panel, player, entity, context.live_state)
    update_build_panel(panel, context.live_state)
    if not context.live_state then
      return true
    end

    update_turret_gui_progress_and_stats(panel, entity, context)
    update_evolution_panel(panel, entity, context.state, context.ammo_name, evolution_anchor)

    return true
  end

  return service
end

return gui_runtime_module
