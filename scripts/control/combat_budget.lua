local combat_budget = {}

local DEFAULT_LIMITS = {
  render_lines_per_surface_tick = 24,
  render_sprites_per_surface_tick = 16,
  visual_entities_per_surface_tick = 12,
  short_effects_per_surface_tick = 12,
  sounds_per_surface_tick = 8,
  status_effect_ticks_per_tick = 256,
  pending_visuals_active = 512,
  visual_entities_active = 512,
}

local SURFACE_BUCKET_LIMITS = {
  render_lines = "render_lines_per_surface_tick",
  render_sprites = "render_sprites_per_surface_tick",
  visual_entities = "visual_entities_per_surface_tick",
  short_effects = "short_effects_per_surface_tick",
  sounds = "sounds_per_surface_tick",
}

local GLOBAL_BUCKET_LIMITS = {
  status_effect_ticks = "status_effect_ticks_per_tick",
}

local function copy_limits(source)
  local limits = {}
  for name, value in pairs(DEFAULT_LIMITS) do
    local configured = source and source[name] or value
    limits[name] = math.max(0, math.floor(tonumber(configured) or value))
  end
  return limits
end

local function surface_index(surface)
  if not surface then
    return "global"
  end

  local index = surface.index
  if type(index) == "number" or type(index) == "string" then
    return tostring(index)
  end

  return "global"
end

local function increment(table_ref, key, amount)
  table_ref[key] = (table_ref[key] or 0) + (amount or 1)
end

function combat_budget.new(deps)
  deps = deps or {}

  local service = {}

  local function limits()
    return copy_limits(deps.get_limits and deps.get_limits() or nil)
  end

  local function storage_root()
    if deps.ensure_storage then
      deps.ensure_storage()
    end

    return deps.get_storage and deps.get_storage() or nil
  end

  local function current_tick()
    return deps.get_tick and deps.get_tick() or 0
  end

  local function budget_state()
    local root = storage_root()
    if not root then
      return nil
    end

    local state = root.combat_effect_budget
    if type(state) ~= "table" then
      state = {}
      root.combat_effect_budget = state
    end

    local tick = current_tick()
    if state.tick ~= tick then
      state.tick = tick
      state.surfaces = {}
      state.global = {}
      state.skipped = {}
    end
    state.surfaces = state.surfaces or {}
    state.global = state.global or {}
    state.skipped = state.skipped or {}

    return state
  end

  local function reserve_from_bucket(bucket, skipped, bucket_name, limit, cost)
    cost = math.max(1, math.floor(tonumber(cost) or 1))
    if limit <= 0 then
      increment(skipped, bucket_name, cost)
      return false
    end

    local used = bucket[bucket_name] or 0
    if used + cost > limit then
      increment(skipped, bucket_name, cost)
      return false
    end

    bucket[bucket_name] = used + cost
    return true
  end

  function service.reserve_surface(surface, bucket_name, cost)
    local limit_name = SURFACE_BUCKET_LIMITS[bucket_name]
    if not limit_name then
      return true
    end

    local state = budget_state()
    if not state then
      return true
    end

    local index = surface_index(surface)
    local surface_bucket = state.surfaces[index]
    if type(surface_bucket) ~= "table" then
      surface_bucket = {}
      state.surfaces[index] = surface_bucket
    end

    return reserve_from_bucket(surface_bucket, state.skipped, bucket_name, limits()[limit_name], cost)
  end

  function service.reserve_global(bucket_name, cost)
    local limit_name = GLOBAL_BUCKET_LIMITS[bucket_name]
    if not limit_name then
      return true
    end

    local state = budget_state()
    if not state then
      return true
    end

    return reserve_from_bucket(state.global, state.skipped, bucket_name, limits()[limit_name], cost)
  end

  function service.allow_active(active_name, current_count)
    local limit = limits()[active_name]
    if not limit or limit <= 0 then
      return true
    end

    if (current_count or 0) >= limit then
      local state = budget_state()
      if state then
        increment(state.skipped, active_name, 1)
      end
      return false
    end

    return true
  end

  function service.reset()
    local root = storage_root()
    if root then
      root.combat_effect_budget = {
        tick = current_tick(),
        surfaces = {},
        global = {},
        skipped = {},
      }
    end
  end

  function service.snapshot()
    local state = budget_state() or {}
    return {
      tick = state.tick,
      limits = limits(),
      surfaces = state.surfaces or {},
      global = state.global or {},
      skipped = state.skipped or {},
    }
  end

  return service
end

return combat_budget
