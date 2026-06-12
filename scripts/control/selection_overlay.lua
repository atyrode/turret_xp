return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  local OVERLAY_TTL = 180

  local function destroy_overlay_entry(entry)
    if entry and entry.render and entry.render.valid then
      entry.render.destroy()
    end
  end

  local function overlay_entry(player_index)
    ensure_storage()
    local entry = storage.turret_xp.selection_overlays[player_index]
    if entry and entry.render and not entry.render.valid then
      storage.turret_xp.selection_overlays[player_index] = nil
      return nil
    end
    return entry
  end

  local function format_health(entity)
    local health = safe_read(entity, "health")
    local max_health = safe_read(entity, "max_health")
    if health and max_health then
      return format_number(health, 0) .. " / " .. format_number(max_health, 0)
    end

    return "-"
  end

  local function format_loaded_ammo_line(entity)
    local ammo_name, ammo_count = get_loaded_ammo(entity)
    if not ammo_name then
      return { "turret-xp.no-ammo" }
    end

    return { "", "[item=", ammo_name, "] x", tostring(ammo_count or 0) }
  end

  local function overlay_title(state)
    local name = state and sanitize_core_name(state.custom_name) or ""
    if name ~= "" then
      return name
    end

    return { "turret-xp.overlay-title" }
  end

  function build_selection_overlay_text(entity, state)
    sync_turret_progression(state)
    local ammo_name = get_loaded_ammo(entity)
    return {
      "",
      "[font=default-bold][color=1,0.86,0.46]",
      overlay_title(state),
      "[/color][/font]\n",
      { "turret-xp.overlay-level-line", state.level or 0, format_number(state.xp or 0, 0), format_number(state.required_xp or 0, 0) },
      "\n",
      { "turret-xp.overlay-health-line", format_health(entity) },
      "    ",
      { "turret-xp.overlay-range-line", format_range(entity) },
      "\n",
      { "turret-xp.overlay-dps-line", format_estimated_dps(entity, ammo_name, state) },
      "\n",
      { "turret-xp.overlay-ammo-line", format_loaded_ammo_line(entity) },
      "\n[color=0.74,0.74,0.74]",
      { "turret-xp.overlay-experiment-note" },
      "[/color]",
    }
  end

  function destroy_selection_overlay(player_index)
    ensure_storage()
    local entry = storage.turret_xp.selection_overlays[player_index]
    destroy_overlay_entry(entry)
    storage.turret_xp.selection_overlays[player_index] = nil
  end

  function destroy_all_selection_overlays()
    if not storage or not storage.turret_xp then
      return
    end

    for player_index, entry in pairs(storage.turret_xp.selection_overlays or {}) do
      destroy_overlay_entry(entry)
      storage.turret_xp.selection_overlays[player_index] = nil
    end
  end

  function update_selection_overlay(player, entity, state)
    if not player or not player.valid or not entity or not entity.valid or not state then
      return false
    end

    local text = build_selection_overlay_text(entity, state)
    local target = {
      entity = entity,
      offset = { 0, -2.85 },
    }
    local entry = overlay_entry(player.index)
    if entry and entry.entity ~= entity then
      destroy_overlay_entry(entry)
      entry = nil
      storage.turret_xp.selection_overlays[player.index] = nil
    end

    if entry and entry.render and entry.render.valid then
      local ok = pcall(function()
        entry.render.text = text
        entry.render.target = target
        entry.render.players = { player }
        entry.render.time_to_live = OVERLAY_TTL
        entry.render.visible = true
      end)
      if ok then
        entry.entity = entity
        entry.chip_id = state.chip_id
        return true
      end
      destroy_selection_overlay(player.index)
    end

    local ok, render_object = pcall(function()
      return rendering.draw_text({
        text = text,
        surface = entity.surface,
        target = target,
        color = { 1, 1, 1 },
        scale = 1.05,
        font = "default",
        alignment = "center",
        vertical_alignment = "middle",
        scale_with_zoom = true,
        only_in_alt_mode = false,
        players = { player },
        time_to_live = OVERLAY_TTL,
        use_rich_text = true,
      })
    end)

    if not ok or not render_object then
      return false
    end

    storage.turret_xp.selection_overlays[player.index] = {
      render = render_object,
      entity = entity,
      chip_id = state.chip_id,
    }
    return true
  end

  function refresh_selected_turret_overlay(player)
    if not player or not player.valid or not player.connected then
      return
    end

    local entity, state = resolve_veteran_selection(player.selected)
    if not is_gun_turret(entity) then
      return
    end

    if state then
      update_selection_overlay(player, entity, state)
    end
  end

  function cleanup_selection_overlays()
    if not storage or not storage.turret_xp then
      return
    end

    for player_index, entry in pairs(storage.turret_xp.selection_overlays or {}) do
      local player = game.get_player(player_index)
      if not player or not player.valid then
        destroy_overlay_entry(entry)
        storage.turret_xp.selection_overlays[player_index] = nil
      elseif entry and entry.render and not entry.render.valid then
        storage.turret_xp.selection_overlays[player_index] = nil
      end
    end
  end
end
