local profile_inventory = {}

function profile_inventory.new(deps)
  local service = {}

  function service.quality_name_from_stack(stack, fallback)
    return deps.compat.quality_name(stack, fallback or "normal", "stack quality")
  end

  function service.quality_name_from_entity(entity, fallback)
    return deps.compat.quality_name(entity, fallback or "normal", "entity quality")
  end

  function service.snapshot_turret_item_state(entity)
    local snapshot = {
      quality = service.quality_name_from_entity(entity, "normal"),
      health_ratio = 1,
      ammo = {},
    }
    if not deps.is_gun_turret(entity) then
      return snapshot
    end

    local health = deps.safe_read(entity, "health")
    local max_health = deps.safe_read(entity, "max_health")
    if health and max_health and max_health > 0 then
      snapshot.health_ratio = math.max(0.01, math.min(1, health / max_health))
    end

    local inventory = deps.get_entity_inventory(entity, deps.inventory_defines.turret_ammo)
    if inventory then
      for index = 1, #inventory do
        local stack = inventory[index]
        if stack and stack.valid_for_read then
          snapshot.ammo[#snapshot.ammo + 1] = {
            name = stack.name,
            count = stack.count,
            quality = service.quality_name_from_stack(stack, "normal"),
            ammo = deps.safe_read(stack, "ammo", nil, "snapshot turret ammo"),
          }
        end
      end
    end

    return snapshot
  end

  function service.clear_turret_ammo_inventory(entity)
    if not deps.is_gun_turret(entity) then
      return
    end

    local inventory = deps.get_entity_inventory(entity, deps.inventory_defines.turret_ammo)
    if not inventory then
      return
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack then
        stack.clear()
      end
    end
  end

  function service.ammo_snapshot_key(name, quality)
    return tostring(name or "") .. "\n" .. tostring(quality or "normal")
  end

  function service.build_desired_turret_ammo_counts(snapshot)
    local desired = {}
    for _, ammo in ipairs((snapshot and snapshot.ammo) or {}) do
      local count = math.max(0, math.floor(tonumber(ammo.count) or 0))
      if ammo.name and count > 0 then
        local quality = ammo.quality or "normal"
        local key = service.ammo_snapshot_key(ammo.name, quality)
        desired[key] = desired[key] or {
          name = ammo.name,
          quality = quality,
          count = 0,
        }
        desired[key].count = desired[key].count + count
      end
    end
    return desired
  end

  function service.build_desired_turret_ammo_stacks(snapshot)
    local desired = {}
    for _, ammo in ipairs((snapshot and snapshot.ammo) or {}) do
      local count = math.max(0, math.floor(tonumber(ammo.count) or 0))
      if ammo.name and count > 0 then
        desired[#desired + 1] = {
          name = ammo.name,
          quality = ammo.quality or "normal",
          count = count,
          ammo = ammo.ammo ~= nil and math.max(0, math.floor(tonumber(ammo.ammo) or 0)) or nil,
        }
      end
    end
    return desired
  end

  function service.make_item_stack_definition(name, count, quality)
    local item = {
      name = name,
      count = count,
    }
    if quality and quality ~= "" then
      item.quality = quality
    end
    return item
  end

  function service.find_turret_ammo_stack(inventory, name, quality)
    if not inventory or not inventory.valid or not name then
      return nil
    end

    local expected_quality = quality or "normal"
    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read and stack.name == name and service.quality_name_from_stack(stack, "normal") == expected_quality then
        return stack
      end
    end

    return nil
  end

  function service.reconcile_preloaded_turret_ammo(entity, inventory, snapshot)
    local desired = service.build_desired_turret_ammo_stacks(snapshot)
    if not inventory or not inventory.valid then
      return desired
    end

    -- Placement-helper mods can preload ammo before the bound turret profile is restored.
    -- Treat that ammo as external and refund it; the bound snapshot remains the source of truth.
    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read then
        local name = stack.name
        local quality = service.quality_name_from_stack(stack, "normal")
        local count = stack.count
        local removed = service.remove_item_from_inventory(inventory, service.make_item_stack_definition(name, count, quality))
        if removed > 0 then
          service.spill_stack_definition_at(entity.surface, entity.position, service.make_item_stack_definition(name, removed, quality))
        end
      end
    end

    return desired
  end

  function service.restore_turret_item_state(entity, snapshot)
    if not deps.is_gun_turret(entity) or type(snapshot) ~= "table" then
      return
    end

    local max_health = deps.safe_read(entity, "max_health")
    if max_health then
      entity.health = math.max(1, math.min(max_health, max_health * (snapshot.health_ratio or 1)))
    end

    local inventory = deps.get_entity_inventory(entity, deps.inventory_defines.turret_ammo)
    if not inventory then
      return
    end

    local remaining = service.reconcile_preloaded_turret_ammo(entity, inventory, snapshot)
    for _, ammo in pairs(remaining) do
      if ammo.name and (ammo.count or 0) > 0 then
        local item = service.make_item_stack_definition(ammo.name, ammo.count, ammo.quality or "normal")
        local inserted = deps.compat.try("restore turret ammo", function()
          return inventory.insert(item)
        end, 0) or 0
        if inserted > 0 and ammo.ammo ~= nil then
          local stack = service.find_turret_ammo_stack(inventory, ammo.name, ammo.quality or "normal")
          if stack then
            pcall(function()
              stack.ammo = ammo.ammo
            end)
          end
        end
        local overflow = (ammo.count or 0) - inserted
        if overflow > 0 then
          service.spill_stack_definition_at(
            entity.surface,
            entity.position,
            service.make_item_stack_definition(ammo.name, overflow, ammo.quality or "normal")
          )
        end
      end
    end
  end

  function service.find_carried_chip_stack(player)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == deps.chip_name then
      return cursor_stack
    end

    local inventory = player.get_main_inventory()
    if not inventory or not inventory.valid then
      return nil
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read and stack.name == deps.chip_name then
        return stack
      end
    end

    return nil
  end

  local function normalize_sort_mode(sort_mode)
    local mode = tostring(sort_mode or "")
    local field, direction = string.match(mode, "^([^:]+):([^:]+)$")
    field = field or mode
    if field ~= "level" and field ~= "kills" and field ~= "damage" and field ~= "name" then
      return "level", "desc", false
    end

    if direction ~= "asc" and direction ~= "desc" then
      direction = field == "name" and "asc" or "desc"
    end

    return field, direction, true
  end

  local function core_option_sort_key(profile)
    profile = profile or {}
    local raw_name = tostring(profile.custom_name or "")
    local normalized_name = raw_name:gsub("^%s+", ""):gsub("%s+$", "")
    return {
      level = math.max(0, math.floor(tonumber(profile.level) or 0)),
      kills = math.max(0, math.floor(tonumber(profile.kills) or 0)),
      damage = math.max(0, math.floor(tonumber(profile.damage) or 0)),
      has_name = normalized_name ~= "",
      name = string.lower(normalized_name),
      chip_id = tonumber(profile.chip_id) or 0,
    }
  end

  local function profile_filter_group(profile)
    local evolution = deps.ensure_evolution_state and deps.ensure_evolution_state(profile or {}) or ((profile or {}).evolution or {})
    local specialization_id = evolution and evolution.specialization or nil
    if specialization_id and deps.specialization_by_id and deps.specialization_by_id[specialization_id] then
      return specialization_id
    end

    return "base"
  end

  local function profile_matches_filters(profile, filters)
    if type(filters) ~= "table" then
      return true
    end

    local group = profile_filter_group(profile)
    if filters[group] == nil then
      return true
    end

    return filters[group] == true
  end

  local function compare_desc(left, right, field)
    if left[field] ~= right[field] then
      return left[field] > right[field]
    end
    return nil
  end

  local function compare_asc(left, right, field)
    if left[field] ~= right[field] then
      return left[field] < right[field]
    end
    return nil
  end

  local function compare_by_direction(left, right, field, direction)
    if direction == "asc" then
      return compare_asc(left, right, field)
    end

    return compare_desc(left, right, field)
  end

  local function compare_named_first(left, right)
    if left.has_name ~= right.has_name then
      return left.has_name
    end
    return nil
  end

  local function sort_core_options(options, sort_mode)
    local sort_field, sort_direction = normalize_sort_mode(sort_mode)
    table.sort(options, function(a, b)
      local left = core_option_sort_key(a.profile)
      local right = core_option_sort_key(b.profile)

      local comparisons = {
        level = {
          function()
            return compare_by_direction(left, right, "level", sort_direction)
          end,
          function()
            return compare_desc(left, right, "kills")
          end,
          function()
            return compare_desc(left, right, "damage")
          end,
          function()
            return compare_named_first(left, right)
          end,
          function()
            return compare_asc(left, right, "name")
          end,
        },
        kills = {
          function()
            return compare_by_direction(left, right, "kills", sort_direction)
          end,
          function()
            return compare_desc(left, right, "level")
          end,
          function()
            return compare_desc(left, right, "damage")
          end,
          function()
            return compare_named_first(left, right)
          end,
          function()
            return compare_asc(left, right, "name")
          end,
        },
        damage = {
          function()
            return compare_by_direction(left, right, "damage", sort_direction)
          end,
          function()
            return compare_desc(left, right, "level")
          end,
          function()
            return compare_desc(left, right, "kills")
          end,
          function()
            return compare_named_first(left, right)
          end,
          function()
            return compare_asc(left, right, "name")
          end,
        },
        name = {
          function()
            return compare_named_first(left, right)
          end,
          function()
            return compare_by_direction(left, right, "name", sort_direction)
          end,
          function()
            return compare_desc(left, right, "level")
          end,
          function()
            return compare_desc(left, right, "kills")
          end,
          function()
            return compare_desc(left, right, "damage")
          end,
        },
      }

      for _, compare in ipairs(comparisons[sort_field] or comparisons.level) do
        local result = compare()
        if result ~= nil then
          return result
        end
      end

      if left.chip_id ~= right.chip_id then
        return left.chip_id < right.chip_id
      end
      return (a.index or 0) < (b.index or 0)
    end)
  end

  function service.get_core_options_from_inventory(inventory, sort_mode, filters)
    local options = {}
    if not inventory or not inventory.valid then
      return options
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read and stack.name == deps.chip_name then
        local profile = deps.read_profile_from_chip_stack(stack)
        if profile_matches_filters(profile, filters) then
          options[#options + 1] = {
            index = index,
            quality = service.quality_name_from_stack(stack, "normal"),
            profile = profile,
          }
        end
      end
    end

    sort_core_options(options, sort_mode)
    return options
  end

  function service.get_player_core_options(player, sort_mode, filters)
    if not player or type(player.get_main_inventory) ~= "function" then
      return {}
    end

    return service.get_core_options_from_inventory(player.get_main_inventory(), sort_mode, filters)
  end

  function service.find_best_carried_chip_stack(player)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == deps.chip_name then
      return cursor_stack
    end

    local inventory = player and type(player.get_main_inventory) == "function" and player.get_main_inventory() or nil
    local options = service.get_core_options_from_inventory(inventory)
    local option = options[1]
    return option and inventory[option.index] or nil
  end

  function service.remove_one_chip_stack(stack)
    if not stack or not stack.valid_for_read or stack.name ~= deps.chip_name then
      return false
    end

    if stack.count and stack.count > 1 then
      stack.count = stack.count - 1
    else
      stack.clear()
    end
    return true
  end

  function service.insert_chip_item(player, profile)
    local stack = deps.make_chip_item_stack(profile)
    local can_insert = deps.compat.try("player can_insert core", function()
      return player.can_insert(stack)
    end, false)

    if not can_insert then
      return false
    end

    local inserted = player.insert(stack)
    return inserted and inserted > 0
  end

  function service.can_insert_chip_inventory(inventory, profile)
    if not inventory or not inventory.valid then
      return false
    end

    local stack = deps.make_chip_item_stack(profile)
    local can_insert = deps.compat.try("inventory can_insert core", function()
      return inventory.can_insert(stack)
    end, false)

    if not can_insert then
      return false
    end

    return true
  end

  function service.get_platform_hub_inventory(entity)
    if not deps.is_gun_turret(entity) then
      return nil
    end

    return deps.compat.platform_hub_inventory(entity, deps.inventory_defines.hub_main)
  end

  function service.get_platform_core_options(entity)
    local options = {}
    local inventory = service.get_platform_hub_inventory(entity)
    if not inventory then
      return options
    end

    for index = 1, #inventory do
      local stack = inventory[index]
      if stack and stack.valid_for_read and stack.name == deps.chip_name then
        options[#options + 1] = {
          index = index,
          quality = service.quality_name_from_stack(stack, "normal"),
          profile = deps.read_profile_from_chip_stack(stack),
        }
      end
    end

    return options
  end

  function service.spill_chip_item(entity, profile)
    if not entity or not entity.valid then
      return false
    end

    local ok = deps.compat.try("spill core item", function()
      entity.surface.spill_item_stack({
        position = entity.position,
        stack = deps.make_chip_item_stack(profile),
        enable_looted = true,
        allow_belts = false,
      })
      return true
    end, false)

    return ok
  end

  function service.spill_stack_definition(entity, stack)
    if not entity or not entity.valid or not stack or not stack.name or (stack.count or 0) <= 0 then
      return false
    end

    return service.spill_stack_definition_at(entity.surface, entity.position, stack)
  end

  function service.spill_stack_definition_at(surface, position, stack)
    if not surface or not position or not stack or not stack.name or (stack.count or 0) <= 0 then
      return false
    end

    local ok = deps.compat.try("spill stack definition", function()
      surface.spill_item_stack({
        position = position,
        stack = stack,
        enable_looted = true,
        allow_belts = false,
      })
      return true
    end, false)
    return ok
  end

  function service.remove_item_from_inventory(inventory, item)
    if not inventory or not inventory.valid or not item or not item.name or (item.count or 0) <= 0 then
      return 0
    end

    local removed = deps.compat.try("inventory remove item", function()
      return inventory.remove(item)
    end, 0)
    if removed and removed > 0 then
      return removed
    end

    local fallback = {
      name = item.name,
      count = item.count,
    }
    removed = deps.compat.try("inventory remove fallback item", function()
      return inventory.remove(fallback)
    end, 0)
    return removed or 0
  end

  return service
end

return profile_inventory
