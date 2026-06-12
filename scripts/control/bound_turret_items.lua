local bound_turret_items = {}

function bound_turret_items.new(deps)
  local service = {}

  function service.description(profile)
    profile = deps.normalize_profile(profile)
    local name = profile.custom_name or ""
    local base_description
    if name ~= "" then
      base_description = { "item-description.turret-xp-bound-gun-turret-profile-named", name, profile.level or 0 }
    else
      base_description = { "item-description.turret-xp-bound-gun-turret-profile", profile.level or 0 }
    end

    return deps.profile_description_with_build(base_description, profile)
  end

  function service.make_stack(profile, turret_snapshot)
    profile = deps.normalize_profile(profile)
    profile.bound_turret = true
    local serialized = deps.serialize_profile(profile)
    turret_snapshot = turret_snapshot or {}
    return {
      name = deps.get_bound_turret_item_name(profile),
      count = 1,
      quality = turret_snapshot.quality or "normal",
      tags = {
        [deps.profile_tag] = serialized,
        [deps.bound_turret_tag] = deps.copy_serializable(turret_snapshot),
      },
      custom_description = service.description(serialized),
    }
  end

  function service.read_stack(stack)
    if not stack or not stack.valid_for_read or not deps.is_bound_turret_item_name(stack.name) then
      return nil, nil
    end

    local profile_data = nil
    local turret_data = nil
    pcall(function()
      profile_data = stack.get_tag(deps.profile_tag)
    end)
    pcall(function()
      turret_data = stack.get_tag(deps.bound_turret_tag)
    end)

    local profile = deps.deserialize_profile(profile_data)
    profile.bound_turret = true
    turret_data = type(turret_data) == "table" and deps.copy_serializable(turret_data) or {}
    turret_data.quality = deps.quality_name_from_stack(stack, turret_data.quality or "normal")
    turret_data.ammo = type(turret_data.ammo) == "table" and turret_data.ammo or {}
    return deps.normalize_profile(profile), turret_data
  end

  function service.find_stack_in_inventory(inventory)
    if not inventory or not inventory.valid then
      return nil
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read and deps.is_bound_turret_item_name(stack.name) then
        return stack
      end
    end

    return nil
  end

  function service.stack_from_build_event(event)
    if event.stack and event.stack.valid_for_read and deps.is_bound_turret_item_name(event.stack.name) then
      return event.stack
    end

    return service.find_stack_in_inventory(event.consumed_items)
  end

  function service.remove_mining_results(buffer, turret_snapshot)
    deps.remove_item_from_inventory(buffer, {
      name = deps.base_turret_name,
      count = 1,
      quality = turret_snapshot and turret_snapshot.quality or "normal",
    })

    for _, ammo in ipairs((turret_snapshot and turret_snapshot.ammo) or {}) do
      deps.remove_item_from_inventory(buffer, {
        name = ammo.name,
        count = ammo.count,
        quality = ammo.quality or "normal",
      })
    end
  end

  function service.insert_item(inventory, entity, profile, turret_snapshot)
    local stack = service.make_stack(profile, turret_snapshot)
    local inserted = 0
    if inventory and inventory.valid then
      local ok, result = pcall(function()
        return inventory.insert(stack)
      end)
      if ok and result then
        inserted = result
      end
    end

    if inserted > 0 then
      return true
    end

    return deps.spill_stack_definition(entity, stack)
  end

  return service
end

return bound_turret_items
