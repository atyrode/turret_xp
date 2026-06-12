local support = {
  IFACE = "turret_xp_test",
  PASS_TICK = 900,
  TEST_PREFIX = "[turret_xp_headless_tests] "
}

function support.fail(message)
  error(support.TEST_PREFIX .. message, 2)
end

function support.assert_true(condition, message)
  if not condition then
    support.fail(message)
  end
end

function support.assert_eq(actual, expected, message)
  if actual ~= expected then
    support.fail(message .. " (expected " .. serpent.line(expected) .. ", got " .. serpent.line(actual) .. ")")
  end
end

function support.assert_gt(actual, minimum, message)
  if not actual or actual <= minimum then
    support.fail(message .. " (expected > " .. tostring(minimum) .. ", got " .. tostring(actual) .. ")")
  end
end

function support.assert_ge(actual, minimum, message)
  if not actual or actual < minimum then
    support.fail(message .. " (expected >= " .. tostring(minimum) .. ", got " .. tostring(actual) .. ")")
  end
end

function support.assert_near(actual, expected, epsilon, message)
  if not actual or math.abs(actual - expected) > (epsilon or 0.0001) then
    support.fail(message .. " (expected near " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
  end
end

function support.list_count(list, value)
  local count = 0
  for _, entry in ipairs(list or {}) do
    if entry == value then
      count = count + 1
    end
  end
  return count
end

function support.assert_contains(list, value, message)
  if support.list_count(list, value) <= 0 then
    support.fail(message .. " (missing " .. serpent.line(value) .. " in " .. serpent.line(list or {}) .. ")")
  end
end

function support.area_around(position, radius)
  return {
    { position.x - radius, position.y - radius },
    { position.x + radius, position.y + radius }
  }
end

function support.get_surface()
  return game.surfaces.nauvis or game.surfaces[1]
end

function support.clear_test_area(surface)
  for _, entity in pairs(surface.find_entities_filtered({ area = support.area_around({ x = 0, y = 0 }, 96) })) do
    if entity.valid and entity.type ~= "character" and entity.type ~= "player" then
      entity.destroy()
    end
  end
end

function support.inventory_count(inventory, item_name)
  if not inventory or not inventory.valid then
    return 0
  end

  return inventory.get_item_count(item_name)
end

function support.ground_item_count(surface, position, item_name, radius)
  local count = 0
  for _, entity in pairs(surface.find_entities_filtered({
    area = support.area_around(position, radius or 1.5),
    type = "item-entity"
  })) do
    local stack = entity.valid and entity.stack or nil
    if stack and stack.valid_for_read and stack.name == item_name then
      count = count + stack.count
    end
  end
  return count
end

function support.find_ground_stack(surface, position, item_name, radius)
  for _, entity in pairs(surface.find_entities_filtered({
    area = support.area_around(position, radius or 1.5),
    type = "item-entity"
  })) do
    local stack = entity.valid and entity.stack or nil
    if stack and stack.valid_for_read and stack.name == item_name then
      return stack
    end
  end

  return nil
end

function support.find_stack(inventory, item_name)
  for index = 1, #inventory do
    local stack = inventory[index]
    if stack and stack.valid_for_read and stack.name == item_name then
      return stack
    end
  end

  return nil
end

function support.create_turret(surface, position, ammo_count)
  local turret = surface.create_entity({
    name = "gun-turret",
    position = position,
    force = "player",
    raise_built = false
  })
  support.assert_true(turret and turret.valid, "failed to create test gun turret")
  if ammo_count and ammo_count > 0 then
    turret.insert({ name = "firearm-magazine", count = ammo_count })
  end
  return turret
end

function support.find_turret_near(surface, position)
  local entities = surface.find_entities_filtered({
    area = support.area_around(position, 0.75),
    type = "ammo-turret"
  })
  for _, entity in pairs(entities) do
    if entity.valid and string.find(entity.name, "gun-turret", 1, true) then
      return entity
    end
  end

  return nil
end

function support.require_turret_near(surface, position, message)
  local turret = support.find_turret_near(surface, position)
  support.assert_true(turret ~= nil, message)
  return turret
end

function support.call(method, ...)
  support.assert_true(remote.interfaces[support.IFACE] ~= nil, "missing Turret XP headless test remote interface")
  support.assert_true(remote.interfaces[support.IFACE][method] ~= nil, "missing Turret XP headless test method " .. method)
  return remote.call(support.IFACE, method, ...)
end

return support
