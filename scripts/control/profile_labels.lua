local profile_labels = {}

local SHIELD_BAR_RENDER_VERSION = 3
local SHIELD_BAR_SEGMENTS = 9
local SHIELD_BAR_PIXELS_PER_TILE = 32
local SHIELD_BAR_PIP_SIZE_TILES = 7 / SHIELD_BAR_PIXELS_PER_TILE
local SHIELD_BAR_WIDTH_TILES = SHIELD_BAR_SEGMENTS * SHIELD_BAR_PIP_SIZE_TILES
local SHIELD_BAR_CENTER_X_NUDGE_TILES = -0.5 / SHIELD_BAR_PIXELS_PER_TILE
local SHIELD_BAR_LEFT_PIP_X = (-SHIELD_BAR_WIDTH_TILES / 2) + (SHIELD_BAR_PIP_SIZE_TILES / 2) + SHIELD_BAR_CENTER_X_NUDGE_TILES
-- Factorio exposes the native bar pip sprites, but not the engine-owned HP bar anchor.
-- These nudges keep the shield row calibrated just below a gun turret's native HP row.
local SHIELD_BAR_PIP_Y = 1.24 + (5 / SHIELD_BAR_PIXELS_PER_TILE)
local SHIELD_BAR_FILLED_SPRITE = "utility/shield_bar_pip"
local SHIELD_BAR_EMPTY_SPRITE = "utility/bar_gray_pip"
local SHIELD_BAR_GUI_VISIBLE_TICKS = 90
local SHIELD_BAR_DAMAGE_VISIBLE_TICKS = 180

