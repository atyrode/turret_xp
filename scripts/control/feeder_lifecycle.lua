local feeder_lifecycle = {}

function feeder_lifecycle.new(deps)
  local service = {}

  function service.destroy(state, position, spill)
    if not state then
      return
    end

    local entity = state.feeder
    state.feeder = nil
    if not entity or not entity.valid then
      return
    end

    deps.ensure_storage()
    if entity.unit_number then
      deps.storage_root().feeders[entity.unit_number] = nil
    end

    if spill then
      deps.spill_contents(entity, position or entity.position)
    end

    if deps.is_gun_turret(state.entity) then
      deps.restore_managed_inserters_for_state(state, entity, state.entity)
      deps.update_nearby_inserters(state.entity, state)
    end

    pcall(function()
      entity.destroy({ raise_destroy = false })
    end)
  end

  function service.find_position(entity)
    if not deps.is_gun_turret(entity) then
      return nil
    end

    return {
      x = entity.position.x,
      y = entity.position.y,
    }
  end

  function service.ensure(entity, state)
    if not deps.is_gun_turret(entity) or not state then
      return nil
    end

    deps.ensure_storage()

    local needs_input = deps.needs_input(state)
    local should_exist = deps.should_exist(state)
    local current = state.feeder
    if current and current.valid and current.name == deps.feeder_name and current.surface == entity.surface then
      local dx = math.abs((current.position.x or 0) - (entity.position.x or 0))
      local dy = math.abs((current.position.y or 0) - (entity.position.y or 0))
      if dx <= 0.1 and dy <= 0.1 then
        local inventory = deps.get_inventory(current)
        deps.set_input_open(inventory, deps.get_input_slot_count(state, inventory))
        if not should_exist and not needs_input and deps.inventory_is_empty(inventory) then
          service.destroy(state, current.position, false)
          return nil
        end
        if current.unit_number and state.chip_id then
          deps.storage_root().feeders[current.unit_number] = state.chip_id
        end
        deps.update_nearby_inserters(entity, state)
        return current
      end
    end

    if current and current.valid then
      service.destroy(state, current.position, true)
    else
      state.feeder = nil
    end

    if not should_exist and not needs_input then
      return nil
    end

    local position = service.find_position(entity)
    if not position then
      return nil
    end

    local ok, created = pcall(function()
      return entity.surface.create_entity({
        name = deps.feeder_name,
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
      deps.storage_root().feeders[created.unit_number] = state.chip_id
    end
    local inventory = deps.get_inventory(created)
    deps.set_input_open(inventory, deps.get_input_slot_count(state, inventory))
    deps.update_nearby_inserters(entity, state)

    return created
  end

  return service
end

return feeder_lifecycle
