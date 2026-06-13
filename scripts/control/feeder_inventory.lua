local feeder_inventory = {}

function feeder_inventory.new(deps)
  local service = {}

  function service.get_entity_inventory(entity, inventory_id)
    return deps.compat.get_entity_inventory(entity, inventory_id, "entity inventory")
  end

  function service.get_inventory(entity)
    return service.get_entity_inventory(entity, deps.inventory_defines.chest)
  end

  function service.spill_stack(entity, stack, position)
    if not entity or not entity.valid or not stack or not stack.valid_for_read then
      return
    end

    local item = {
      name = stack.name,
      count = stack.count,
    }
    item.quality = deps.compat.quality_name(stack, nil, "spill stack quality")
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

  function service.spill_inventory_contents(entity, inventory, position)
    if not inventory then
      return
    end
    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read then
        service.spill_stack(entity, stack, position)
      end
    end
  end

  function service.spill_contents(entity, position)
    service.spill_inventory_contents(entity, service.get_inventory(entity), position)
  end

  function service.get_allowed_items(state)
    local allowed = {}
    if not state then
      return allowed
    end

    deps.ensure_evolution_state(state)
    for _, element_id in ipairs(deps.get_unique_active_element_ids(state)) do
      local requirement = deps.get_element_remaining_requirement(state, element_id)
      if requirement and requirement.remaining > 0 then
        allowed[requirement.name] = true
      end
    end

    return allowed
  end

  function service.allowed_item_names(state)
    local allowed = service.get_allowed_items(state)
    local names = {}
    local seen = {}
    local evolution = state and deps.ensure_evolution_state(state) or nil
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
          local requirement = deps.get_element_remaining_requirement(state, element_id)
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

  function service.needs_input(state)
    return next(service.get_allowed_items(state)) ~= nil
  end

  function service.should_exist(state)
    if not state then
      return false
    end

    return service.needs_input(state)
  end

  function service.set_input_open(inventory, open)
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

  function service.get_total_input_slots(state)
    if not state then
      return 0
    end

    local remaining = 0
    for _, element_id in ipairs(deps.get_unique_active_element_ids(state)) do
      local requirement = deps.get_element_remaining_requirement(state, element_id)
      if requirement then
        remaining = remaining + math.max(0, requirement.remaining or 0)
      end
    end
    return remaining
  end

  function service.get_input_slot_count(state, inventory)
    if not state or not inventory then
      return 0
    end
    local slots = service.get_total_input_slots(state)
    return math.min(#inventory, deps.input_buffer_slots, math.max(0, slots))
  end

  function service.inventory_is_empty(inventory)
    if not inventory then
      return true
    end

    local ok, empty = pcall(function()
      return inventory.is_empty()
    end)

    return ok and empty == true
  end

  function service.remove_items(state, item_name, count)
    count = math.max(0, math.floor(tonumber(count) or 0))
    if count <= 0 or not item_name then
      return 0
    end

    local entity = state and state.feeder
    if state and deps.is_gun_turret(state.entity) then
      entity = deps.ensure_feeder(state.entity, state) or entity
    end

    local inventory = service.get_inventory(entity)
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

  function service.make_item_stack(stack, count)
    if not stack or not stack.valid_for_read then
      return nil
    end

    local item = {
      name = stack.name,
      count = count or stack.count,
    }
    item.quality = deps.compat.quality_name(stack, nil, "feeder stack quality")
    return item
  end

  function service.is_ammo_item(item_name)
    local prototype = item_name and deps.safe_read(deps.item_prototypes(), item_name, nil, "item prototype") or nil
    if not prototype then
      return false
    end

    return deps.safe_read(prototype, "ammo_category", nil, "item ammo_category") ~= nil
  end

  function service.route_contents(state)
    if not state or not deps.is_gun_turret(state.entity) then
      return
    end

    local needs_input = service.needs_input(state)
    local entity = state.feeder
    if not needs_input and not service.should_exist(state) then
      if not entity or not entity.valid then
        return
      end
    end

    if needs_input or service.should_exist(state) then
      entity = deps.ensure_feeder(state.entity, state) or entity
    end
    local inventory = service.get_inventory(entity)
    if not inventory then
      return
    end
    service.set_input_open(inventory, service.get_input_slot_count(state, inventory))

    local turret_inventory = service.get_entity_inventory(state.entity, deps.inventory_defines.turret_ammo)

    local allowed_feed_items = service.get_allowed_items(state)
    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read then
        local item_name = stack.name
        if turret_inventory and service.is_ammo_item(item_name) then
          local item = service.make_item_stack(stack)
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
            local removed = service.make_item_stack(stack, inserted)
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
        if not allowed_feed_items[item_name] and not service.is_ammo_item(item_name) then
          service.spill_stack(entity, stack, state.entity.position)
        end
      end
    end

    if not service.needs_input(state) then
      service.set_input_open(inventory, false)
      if not service.should_exist(state) and service.inventory_is_empty(inventory) then
        deps.destroy_feeder(state, entity.position, false)
      end
    else
      service.set_input_open(inventory, service.get_input_slot_count(state, inventory))
    end

    deps.update_nearby_inserters(state.entity, state)
  end

  return service
end

return feeder_inventory