function profile_labels.new(deps)
  local service = {}

  function service.destroy_name_render(profile)
    if profile and profile.name_render and profile.name_render.valid then
      profile.name_render.destroy()
    end
    if profile and profile.label_entity and profile.label_entity.valid then
      pcall(function()
        profile.label_entity.destroy({ raise_destroy = false })
      end)
    end
    if profile then
      profile.name_render = nil
      profile.label_entity = nil
    end
  end

  local function destroy_render_object(object)
    if object and object.valid then
      object.destroy()
    end
  end

  function service.destroy_shield_bar_render(profile)
    local bar = profile and profile.shield_bar or nil
    if bar then
      if type(bar.segments) == "table" then
        for _, segment in pairs(bar.segments) do
          if type(segment) == "table" then
            destroy_render_object(segment.object)
            destroy_render_object(segment.background)
            destroy_render_object(segment.fill)
            destroy_render_object(segment.border)
          end
        end
      end
      -- Clean up stale handles from earlier dev builds that rendered a custom HP row
      -- or a single solid shield bar.
      destroy_render_object(bar.health_background)
      destroy_render_object(bar.health_fill)
      destroy_render_object(bar.health_border)
      destroy_render_object(bar.shield_background)
      destroy_render_object(bar.shield_fill)
      destroy_render_object(bar.shield_border)
      destroy_render_object(bar.background)
      destroy_render_object(bar.fill)
      destroy_render_object(bar.border)
    end

    if profile then
      profile.shield_bar = nil
    end
  end

  function service.shield_bar_visible_for_damage(profile)
    local tick = deps.game_tick()
    if not profile or not tick then
      return
    end

    profile._shield_bar_visible_until = math.max(tonumber(profile._shield_bar_visible_until) or 0, tick + SHIELD_BAR_DAMAGE_VISIBLE_TICKS)
  end

  local function shield_bar_target(entity, x, y)
    return {
      entity = entity,
      offset = { x, y },
    }
  end

  local function draw_shield_bar_pip(entity, sprite, x, y)
    local ok, object = pcall(function()
      return deps.rendering_api().draw_sprite({
        surface = entity.surface,
        sprite = sprite,
        target = shield_bar_target(entity, x, y),
        x_scale = 1,
        y_scale = 1,
        render_layer = "air-object",
        forces = { entity.force },
        only_in_alt_mode = false,
      })
    end)

    return ok and object or nil
  end

  local function update_shield_bar_pip(segment, entity, sprite, x, y)
    local object = segment.object
    if object and object.valid then
      local ok = pcall(function()
        object.surface = entity.surface
        object.sprite = sprite
        object.target = shield_bar_target(entity, x, y)
        object.x_scale = 1
        object.y_scale = 1
        object.render_layer = "air-object"
        object.forces = { entity.force }
        object.only_in_alt_mode = false
      end)
      if ok then
        segment.sprite = sprite
        return object
      end
      destroy_render_object(object)
    end

    object = draw_shield_bar_pip(entity, sprite, x, y)
    segment.object = object
    segment.sprite = sprite
    return object
  end

  local function discard_legacy_shield_bar_handles(bar)
    if bar._shield_bar_render_version == SHIELD_BAR_RENDER_VERSION then
      return
    end

    if type(bar.segments) == "table" then
      for _, segment in pairs(bar.segments) do
        if type(segment) == "table" then
          destroy_render_object(segment.object)
          destroy_render_object(segment.background)
          destroy_render_object(segment.fill)
          destroy_render_object(segment.border)
          segment.object = nil
          segment.background = nil
          segment.fill = nil
          segment.border = nil
        end
      end
    end
    destroy_render_object(bar.health_background)
    destroy_render_object(bar.health_fill)
    destroy_render_object(bar.health_border)
    destroy_render_object(bar.shield_background)
    destroy_render_object(bar.shield_fill)
    destroy_render_object(bar.shield_border)
    destroy_render_object(bar.background)
    destroy_render_object(bar.fill)
    destroy_render_object(bar.border)
    bar.health_background = nil
    bar.health_fill = nil
    bar.health_border = nil
    bar.shield_background = nil
    bar.shield_fill = nil
    bar.shield_border = nil
    bar.background = nil
    bar.fill = nil
    bar.border = nil
    bar._shield_bar_render_version = SHIELD_BAR_RENDER_VERSION
  end

  local function update_segmented_shield_bar(bar, entity, shield_ratio)
    discard_legacy_shield_bar_handles(bar)

    if type(bar.segments) ~= "table" then
      bar.segments = {}
    end

    local filled_segments = 0
    if shield_ratio > 0 then
      filled_segments = math.max(1, math.min(SHIELD_BAR_SEGMENTS, math.ceil(shield_ratio * SHIELD_BAR_SEGMENTS)))
    end

    for index = 1, SHIELD_BAR_SEGMENTS do
      local segment = bar.segments[index]
      if type(segment) ~= "table" then
        segment = {}
        bar.segments[index] = segment
      end

      local filled = index <= filled_segments
      local sprite = filled and SHIELD_BAR_FILLED_SPRITE or SHIELD_BAR_EMPTY_SPRITE
      local x = SHIELD_BAR_LEFT_PIP_X + ((index - 1) * SHIELD_BAR_PIP_SIZE_TILES)
      update_shield_bar_pip(segment, entity, sprite, x, SHIELD_BAR_PIP_Y)
      segment.filled = filled
    end

    for index = SHIELD_BAR_SEGMENTS + 1, #bar.segments do
      local segment = bar.segments[index]
      if type(segment) == "table" then
        destroy_render_object(segment.object)
        destroy_render_object(segment.background)
        destroy_render_object(segment.fill)
        destroy_render_object(segment.border)
      end
      bar.segments[index] = nil
    end
  end

  function service.update_shield_bar_render(entity, profile, force_visible)
    if not profile then
      return
    end

    if not deps.is_gun_turret(entity) then
      service.destroy_shield_bar_render(profile)
      return
    end

    local shield, capacity = deps.normalize_shield_state(profile, true)
    if capacity <= 0 then
      service.destroy_shield_bar_render(profile)
      return
    end

    local tick = deps.game_tick() or 0
    if force_visible then
      profile._shield_bar_visible_until = math.max(tonumber(profile._shield_bar_visible_until) or 0, tick + SHIELD_BAR_GUI_VISIBLE_TICKS)
    end

    local visible_until = tonumber(profile._shield_bar_visible_until) or 0
    if not force_visible and shield >= capacity and visible_until < tick then
      service.destroy_shield_bar_render(profile)
      return
    end

    local shield_ratio = math.max(0, math.min(1, shield / capacity))
    local bar = profile.shield_bar
    if type(bar) ~= "table" then
      bar = {}
      profile.shield_bar = bar
    end
    update_segmented_shield_bar(bar, entity, shield_ratio)

    local first_segment = bar.segments and bar.segments[1] or nil
    bar.background = first_segment and first_segment.object or nil
    bar.fill = first_segment and first_segment.filled and first_segment.object or nil
    bar.border = first_segment and first_segment.object or nil

    if not first_segment or not first_segment.object then
      service.destroy_shield_bar_render(profile)
    end
  end

  function service.find_matching_label_color_preset(profile)
    if not profile then
      return nil
    end

    if profile.label_color_preset and profile.label_color_preset ~= "custom" then
      local preset = deps.label_colors.preset_by_id(profile.label_color_preset)
      if preset then
        return preset
      end
    end

    if profile.label_color_preset == "custom" then
      return nil
    end

    return deps.label_colors.preset_from_color(profile.label_color)
  end

  function service.get_profile_label_text(profile)
    profile = deps.normalize_profile(profile)
    local name = profile.custom_name or ""
    if name == "" then
      return nil
    end

    if profile.show_label_level == false then
      return name
    end

    return name .. " (lvl " .. tostring(profile.level or 0) .. ")"
  end

  function service.update_name_render(entity, profile)
    if not profile then
      return
    end

    if not deps.is_gun_turret(entity) or not profile.show_name_label then
      service.destroy_name_render(profile)
      return
    end

    local text = service.get_profile_label_text(profile)
    if not text then
      service.destroy_name_render(profile)
      return
    end

    if profile.label_entity and profile.label_entity.valid then
      pcall(function()
        profile.label_entity.destroy({ raise_destroy = false })
      end)
    end
    profile.label_entity = nil

    if profile.name_render and profile.name_render.valid then
      local ok = pcall(function()
        profile.name_render.text = text
        profile.name_render.target = {
          entity = entity,
          offset = { 0, -2.05 },
        }
        profile.name_render.surface = entity.surface
        profile.name_render.forces = { entity.force }
        profile.name_render.color = profile.label_color or { 1, 0.86, 0.46 }
        profile.name_render.scale = profile.label_scale or 2
      end)
      if ok then
        return
      end
      service.destroy_name_render(profile)
    end

    local ok, render_object = pcall(function()
      return deps.rendering_api().draw_text({
        text = text,
        surface = entity.surface,
        target = {
          entity = entity,
          offset = { 0, -2.05 },
        },
        color = profile.label_color or { 1, 0.86, 0.46 },
        scale = profile.label_scale or 2,
        font = "default-bold",
        alignment = "center",
        vertical_alignment = "middle",
        scale_with_zoom = true,
        only_in_alt_mode = false,
        forces = { entity.force },
      })
    end)

    if ok then
      profile.name_render = render_object
    end
  end

  return service
end

return profile_labels
