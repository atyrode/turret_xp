return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  function feeder.get_entity_inventory(entity, inventory_id)
    if not entity or not entity.valid then
      return nil
    end
    if not inventory_id then
      return nil
    end

    local ok, inventory = pcall(function()
      return entity.get_inventory(inventory_id)
    end)

    if ok and inventory and inventory.valid then
      return inventory
    end

    return nil
  end

  function feeder.get_inventory(entity)
    return feeder.get_entity_inventory(entity, defines.inventory.chest)
  end

  function feeder.spill_stack(entity, stack, position)
    if not entity or not entity.valid or not stack or not stack.valid_for_read then
      return
    end

    local item = {
      name = stack.name,
      count = stack.count,
    }
    pcall(function()
      if stack.quality and stack.quality.name then
        item.quality = stack.quality.name
      end
    end)
    pcall(function()
      entity.surface.spill_item_stack({
        position = position or entity.position,
        stack = item,
        enable_looted = true,
        allow_belts = false,
      })
    end)
    stack.clear()
  end

  function feeder.spill_inventory_contents(entity, inventory, position)
    if not inventory then
      return
    end
    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read then
        feeder.spill_stack(entity, stack, position)
      end
    end
  end

  function feeder.spill_contents(entity, position)
    feeder.spill_inventory_contents(entity, feeder.get_inventory(entity), position)
  end

  function feeder.destroy(state, position, spill)
    if not state then
      return
    end

    local entity = state.feeder
    state.feeder = nil
    if not entity or not entity.valid then
      return
    end

    ensure_storage()
    if entity.unit_number then
      storage.turret_xp.feeders[entity.unit_number] = nil
    end

    if spill then
      feeder.spill_contents(entity, position or entity.position)
    end

    if is_gun_turret(state.entity) then
      feeder.update_nearby_inserters(state.entity, state)
    end

    pcall(function()
      entity.destroy({ raise_destroy = false })
    end)
  end

  function feeder.find_position(entity)
    if not is_gun_turret(entity) then
      return nil
    end

    return {
      x = entity.position.x,
      y = entity.position.y,
    }
  end

  function feeder.get_allowed_items(state)
    local allowed = {}
    if not state then
      return allowed
    end

    ensure_evolution_state(state)
    for _, element_id in ipairs(get_unique_active_element_ids(state)) do
      local requirement = get_element_remaining_requirement(state, element_id)
      if requirement and requirement.remaining > 0 then
        allowed[requirement.name] = true
      end
    end

    return allowed
  end

  function feeder.allowed_item_names(state)
    local allowed = feeder.get_allowed_items(state)
    local names = {}
    local seen = {}
    local evolution = state and ensure_evolution_state(state) or nil
    local entries = {}

    local function add_entry(name, slot, delivered, required)
      if name and allowed[name] then
        local ratio = required and required > 0 and ((delivered or 0) / required) or 1
        local existing = seen[name]
        if existing then
          existing.ratio = math.min(existing.ratio, ratio)
          existing.slot = math.min(existing.slot, slot or 99)
        else
          local entry = {
            name = name,
            slot = slot or 99,
            ratio = ratio,
          }
          seen[name] = entry
          entries[#entries + 1] = entry
        end
      end
    end

    if evolution then
      for slot = 1, 2 do
        local element_id = evolution.elements and evolution.elements[slot] or nil
        if element_id then
          local requirement = get_element_remaining_requirement(state, element_id)
          if requirement then
            add_entry(requirement.name, slot, requirement.delivered, requirement.count)
          end
        end
      end
    end

    for name in pairs(allowed) do
      add_entry(name, 99, 0, 1)
    end

    table.sort(entries, function(a, b)
      if math.abs((a.ratio or 0) - (b.ratio or 0)) > 0.000001 then
        return (a.ratio or 0) < (b.ratio or 0)
      end
      if (a.slot or 99) ~= (b.slot or 99) then
        return (a.slot or 99) < (b.slot or 99)
      end
      return tostring(a.name) < tostring(b.name)
    end)

    for _, entry in ipairs(entries) do
      names[#names + 1] = entry.name
    end

    return names
  end

  function feeder.filter_name(filter)
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

  function feeder.get_inserter_filter_slot_count(inserter)
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

  function feeder.read_inserter_filters(inserter, count)
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

  function feeder.inserter_filters_match_allowed(inserter, allowed_items, count)
    local has_filter = false
    local has_allowed_filter = false

    for index = 1, count do
      local ok, filter = pcall(function()
        return inserter.get_filter(index)
      end)
      if ok then
        local name = feeder.filter_name(filter)
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

  function feeder.set_inserter_drop_target(inserter, target)
    if not inserter or not inserter.valid or not target or not target.valid then
      return false
    end

    local ok = pcall(function()
      inserter.drop_target = target
    end)
    return ok
  end

  function feeder.drop_position_matches_turret(inserter, turret)
    local position = safe_read(inserter, "drop_position")
    local turret_position = safe_read(turret, "position")
    if not position or not turret_position then
      return false
    end

    return math.abs((position.x or 0) - (turret_position.x or 0)) <= 1.4 and math.abs((position.y or 0) - (turret_position.y or 0)) <= 1.4
  end

  function feeder.inserter_points_at_turret(inserter, turret, feeder_entity)
    if not inserter or not inserter.valid or safe_read(inserter, "type") ~= "inserter" then
      return false
    end
    if not is_gun_turret(turret) then
      return false
    end

    local target = safe_read(inserter, "drop_target")
    if target and target.valid then
      if target == turret or (feeder_entity and target == feeder_entity) then
        return true
      end
    end

    return feeder.drop_position_matches_turret(inserter, turret)
  end

  function feeder.transport_line_has_item(entity, item_name)
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

  function feeder.entity_has_item(entity, item_name)
    if not entity or not entity.valid or not item_name then
      return false
    end

    local ok, count = pcall(function()
      return entity.get_item_count(item_name)
    end)
    if ok and (count or 0) > 0 then
      return true
    end

    return feeder.transport_line_has_item(entity, item_name)
  end

  function feeder.ground_has_item(surface, position, item_name)
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
      local stack = safe_read(item, "stack")
      if stack and stack.valid_for_read and stack.name == item_name then
        return true
      end
    end

    return false
  end

  function feeder.inserter_source_has_allowed_item(inserter, allowed_items)
    for item_name in pairs(allowed_items) do
      if feeder.inserter_source_has_item(inserter, item_name) then
        return true
      end
    end

    return false
  end

  function feeder.inserter_source_has_item(inserter, item_name)
    local source = safe_read(inserter, "pickup_target")
    if feeder.entity_has_item(source, item_name) then
      return true
    end

    local surface = safe_read(inserter, "surface")
    local pickup_position = safe_read(inserter, "pickup_position")
    return feeder.ground_has_item(surface, pickup_position, item_name)
  end

  function feeder.prioritize_item_names_for_inserter(inserter, names)
    return names or {}
  end

  function feeder.apply_inserter_filters(inserter, state)
    if not inserter or not inserter.valid or not state then
      return false
    end

    local unit_number = safe_read(inserter, "unit_number")
    if not unit_number then
      return false
    end

    ensure_storage()
    local allowed_items = feeder.get_allowed_items(state)
    local names = feeder.prioritize_item_names_for_inserter(inserter, feeder.allowed_item_names(state))
    if #names == 0 then
      return false
    end

    local count = feeder.get_inserter_filter_slot_count(inserter)
    if count <= 0 then
      return false
    end

    local managed = storage.turret_xp.managed_inserters[unit_number]
    if not managed then
      local has_filter, has_allowed_filter = feeder.inserter_filters_match_allowed(inserter, allowed_items, count)
      if has_filter then
        if not has_allowed_filter then
          return false
        end

        managed = {
          filters = feeder.read_inserter_filters(inserter, count),
        }
        storage.turret_xp.managed_inserters[unit_number] = managed
      else
        managed = {
          filters = feeder.read_inserter_filters(inserter, count),
        }
        storage.turret_xp.managed_inserters[unit_number] = managed
      end
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

  function feeder.restore_inserter_filters(inserter)
    if not inserter or not inserter.valid then
      return
    end

    local unit_number = safe_read(inserter, "unit_number")
    if not unit_number or not storage or not storage.turret_xp then
      return
    end

    local managed = storage.turret_xp.managed_inserters and storage.turret_xp.managed_inserters[unit_number] or nil
    if not managed then
      return
    end

    local count = math.max(feeder.get_inserter_filter_slot_count(inserter), #(managed.filters or {}))
    for index = 1, count do
      local filter = managed.filters and managed.filters[index] or nil
      pcall(function()
        inserter.set_filter(index, filter)
      end)
    end

    storage.turret_xp.managed_inserters[unit_number] = nil
  end

  function feeder.update_nearby_inserters(turret, state)
    if not is_gun_turret(turret) or not state then
      return
    end

    ensure_storage()
    local surface = safe_read(turret, "surface")
    local position = safe_read(turret, "position")
    if not surface or not position then
      return
    end

    local feeder_entity = state.feeder
    local needs_input = feeder.needs_input(state)
    local allowed_items = feeder.get_allowed_items(state)
    local filters = {
      area = {
        { position.x - FEEDER_INSERTER_RADIUS, position.y - FEEDER_INSERTER_RADIUS },
        { position.x + FEEDER_INSERTER_RADIUS, position.y + FEEDER_INSERTER_RADIUS },
      },
      type = "inserter",
    }
    local force = safe_read(turret, "force")
    if force then
      filters.force = force
    end
    local inserters = surface.find_entities_filtered(filters)

    for _, inserter in ipairs(inserters) do
      if feeder.inserter_points_at_turret(inserter, turret, feeder_entity) then
        local unit_number = safe_read(inserter, "unit_number")
        local managed = unit_number and storage.turret_xp.managed_inserters[unit_number] or nil
        local has_source_item = needs_input and feeder.inserter_source_has_allowed_item(inserter, allowed_items)
        local filter_count = feeder.get_inserter_filter_slot_count(inserter)
        local _, has_allowed_filter = feeder.inserter_filters_match_allowed(inserter, allowed_items, filter_count)
        local should_feed = needs_input
          and feeder_entity
          and feeder_entity.valid
          and (has_source_item or has_allowed_filter or managed ~= nil)

        if should_feed and feeder.apply_inserter_filters(inserter, state) then
          feeder.set_inserter_drop_target(inserter, feeder_entity)
        else
          feeder.restore_inserter_filters(inserter)
          feeder.set_inserter_drop_target(inserter, turret)
        end
      end
    end
  end

  function feeder.needs_input(state)
    return next(feeder.get_allowed_items(state)) ~= nil
  end

  function feeder.should_exist(state)
    if not state then
      return false
    end

    return feeder.needs_input(state)
  end

  function feeder.set_input_open(inventory, open)
    if not inventory then
      return
    end

    local ok, supports_bar = pcall(function()
      return inventory.supports_bar()
    end)
    if not ok or not supports_bar then
      return
    end

    local open_slots = 0
    if type(open) == "number" then
      open_slots = math.max(0, math.floor(open))
    elseif open then
      open_slots = #inventory
    end
    open_slots = math.min(#inventory, open_slots)

    local target_bar = open_slots + 1
    local bar_ok, current_bar = pcall(function()
      return inventory.get_bar()
    end)
    if bar_ok and current_bar == target_bar then
      return
    end

    pcall(function()
      inventory.set_bar(target_bar)
    end)
  end

  function feeder.get_project_input_slots(state, priority_item)
    if not state or not priority_item then
      return 0
    end

    local remaining = 0
    for _, element_id in ipairs(get_unique_active_element_ids(state)) do
      local requirement = get_element_remaining_requirement(state, element_id)
      if requirement and requirement.name == priority_item then
        remaining = remaining + math.max(0, requirement.remaining or 0)
      end
    end
    return remaining
  end

  function feeder.get_total_input_slots(state)
    if not state then
      return 0
    end

    local remaining = 0
    for _, element_id in ipairs(get_unique_active_element_ids(state)) do
      local requirement = get_element_remaining_requirement(state, element_id)
      if requirement then
        remaining = remaining + math.max(0, requirement.remaining or 0)
      end
    end
    return remaining
  end

  function feeder.get_input_slot_count(state, inventory)
    if not state or not inventory then
      return 0
    end
    local slots = feeder.get_total_input_slots(state)
    return math.min(#inventory, FEEDER_INPUT_BUFFER_SLOTS, math.max(0, slots))
  end

  function feeder.inventory_is_empty(inventory)
    if not inventory then
      return true
    end

    local ok, empty = pcall(function()
      return inventory.is_empty()
    end)

    return ok and empty == true
  end

  function feeder.ensure(entity, state)
    if not is_gun_turret(entity) or not state then
      return nil
    end

    ensure_storage()

    local needs_input = feeder.needs_input(state)
    local should_exist = feeder.should_exist(state)
    local current = state.feeder
    if current and current.valid and current.name == FEEDER_NAME and current.surface == entity.surface then
      local dx = math.abs((current.position.x or 0) - (entity.position.x or 0))
      local dy = math.abs((current.position.y or 0) - (entity.position.y or 0))
      if dx <= 0.1 and dy <= 0.1 then
        local inventory = feeder.get_inventory(current)
        feeder.set_input_open(inventory, feeder.get_input_slot_count(state, inventory))
        if not should_exist and not needs_input and feeder.inventory_is_empty(inventory) then
          feeder.destroy(state, current.position, false)
          return nil
        end
        if current.unit_number and state.chip_id then
          storage.turret_xp.feeders[current.unit_number] = state.chip_id
        end
        feeder.update_nearby_inserters(entity, state)
        return current
      end
    end

    if current and current.valid then
      feeder.destroy(state, current.position, true)
    else
      state.feeder = nil
    end

    if not should_exist and not needs_input then
      return nil
    end

    local position = feeder.find_position(entity)
    if not position then
      return nil
    end

    local ok, created = pcall(function()
      return entity.surface.create_entity({
        name = FEEDER_NAME,
        position = position,
        force = entity.force,
        raise_built = false,
        create_build_effect_smoke = false,
      })
    end)

    if not ok or not created then
      return nil
    end

    pcall(function()
      created.destructible = false
    end)
    pcall(function()
      created.minable_flag = false
    end)

    state.feeder = created
    if created.unit_number and state.chip_id then
      storage.turret_xp.feeders[created.unit_number] = state.chip_id
    end
    local inventory = feeder.get_inventory(created)
    feeder.set_input_open(inventory, feeder.get_input_slot_count(state, inventory))
    feeder.update_nearby_inserters(entity, state)

    return created
  end

  function feeder.remove_items(state, item_name, count)
    count = math.max(0, math.floor(tonumber(count) or 0))
    if count <= 0 or not item_name then
      return 0
    end

    local entity = state and state.feeder
    if state and is_gun_turret(state.entity) then
      entity = feeder.ensure(state.entity, state) or entity
    end

    local inventory = feeder.get_inventory(entity)
    if not inventory then
      return 0
    end

    local ok, removed = pcall(function()
      return inventory.remove({
        name = item_name,
        count = count,
      })
    end)

    if ok and removed then
      return removed
    end

    return 0
  end

  function feeder.make_item_stack(stack, count)
    if not stack or not stack.valid_for_read then
      return nil
    end

    local item = {
      name = stack.name,
      count = count or stack.count,
    }
    pcall(function()
      if stack.quality and stack.quality.name then
        item.quality = stack.quality.name
      end
    end)
    return item
  end

  function feeder.is_ammo_item(item_name)
    local prototype = item_name and prototypes.item[item_name] or nil
    if not prototype then
      return false
    end

    local ok, ammo_category = pcall(function()
      return prototype.ammo_category
    end)
    return ok and ammo_category ~= nil
  end

  function feeder.route_contents(state)
    if not state or not is_gun_turret(state.entity) then
      return
    end

    local needs_input = feeder.needs_input(state)
    local entity = state.feeder
    if not needs_input and not feeder.should_exist(state) then
      if not entity or not entity.valid then
        return
      end
    end

    if needs_input or feeder.should_exist(state) then
      entity = feeder.ensure(state.entity, state) or entity
    end
    local inventory = feeder.get_inventory(entity)
    if not inventory then
      return
    end
    feeder.set_input_open(inventory, feeder.get_input_slot_count(state, inventory))

    local turret_inventory = nil
    pcall(function()
      turret_inventory = state.entity.get_inventory(defines.inventory.turret_ammo)
    end)

    local allowed_feed_items = feeder.get_allowed_items(state)
    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read then
        local item_name = stack.name
        if turret_inventory and feeder.is_ammo_item(item_name) then
          local item = feeder.make_item_stack(stack)
          local inserted = 0
          if item then
            local ok, result = pcall(function()
              return turret_inventory.insert(item)
            end)
            if ok and result then
              inserted = result
            end
          end
          if inserted > 0 then
            local removed = feeder.make_item_stack(stack, inserted)
            if removed then
              pcall(function()
                inventory.remove(removed)
              end)
            end
          end
        end
      end
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read then
        local item_name = stack.name
        if not allowed_feed_items[item_name] and not feeder.is_ammo_item(item_name) then
          feeder.spill_stack(entity, stack, state.entity.position)
        end
      end
    end

    if not feeder.needs_input(state) then
      feeder.set_input_open(inventory, false)
      if not feeder.should_exist(state) and feeder.inventory_is_empty(inventory) then
        feeder.destroy(state, entity.position, false)
      end
    else
      feeder.set_input_open(inventory, feeder.get_input_slot_count(state, inventory))
    end

    feeder.update_nearby_inserters(state.entity, state)
  end
end
