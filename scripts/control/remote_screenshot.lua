return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  local INTERFACE_NAME = "turret_xp_screenshot"
  local DEFAULT_POSITION = { x = 0, y = 0 }

  local function level_dev_xp(level)
    local target_level = math.max(0, math.floor(tonumber(level) or 0))
    local total = 0
    for current = 0, target_level - 1 do
      total = total + xp_required(current)
    end
    return total
  end

  local function clear_scene(surface, position)
    local area = {
      { position.x - 8, position.y - 8 },
      { position.x + 8, position.y + 8 },
    }

    for _, entity in pairs(surface.find_entities_filtered({ area = area })) do
      if entity.valid and entity.type ~= "character" then
        entity.destroy()
      end
    end
  end

  local function create_scene_turret(surface, position)
    clear_scene(surface, position)
    local turret = surface.create_entity({
      name = BASE_TURRET_NAME,
      position = position,
      force = "player",
      raise_built = false,
    })

    if turret and turret.valid then
      turret.insert({ name = "piercing-rounds-magazine", count = 10 })
    end

    return turret
  end

  local function apply_evolution(profile, evolution_fields)
    local evolution = ensure_evolution_state(profile)
    evolution_fields = type(evolution_fields) == "table" and evolution_fields or {}

    evolution.base = copy_serializable(evolution_fields.base or {
      damage = 8,
      resistance = 6,
      shield = 10,
      ammo_regen = 5,
      crit_chance = 7,
      crit_damage = 9,
    })
    evolution.augments = copy_serializable(evolution_fields.augments or {
      repair = 4,
      bounce = 3,
      double_shot = 3,
      siphon = 4,
      luck = 5,
      veteran_training = 4,
    })
    evolution.elements = copy_serializable(evolution_fields.elements or {
      "fire",
      "electric",
    })
    evolution.element_mastery = copy_serializable(evolution_fields.element_mastery or {
      fire = { rank = 3, delivered = 1400 },
      electric = { rank = 2, delivered = 420 },
    })
    evolution.specialization = evolution_fields.specialization or "sniper"
    evolution.sub_specialization = evolution_fields.sub_specialization or "sniper_deadeye"
    evolution.element_project = copy_serializable(evolution_fields.element_project)

    ensure_evolution_state(profile)
  end

  local function build_profile(scene)
    scene = type(scene) == "table" and scene or {}

    local profile = create_blank_profile()
    profile.custom_name = scene.custom_name or "Aegis North"
    profile.show_name_label = scene.show_name_label ~= false
    profile.show_label_level = scene.show_label_level ~= false
    profile.label_color_preset = scene.label_color_preset or "gold"
    profile.label_color = copy_serializable(scene.label_color or { 1, 0.86, 0.46 })
    profile.dev_xp = level_dev_xp(scene.level or 54)
    profile.kills = scene.kills or 286
    profile.kill_credit = scene.kill_credit or profile.kills
    profile.damage = scene.damage or 184275
    profile.xp_damage = scene.xp_damage or profile.damage
    profile.xp_kill_credit = scene.xp_kill_credit or profile.kill_credit
    profile.ammo_productivity_progress = scene.ammo_productivity_progress or 0.62

    apply_evolution(profile, scene.evolution)
    normalize_profile(profile)
    sync_turret_progression(profile)
    return profile
  end

  local function resolve_player(player_index)
    local index = tonumber(player_index) or 1
    local player = game.get_player(index)
    if player then
      return player
    end

    for _, candidate in pairs(game.players or {}) do
      if candidate then
        return candidate
      end
    end

    return nil
  end

  local function panel_metadata(player)
    local panel = get_gui_panel(player)
    if not panel or not panel.valid then
      return {
        valid = false,
      }
    end

    local location = panel.location or { x = 0, y = 0 }
    local size = panel.actual_size or { width = 0, height = 0 }
    return {
      valid = true,
      name = panel.name,
      location = { x = location.x or 0, y = location.y or 0 },
      actual_size = { width = size.width or 0, height = size.height or 0 },
      child_count = #panel.children,
    }
  end

  remote.add_interface(INTERFACE_NAME, {
    open_panel = function(player_index, scene)
      local player = resolve_player(player_index)
      if not player then
        return nil
      end

      local position = scene and scene.position or DEFAULT_POSITION
      local surface = player.surface or game.surfaces[1]
      local turret = create_scene_turret(surface, position)
      if not turret or not turret.valid then
        return nil
      end

      local profile = build_profile(scene)
      local installed = install_profile_on_turret(turret, profile)
      local entity = installed and (combat.sync_turret_body_when_idle(turret, installed) or turret) or turret

      if entity and entity.valid then
        player.teleport({ position.x, position.y + 4 }, entity.surface)
        player.opened = entity
        build_turret_gui(player, entity)
      end

      return {
        panel = panel_metadata(player),
        entity_name = entity and entity.valid and entity.name or nil,
        position = entity and entity.valid and { x = entity.position.x, y = entity.position.y } or nil,
      }
    end,
    panel_metadata = function(player_index)
      local player = resolve_player(player_index)
      if not player then
        return {
          valid = false,
        }
      end

      return panel_metadata(player)
    end,
  })
end
