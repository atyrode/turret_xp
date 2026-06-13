local profile_schema = {}

local DEFAULT_LABEL_COLOR = { 1, 0.86, 0.46 }

local function default_label_color()
  return { DEFAULT_LABEL_COLOR[1], DEFAULT_LABEL_COLOR[2], DEFAULT_LABEL_COLOR[3] }
end

function profile_schema.new(deps)
  local service = {}

  function service.create_blank_profile()
    return {
      xp = 0,
      total_xp = 0,
      level = 0,
      kills = 0,
      kill_credit = 0,
      damage = 0,
      xp_damage = 0,
      xp_kill_credit = 0,
      evolution = {},
      chip_quality = "normal",
      custom_name = "",
      show_name_label = false,
      show_label_level = true,
      label_color = default_label_color(),
      label_color_preset = "gold",
      label_scale = 2,
      bound_turret = false,
      last_ammo = nil,
      ammo_productivity_progress = 0,
      shield = 0,
    }
  end

  function service.normalize_profile(profile)
    if type(profile) ~= "table" then
      profile = service.create_blank_profile()
    end

    profile.xp = profile.xp or 0
    profile.total_xp = profile.total_xp or 0
    profile.level = math.max(0, math.floor(tonumber(profile.level) or 0))
    profile.kills = profile.kills or 0
    profile.kill_credit = profile.kill_credit or profile.kills or 0
    profile.damage = profile.damage or 0
    deps.ensure_xp_counters(profile)
    profile.dev_xp = profile.dev_xp or 0
    profile.chip_quality = profile.chip_quality or "normal"
    profile.custom_name = profile.custom_name or ""
    profile.show_name_label = profile.show_name_label == true
    profile.show_label_level = profile.show_label_level ~= false
    profile.bound_turret = profile.bound_turret == true
    profile.ammo_productivity_progress = math.max(0, tonumber(profile.ammo_productivity_progress or profile.ammo_regen_progress) or 0)
    profile.ammo_regen_progress = nil
    if type(profile.last_ammo) == "table" and deps.is_ammo_item(profile.last_ammo.name) then
      profile.last_ammo = {
        name = profile.last_ammo.name,
        quality = profile.last_ammo.quality or "normal",
      }
    else
      profile.last_ammo = nil
    end
    if type(profile.label_color) ~= "table" then
      profile.label_color = default_label_color()
    end
    if profile.label_color_preset ~= "custom" and not deps.label_colors.preset_by_id(profile.label_color_preset) then
      local preset = deps.label_colors.preset_from_color(profile.label_color)
      profile.label_color_preset = preset and preset.id or "custom"
    end
    profile.label_scale = 2
    deps.ensure_evolution_state(profile)
    profile.skills = nil
    deps.normalize_shield_state(profile, true)
    deps.sync_turret_progression(profile)
    return profile
  end

  function service.copy_serializable(value)
    if type(value) ~= "table" then
      return value
    end

    local result = {}
    for key, child in pairs(value) do
      local skip_runtime_key = type(key) == "string" and string.sub(key, 1, 1) == "_"
      if
        not skip_runtime_key
        and key ~= "entity"
        and key ~= "name_render"
        and key ~= "label_entity"
        and key ~= "shield_bar"
        and key ~= "feeder"
      then
        result[key] = service.copy_serializable(child)
      end
    end
    return result
  end

  function service.serialize_profile(profile)
    profile = service.normalize_profile(profile)
    local evolution = deps.ensure_evolution_state(profile)

    return {
      schema = 1,
      chip_id = profile.chip_id,
      chip_quality = profile.chip_quality or "normal",
      custom_name = profile.custom_name or "",
      show_name_label = profile.show_name_label == true,
      show_label_level = profile.show_label_level ~= false,
      bound_turret = profile.bound_turret == true,
      label_color = service.copy_serializable(profile.label_color or default_label_color()),
      label_color_preset = profile.label_color_preset or "custom",
      label_scale = profile.label_scale or 2,
      xp = profile.xp or 0,
      total_xp = profile.total_xp or 0,
      level = profile.level or 0,
      kills = profile.kills or 0,
      kill_credit = profile.kill_credit or 0,
      damage = profile.damage or 0,
      xp_damage = profile.xp_damage or profile.damage or 0,
      xp_kill_credit = profile.xp_kill_credit or profile.kill_credit or 0,
      dev_xp = profile.dev_xp or 0,
      last_ammo = service.copy_serializable(profile.last_ammo),
      ammo_productivity_progress = profile.ammo_productivity_progress or 0,
      shield = deps.normalize_shield_state(profile, true),
      evolution = {
        base = service.copy_serializable(evolution.base or {}),
        augments = service.copy_serializable(evolution.augments or {}),
        element_mastery = service.copy_serializable(evolution.element_mastery or {}),
        elements = {
          evolution.elements and evolution.elements[1] or nil,
          evolution.elements and evolution.elements[2] or nil,
        },
        specialization = evolution.specialization,
        sub_specialization = evolution.sub_specialization,
      },
    }
  end

  function service.deserialize_profile(data)
    local profile = service.create_blank_profile()
    if type(data) == "table" then
      profile.chip_id = data.chip_id
      profile.chip_quality = data.chip_quality or "normal"
      profile.custom_name = data.custom_name or ""
      profile.show_name_label = data.show_name_label == true
      profile.show_label_level = data.show_label_level ~= false
      profile.bound_turret = data.bound_turret == true
      profile.label_color = service.copy_serializable(data.label_color or default_label_color())
      profile.label_color_preset = data.label_color_preset or nil
      profile.label_scale = data.label_scale or 2
      profile.xp = data.xp or 0
      profile.total_xp = data.total_xp or 0
      profile.level = data.level or 0
      profile.kills = data.kills or 0
      profile.kill_credit = data.kill_credit or data.kills or 0
      profile.damage = data.damage or 0
      profile.xp_damage = data.xp_damage
      profile.xp_kill_credit = data.xp_kill_credit
      profile.dev_xp = data.dev_xp or 0
      profile.last_ammo = service.copy_serializable(data.last_ammo)
      profile.ammo_productivity_progress = data.ammo_productivity_progress or data.ammo_regen_progress or 0
      profile.shield = data.shield
      profile.evolution = service.copy_serializable(data.evolution or {})
    end

    if type(profile.evolution) ~= "table" then
      profile.evolution = {}
    end

    return service.normalize_profile(profile)
  end

  return service
end

return profile_schema
