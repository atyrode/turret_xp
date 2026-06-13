local feeder_refresh = {}

function feeder_refresh.new(deps)
  local service = {}

  local function refresh_stats(turret, state, feeder_entity)
    local force = deps.safe_read(turret, "force")
    return {
      tick = deps.game_tick(),
      turret_unit_number = deps.safe_read(turret, "unit_number"),
      feeder_unit_number = feeder_entity and deps.safe_read(feeder_entity, "unit_number") or nil,
      force_name = force and force.name or nil,
      scanned = 0,
      eligible = 0,
      managed = 0,
      restored = 0,
      pointed_to_feeder = 0,
      pointed_to_turret = 0,
      stale_restored = 0,
      needs_input = deps.needs_input(state),
    }
  end

  local function save_refresh_stats(stats)
    local root = deps.storage_root()
    if not root then
      return
    end

    root.feeder_refresh = root.feeder_refresh or {}
    root.feeder_refresh.last = stats
  end

  function service.get_last_refresh_stats()
    local root = deps.storage_root()
    return root and root.feeder_refresh and root.feeder_refresh.last or nil
  end

  function service.update_nearby_inserters(turret, state)
    if not deps.is_gun_turret(turret) or not state then
      return
    end

    deps.ensure_storage()
    local surface = deps.safe_read(turret, "surface")
    local position = deps.safe_read(turret, "position")
    if not surface or not position then
      return
    end

    local feeder_entity = state.feeder
    local needs_input = deps.needs_input(state)
    local allowed_items = deps.get_allowed_items(state)
    local stats = refresh_stats(turret, state, feeder_entity)
    local filters = {
      area = {
        { position.x - deps.inserter_radius, position.y - deps.inserter_radius },
        { position.x + deps.inserter_radius, position.y + deps.inserter_radius },
      },
      type = "inserter",
    }
    local force = deps.safe_read(turret, "force")
    if force then
      filters.force = force
    end
    local inserters = surface.find_entities_filtered(filters)

    for _, inserter in ipairs(inserters) do
      stats.scanned = stats.scanned + 1
      local unit_number = deps.safe_read(inserter, "unit_number")
      local managed = unit_number and deps.storage_root().managed_inserters[unit_number] or nil
      local managed_matches = managed and deps.inserters.managed_inserter_matches_state(managed, state, feeder_entity)
      if deps.inserters.inserter_points_at_turret(inserter, turret, feeder_entity) then
        stats.eligible = stats.eligible + 1
        local has_source_item = needs_input and deps.inserters.inserter_source_has_allowed_item(inserter, allowed_items)
        local filter_count = deps.inserters.get_inserter_filter_slot_count(inserter)
        local _, has_allowed_filter = deps.inserters.inserter_filters_match_allowed(inserter, allowed_items, filter_count)
        local should_feed = needs_input
          and feeder_entity
          and feeder_entity.valid
          and (has_source_item or has_allowed_filter or managed_matches)

        if should_feed and deps.inserters.apply_inserter_filters(inserter, state) then
          stats.managed = stats.managed + 1
          if deps.inserters.set_inserter_drop_target(inserter, feeder_entity) then
            stats.pointed_to_feeder = stats.pointed_to_feeder + 1
          end
        else
          deps.inserters.restore_inserter_filters(inserter)
          stats.restored = stats.restored + 1
          if deps.inserters.set_inserter_drop_target(inserter, turret) then
            stats.pointed_to_turret = stats.pointed_to_turret + 1
          end
        end
      elseif managed_matches then
        deps.inserters.restore_inserter_filters(inserter)
        stats.stale_restored = stats.stale_restored + 1
      end
    end

    save_refresh_stats(stats)
  end

  return service
end

return feeder_refresh
