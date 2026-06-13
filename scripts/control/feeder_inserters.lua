local feeder_inserters = {}

function feeder_inserters.new(deps)
  local service = {}

  function service.filter_name(filter)
    if not filter then
      return nil
    end
    if type(filter) == "string" then
      return filter
    end
    if type(filter) == "table" then
      return filter.name
    end
    return nil
  end

  function service.get_inserter_filter_slot_count(inserter)
    if not inserter or not inserter.valid then
      return 0
    end

    local count = 0
    for index = 1, 10 do
      local ok = pcall(function()
        return inserter.get_filter(index)
      end)
      if not ok then
        break
      end
      count = index
    end
    return count
  end

  function service.read_inserter_filters(inserter, count)
    local filters = {}
    for index = 1, count do
      local ok, filter = pcall(function()
        return inserter.get_filter(index)
      end)
      if ok then
        filters[index] = filter
      end
    end
    return filters
  end

  function service.inserter_filters_match_allowed(inserter, allowed_items, count)
    local has_filter = false
    local has_allowed_filter = false

    for index = 1, count do
      local ok, filter = pcall(function()
        return inserter.get_filter(index)
      end)
      if ok then
        local name = service.filter_name(filter)
        if name then
          has_filter = true
          if allowed_items[name] then
            has_allowed_filter = true
          end
        end
      end
    end

    return has_filter, has_allowed_filter
  end

  function service.set_inserter_drop_target(inserter, target)
    if not inserter or not inserter.valid or not target or not target.valid then
      return false
    end

    local ok = pcall(function()
      inserter.drop_target = target
    end)
    return ok
  end

  function service.drop_position_matches_turret(inserter, turret)
    local position = deps.safe_read(inserter, "drop_position")
    local turret_position = deps.safe_read(turret, "position")
    if not position or not turret_position then
      return false
    end

    return math.abs((position.x or 0) - (turret_position.x or 0)) <= 1.4 and math.abs((position.y or 0) - (turret_position.y or 0)) <= 1.4
  end

  function service.inserter_points_at_turret(inserter, turret, feeder_entity)
    if not inserter or not inserter.valid or deps.safe_read(inserter, "type") ~= "inserter" then
      return false
    end
    if not deps.is_gun_turret(turret) then
      return false
    end

    local target = deps.safe_read(inserter, "drop_target")
    if target and target.valid then
      if target == turret or (feeder_entity and target == feeder_entity) then
        return true
      end
    end

    return service.drop_position_matches_turret(inserter, turret)
  end

  function service.transport_line_has_item(entity, item_name)
    if not entity or not entity.valid or not item_name then
      return false
    end

    local ok, max_index = pcall(function()
      return entity.get_max_transport_line_index()
    end)
    if not ok or not max_index then
      return false
    end

    for index = 1, max_index do
      local line_ok, line = pcall(function()
        return entity.get_transport_line(index)
      end)
      if line_ok and line and line.valid then
        local count_ok, count = pcall(function()
          return line.get_item_count(item_name)
        end)
        if count_ok and (count or 0) > 0 then
          return true
        end
      end
    end

    return false
  end

  function service.entity_has_item(entity, item_name)
    if not entity or not entity.valid or not item_name then
      return false
    end

    local ok, count = pcall(function()
      return entity.get_item_count(item_name)
    end)
    if ok and (count or 0) > 0 then
      return true
    end

    return service.transport_line_has_item(entity, item_name)
  end

  function service.ground_has_item(surface, position, item_name)
    if not surface or not position or not item_name then
      return false
    end

    local ok, items = pcall(function()
      return surface.find_entities_filtered({
        area = {
          { (position.x or 0) - 0.35, (position.y or 0) - 0.35 },
          { (position.x or 0) + 0.35, (position.y or 0) + 0.35 },
        },
        type = "item-entity",
      })
    end)
    if not ok or not items then
      return false
    end

    for _, item in ipairs(items) do
      local stack = deps.safe_read(item, "stack")
      if stack and stack.valid_for_read and stack.name == item_name then
        return true
      end
    end

    return false
  end

  function service.pickup_area_has_item(surface, position, item_name, ignored_entity)
    if not surface or not position or not item_name then
      return false
    end

    local ok, entities = pcall(function()
      return surface.find_entities_filtered({
        area = {
          { (position.x or 0) - 0.35, (position.y or 0) - 0.35 },
          { (position.x or 0) + 0.35, (position.y or 0) + 0.35 },
        },
      })
    end)
    if not ok or not entities then
      return false
    end

    for _, entity in ipairs(entities) do
      if entity and entity.valid and entity ~= ignored_entity and entity.type ~= "item-entity" then
        if service.entity_has_item(entity, item_name) then
          return true
        end
      end
    end

    return false
  end

  function service.inserter_source_has_allowed_item(inserter, allowed_items)
    for item_name in pairs(allowed_items) do
      if service.inserter_source_has_item(inserter, item_name) then
        return true
      end
    end

    return false
  end

  function service.inserter_source_has_item(inserter, item_name)
    local source = deps.safe_read(inserter, "pickup_target")
    if service.entity_has_item(source, item_name) then
      return true
    end

    local surface = deps.safe_read(inserter, "surface")
    local pickup_position = deps.safe_read(inserter, "pickup_position")
    if service.pickup_area_has_item(surface, pickup_position, item_name, inserter) then
      return true
    end

    return service.ground_has_item(surface, pickup_position, item_name)
  end

  function service.prioritize_item_names_for_inserter(inserter, names)
    if not inserter or not inserter.valid or not names or #names <= 1 then
      return names or {}
    end

    local available = {}
    local unavailable = {}
    for _, name in ipairs(names) do
      if service.inserter_source_has_item(inserter, name) then
        available[#available + 1] = name
      else
        unavailable[#unavailable + 1] = name
      end
    end

    if #available == 0 then
      return names
    end

    for _, name in ipairs(unavailable) do
      available[#available + 1] = name
    end
    return available
  end

  function service.capture_managed_inserter(inserter, state, count)
    return {
      entity = inserter,
      filters = service.read_inserter_filters(inserter, count),
      turret_unit_number = state and state.entity and deps.safe_read(state.entity, "unit_number") or nil,
      feeder_unit_number = state and state.feeder and deps.safe_read(state.feeder, "unit_number") or nil,
    }
  end

  function service.track_managed_inserter(managed, inserter, state)
    if not managed then
      return
    end

    managed.entity = managed.entity or inserter
    managed.turret_unit_number = managed.turret_unit_number
      or (state and state.entity and deps.safe_read(state.entity, "unit_number") or nil)
    managed.feeder_unit_number = managed.feeder_unit_number
      or (state and state.feeder and deps.safe_read(state.feeder, "unit_number") or nil)
  end

  function service.managed_inserter_matches_state(managed, state, feeder_entity)
    if not managed or not state then
      return false
    end

    local turret_unit_number = state.entity and deps.safe_read(state.entity, "unit_number") or nil
    local feeder_unit_number = feeder_entity and deps.safe_read(feeder_entity, "unit_number") or nil
    feeder_unit_number = feeder_unit_number or (state.feeder and deps.safe_read(state.feeder, "unit_number") or nil)

    if not managed.turret_unit_number and not managed.feeder_unit_number then
      return true
    end

    return (turret_unit_number and managed.turret_unit_number == turret_unit_number)
      or (feeder_unit_number and managed.feeder_unit_number == feeder_unit_number)
  end

  function service.apply_inserter_filters(inserter, state)
    if not inserter or not inserter.valid or not state then
      return false
    end

    local unit_number = deps.safe_read(inserter, "unit_number")
    if not unit_number then
      return false
    end

    deps.ensure_storage()
    local allowed_items = deps.get_allowed_items(state)
    local names = service.prioritize_item_names_for_inserter(inserter, deps.allowed_item_names(state))
    if #names == 0 then
      return false
    end

    local count = service.get_inserter_filter_slot_count(inserter)
    if count <= 0 then
      return false
    end

    local managed = deps.storage_root().managed_inserters[unit_number]
    if not managed then
      local has_filter, has_allowed_filter = service.inserter_filters_match_allowed(inserter, allowed_items, count)
      if has_filter then
        if not has_allowed_filter then
          return false
        end

        managed = service.capture_managed_inserter(inserter, state, count)
        deps.storage_root().managed_inserters[unit_number] = managed
      else
        managed = service.capture_managed_inserter(inserter, state, count)
        deps.storage_root().managed_inserters[unit_number] = managed
      end
    else
      service.track_managed_inserter(managed, inserter, state)
    end

    local applied_any_filter = false
    for index = 1, count do
      local filter = names[index] and { name = names[index] } or nil
      local ok = pcall(function()
        inserter.set_filter(index, filter)
      end)
      if ok and filter then
        applied_any_filter = true
      end
    end

    return applied_any_filter
  end

  function service.restore_inserter_filters(inserter)
    if not inserter or not inserter.valid then
      return
    end

    local unit_number = deps.safe_read(inserter, "unit_number")
    local root = deps.storage_root()
    if not unit_number or not root then
      return
    end

    local managed = root.managed_inserters and root.managed_inserters[unit_number] or nil
    if not managed then
      return
    end

    local count = math.max(service.get_inserter_filter_slot_count(inserter), #(managed.filters or {}))
    for index = 1, count do
      local filter = managed.filters and managed.filters[index] or nil
      pcall(function()
        inserter.set_filter(index, filter)
      end)
    end

    root.managed_inserters[unit_number] = nil
  end

  function service.restore_managed_inserters_for_state(state, feeder_entity, restore_target)
    local root = deps.storage_root()
    if not root or not root.managed_inserters then
      return
    end

    for unit_number, managed in pairs(root.managed_inserters) do
      if service.managed_inserter_matches_state(managed, state, feeder_entity) then
        local inserter = managed and managed.entity or nil
        if inserter and inserter.valid then
          local should_restore_target = restore_target
            and restore_target.valid
            and service.inserter_points_at_turret(inserter, restore_target, feeder_entity)
          service.restore_inserter_filters(inserter)
          if should_restore_target then
            service.set_inserter_drop_target(inserter, restore_target)
          end
        else
          root.managed_inserters[unit_number] = nil
        end
      end
    end
  end

  return service
end

return feeder_inserters
