local compat = {}

function compat.new(deps)
  deps = deps or {}
  local service = {}
  local reported = {}

  local function diagnostics_enabled()
    local enabled = deps.diagnostics_enabled
    return type(enabled) == "function" and enabled() == true
  end

  local function report(context, err)
    if not diagnostics_enabled() then
      return
    end

    local key = tostring(context or "unknown") .. "\n" .. tostring(err or "unknown")
    if reported[key] then
      return
    end
    reported[key] = true

    log("[turret_xp][compat] " .. tostring(context or "unknown") .. ": " .. tostring(err or "unknown"))
  end

  function service.try(context, callback, fallback)
    if type(callback) ~= "function" then
      return fallback
    end

    local ok, value = pcall(callback)
    if ok then
      if value == nil and fallback ~= nil then
        return fallback
      end
      return value
    end

    report(context, value)
    return fallback
  end

  function service.safe_read(object, property, fallback, context)
    if object == nil then
      return fallback
    end

    return service.try(context or ("read " .. tostring(property)), function()
      return object[property]
    end, fallback)
  end

  function service.quality_name(object, fallback, context)
    local quality = service.safe_read(object, "quality", nil, context or "quality")
    local name = quality and service.safe_read(quality, "name", nil, (context or "quality") .. ".name") or nil
    return name or fallback or "normal"
  end

  function service.get_entity_inventory(entity, inventory_id, context)
    if not entity or not entity.valid or not inventory_id then
      return nil
    end

    local inventory = service.try(context or ("get_inventory " .. tostring(inventory_id)), function()
      return entity.get_inventory(inventory_id)
    end)
    if inventory and inventory.valid then
      return inventory
    end

    return nil
  end

  function service.prototype_exists(prototype_table, name, context)
    if not prototype_table or not name then
      return false
    end

    return service.safe_read(prototype_table, name, nil, context or ("prototype " .. tostring(name))) ~= nil
  end

  function service.platform_hub_inventory(entity, inventory_id)
    local surface = service.safe_read(entity, "surface", nil, "platform surface")
    local platform = surface and service.safe_read(surface, "platform", nil, "platform surface.platform") or nil
    local hub = platform and service.safe_read(platform, "hub", nil, "platform hub") or nil
    return service.get_entity_inventory(hub, inventory_id, "platform hub inventory")
  end

  return service
end

return compat
