local combat_targeting = {}

function combat_targeting.new(deps)
  local service = {}
  local safe_read = deps.safe_read

  function service.chance_roll(chance)
    chance = math.max(0, math.min(0.95, chance or 0))
    return chance > 0 and math.random() < chance
  end

  function service.get_distance(a, b)
    if not a or not b then
      return 0
    end

    local dx = (a.x or a[1] or 0) - (b.x or b[1] or 0)
    local dy = (a.y or a[2] or 0) - (b.y or b[2] or 0)
    return math.sqrt((dx * dx) + (dy * dy))
  end

  function service.find_nearby_enemy(surface, position, force, radius, exclude)
    if not surface or not position then
      return nil
    end

    local entities = surface.find_entities_filtered({
      area = {
        { position.x - radius, position.y - radius },
        { position.x + radius, position.y + radius },
      },
    })

    for _, entity in pairs(entities) do
      local excluded = entity == exclude
      if type(exclude) == "table" and not exclude.valid then
        local unit_number = safe_read(entity, "unit_number")
        excluded = excluded or exclude[unit_number] == true or exclude[deps.entity_tracking_key(entity)] == true
      end
      if
        entity.valid
        and not excluded
        and safe_read(entity, "health")
        and entity.force ~= force
        and service.get_distance(position, entity.position) <= radius
      then
        return entity
      end
    end

    return nil
  end

  function service.get_active_elements(state)
    local evolution = deps.ensure_evolution_state(state)
    local elements = {}
    for slot = 1, 2 do
      if evolution.elements[slot] then
        elements[#elements + 1] = evolution.elements[slot]
      end
    end
    return elements
  end

  function service.has_element_pair(state, a, b)
    local elements = service.get_active_elements(state)
    if #elements < 2 then
      return false
    end

    return (elements[1] == a and elements[2] == b) or (elements[1] == b and elements[2] == a)
  end

  function service.combo_descriptor_is_active(state, flags, descriptor)
    return descriptor
      and flags
      and flags[descriptor.flags[1]]
      and flags[descriptor.flags[2]]
      and service.has_element_pair(state, descriptor.elements[1], descriptor.elements[2])
  end

  return service
end

return combat_targeting
