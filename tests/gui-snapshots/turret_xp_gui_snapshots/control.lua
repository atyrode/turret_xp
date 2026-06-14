local IFACE = "turret_xp_test"
local PREFIX = "[turret_xp_gui_snapshots] "
local SURFACE_NAME = "turret-xp-gui-snapshots"
local OUTPUT_ROOT = "turret_xp/gui-snapshots/latest"
local CHIP_NAME = "turret-xp-veteran-core"
local DEFAULT_CAPTURE_RESOLUTION = { x = 1600, y = 1000 }
local MAX_CAPTURE_RESOLUTION = 8192

local SCENES = {
  {
    id = "empty-picker",
    description = "Empty turret with sample Veteran Cores in player inventory.",
    mode = "empty",
  },
  {
    id = "installed-basic",
    description = "Installed named core with label and bound action state.",
    profile = {
      custom_name = "Rampart",
      level = 12,
      kills = 42,
      damage = 18600,
      show_name_label = true,
      show_label_level = true,
      label_color_preset = "gold",
      label_color = { 1, 0.86, 0.46 },
      bound_turret = true,
    },
    evolution = {
      base = {
        damage = 4,
        attack_speed = 3,
        hp = 2,
      },
    },
  },
  {
    id = "evolution-choices",
    description = "High-level unspent core showing available Evolution choices.",
    profile = {
      custom_name = "Unassigned Veteran",
      level = 55,
      kills = 120,
      damage = 64000,
    },
  },
  {
    id = "evolution-progress",
    description = "Specialized core with elements, augments, and material progress.",
    profile = {
      custom_name = "Stormline",
      level = 55,
      kills = 380,
      damage = 248000,
      ammo_productivity_progress = 0.64,
      shield = 90,
      show_name_label = true,
      show_label_level = true,
      label_color_preset = "blue",
      label_color = { 0.35, 0.75, 1 },
    },
    evolution = {
      specialization = "sniper",
      sub_specialization = "deadeye",
      elements = { "electric", "fire" },
      base = {
        damage = 12,
        attack_speed = 4,
        crit_chance = 8,
        crit_damage = 6,
        shield = 5,
      },
      augments = {
        ammo_productivity = 3,
        luck = 4,
      },
      element_mastery = {
        electric = {
          rank = 2,
          delivered = 120,
        },
        fire = {
          rank = 1,
          delivered = 40,
        },
      },
    },
  },
}

local SAMPLE_INVENTORY_CORES = {
  {
    custom_name = "Longshot",
    level = 44,
    kills = 140,
    damage = 122000,
    evolution = {
      specialization = "sniper",
      sub_specialization = "deadeye",
      base = {
        damage = 8,
        crit_chance = 5,
      },
    },
  },
  {
    custom_name = "Bulwark Gate",
    level = 28,
    kills = 90,
    damage = 82000,
    evolution = {
      specialization = "bulwark",
      base = {
        hp = 10,
        shield = 3,
      },
    },
  },
  {
    custom_name = "Sprayer",
    level = 18,
    kills = 58,
    damage = 38000,
    evolution = {
      specialization = "machine_gun",
      base = {
        attack_speed = 6,
      },
    },
  },
  {
    custom_name = "",
    level = 5,
    kills = 12,
    damage = 6400,
  },
}

local function init_storage()
  storage.turret_xp_gui_snapshots = storage.turret_xp_gui_snapshots or {}
end

script.on_init(init_storage)
script.on_configuration_changed(init_storage)

local function print_player(player, message)
  if player and player.valid then
    player.print(PREFIX .. message)
  end
end

local function scene_by_id(scene_id)
  for _, scene in ipairs(SCENES) do
    if scene.id == scene_id then
      return scene
    end
  end
  return nil
end

local function selected_scenes(parameter)
  local raw = parameter and parameter:match("^%s*(.-)%s*$") or ""
  if raw == "" or raw == "all" then
    return SCENES
  end

  local scene = scene_by_id(raw)
  return scene and { scene } or nil
end

local function snapshot_surface()
  local surface = game.surfaces[SURFACE_NAME]
  if not surface then
    surface = game.create_surface(SURFACE_NAME)
  end
  surface.request_to_generate_chunks({ 0, 0 }, 2)
  surface.force_generate_chunk_requests()
  return surface
end

local function area_around(position, radius)
  return {
    { position.x - radius, position.y - radius },
    { position.x + radius, position.y + radius },
  }
end

local function current_turret(surface, position)
  local entities = surface.find_entities_filtered({
    area = area_around(position, 0.75),
    type = "ammo-turret",
  })
  for _, entity in pairs(entities) do
    if entity.valid and entity.force.name == "player" then
      return entity
    end
  end
  return nil
end

local function clamp_resolution(value, fallback)
  value = math.floor(tonumber(value) or fallback)
  if value < 1 then
    return fallback
  end
  return math.min(value, MAX_CAPTURE_RESOLUTION)
end

local function player_display_resolution(player)
  local display = player.display_resolution or {}
  return {
    width = clamp_resolution(display.width or display.x, DEFAULT_CAPTURE_RESOLUTION.x),
    height = clamp_resolution(display.height or display.y, DEFAULT_CAPTURE_RESOLUTION.y),
  }
end

local function capture_resolution(player)
  local display = player_display_resolution(player)
  return {
    x = display.width,
    y = display.height,
  }
end

local function snapshot_layout()
  if remote.interfaces[IFACE] and remote.interfaces[IFACE].gui_snapshot_layout then
    local ok, result = pcall(remote.call, IFACE, "gui_snapshot_layout")
    if ok and type(result) == "table" then
      return result
    end
  end
  return {}
end

local function close_turret_xp_gui(player)
  if player and player.valid and remote.interfaces[IFACE] and remote.interfaces[IFACE].close_gui then
    pcall(remote.call, IFACE, "close_gui", player)
  end
end

local function snapshot_frame(player)
  if remote.interfaces[IFACE] and remote.interfaces[IFACE].gui_snapshot_frame then
    local ok, result = pcall(remote.call, IFACE, "gui_snapshot_frame", player)
    if ok and type(result) == "table" then
      return result
    end
  end
  return nil
end

local function center_snapshot_frame(player)
  if remote.interfaces[IFACE] and remote.interfaces[IFACE].center_gui_snapshot_frame then
    local ok, result = pcall(remote.call, IFACE, "center_gui_snapshot_frame", player)
    if ok and type(result) == "table" then
      return result
    end
  end
  return snapshot_frame(player)
end

local function cleanup_entities(session)
  if not session or not session.surface_name then
    return
  end

  local surface = game.surfaces[session.surface_name]
  if not surface then
    return
  end

  for _, entity in pairs(surface.find_entities_filtered({ area = area_around({ x = 0, y = 0 }, 24) })) do
    if entity.valid and entity.type ~= "character" and entity.type ~= "player" then
      if entity.type == "ammo-turret" and remote.interfaces[IFACE] and remote.interfaces[IFACE].cleanup_entity then
        pcall(remote.call, IFACE, "cleanup_entity", entity)
      end
      if entity.valid then
        entity.destroy()
      end
    end
  end
end

local function clear_inserted_inventory(session)
  local player = game.get_player(session.player_index)
  local inventory = player and player.valid and player.get_main_inventory() or nil
  if not inventory then
    return
  end

  for _, index in ipairs(session.inserted_slots or {}) do
    local stack = inventory[index]
    if stack and stack.valid_for_read and stack.name == CHIP_NAME then
      stack.clear()
    end
  end
  session.inserted_slots = {}
end

local function place_stack_in_inventory(player, stack_definition, inserted_slots)
  local inventory = player.get_main_inventory()
  if not inventory then
    return false
  end

  for index = 1, #inventory do
    local stack = inventory[index]
    if stack and not stack.valid_for_read then
      stack.set_stack(stack_definition)
      inserted_slots[#inserted_slots + 1] = index
      return true
    end
  end

  return false
end

local function create_core_stack(surface, position, profile, evolution)
  local turret = surface.create_entity({
    name = "gun-turret",
    position = position,
    force = "player",
    raise_built = false,
  })
  if not turret then
    return nil
  end

  remote.call(IFACE, "install_core", turret, profile or {})
  turret = current_turret(surface, position) or turret
  if evolution then
    remote.call(IFACE, "set_evolution", turret, evolution)
    turret = current_turret(surface, position) or turret
  end

  local stack = remote.call(IFACE, "make_chip_stack", turret)
  remote.call(IFACE, "cleanup_entity", turret)
  if turret.valid then
    turret.destroy()
  end
  return stack
end

local function seed_inventory_cores(player, surface, session)
  if session.seeded_inventory then
    return true
  end

  for index, sample in ipairs(SAMPLE_INVENTORY_CORES) do
    local stack = create_core_stack(surface, { x = -8 + index, y = -8 }, sample, sample.evolution)
    if not stack or not place_stack_in_inventory(player, stack, session.inserted_slots) then
      print_player(player, "Could not add sample Veteran Cores. Make a few empty inventory slots and retry.")
      return false
    end
  end

  session.seeded_inventory = true
  return true
end

local function create_scene_turret(surface, scene)
  local position = { x = 0, y = 0 }
  local turret = surface.create_entity({
    name = "gun-turret",
    position = position,
    force = "player",
    raise_built = false,
  })
  if not turret then
    return nil
  end

  turret.insert({ name = "firearm-magazine", count = 50 })
  if scene.profile then
    remote.call(IFACE, "install_core", turret, scene.profile)
    turret = current_turret(surface, position) or turret
    if scene.evolution then
      remote.call(IFACE, "set_evolution", turret, scene.evolution)
      turret = current_turret(surface, position) or turret
    end
  end

  return turret
end

local function json_manifest(session)
  local manifest = {
    generated_tick = game.tick,
    output_root = OUTPUT_ROOT,
    screenshot = session.screenshot or {},
    layout = session.layout or {},
    scenes = session.manifest_scenes or {},
  }
  if helpers and helpers.table_to_json then
    return helpers.table_to_json(manifest)
  end
  return serpent.block(manifest)
end

local function write_manifest(session)
  local ok, err = pcall(function()
    helpers.write_file(OUTPUT_ROOT .. "/manifest.json", json_manifest(session), false)
  end)
  return ok, err
end

local function finish_session(session, message)
  local player = game.get_player(session.player_index)
  if player and player.valid then
    player.opened = nil
    close_turret_xp_gui(player)
  end

  cleanup_entities(session)
  clear_inserted_inventory(session)

  if player and player.valid and session.original_surface_name and game.surfaces[session.original_surface_name] then
    player.teleport(session.original_position, session.original_surface_name)
  end

  local manifest_ok, manifest_error = write_manifest(session)
  if not manifest_ok then
    print_player(player, "Could not write snapshot manifest: " .. tostring(manifest_error))
  end
  game.set_wait_for_screenshots_to_finish()
  storage.turret_xp_gui_snapshots.session = nil

  if message then
    print_player(player, message)
  end
end

local function setup_next_scene(session)
  local player = game.get_player(session.player_index)
  if not player or not player.valid then
    storage.turret_xp_gui_snapshots.session = nil
    return
  end

  session.scene_index = (session.scene_index or 0) + 1
  local scene = session.scenes[session.scene_index]
  if not scene then
    finish_session(session, "Captured " .. tostring(#(session.manifest_scenes or {})) .. " GUI snapshots. Run scripts/gui-snapshots.sh collect from the repo.")
    return
  end

  cleanup_entities(session)
  local surface = snapshot_surface()
  session.surface_name = surface.name
  player.teleport({ x = 0, y = -5 }, surface)

  if scene.mode == "empty" and not seed_inventory_cores(player, surface, session) then
    finish_session(session, "Snapshot capture aborted.")
    return
  end

  local turret = create_scene_turret(surface, scene)
  if not turret then
    finish_session(session, "Snapshot capture aborted: could not create fixture turret.")
    return
  end

  if not remote.call(IFACE, "open_gui_standalone", player, turret) then
    finish_session(session, "Snapshot capture aborted: could not open Turret XP GUI.")
    return
  end

  session.current_scene = scene
  session.current_frame = nil
  session.step = "center"
  session.wait = 20
end

local function center_current_scene(session)
  local player = game.get_player(session.player_index)
  if not player or not player.valid then
    storage.turret_xp_gui_snapshots.session = nil
    return
  end

  session.current_frame = center_snapshot_frame(player)
  session.step = "capture"
  session.wait = 2
end

local function capture_current_scene(session)
  local player = game.get_player(session.player_index)
  if not player or not player.valid then
    storage.turret_xp_gui_snapshots.session = nil
    return
  end

  local scene = session.current_scene
  local file_name = string.format("%02d-%s.png", session.scene_index, scene.id)
  local path = OUTPUT_ROOT .. "/" .. file_name
  local resolution = session.capture_resolution or capture_resolution(player)
  local frame = session.current_frame or snapshot_frame(player)
  game.take_screenshot({
    player = player.index,
    by_player = player.index,
    surface = player.surface,
    position = { x = 0, y = 0 },
    resolution = resolution,
    zoom = 1,
    path = path,
    show_gui = true,
    show_entity_info = false,
    anti_alias = false,
    hide_clouds = true,
    hide_fog = true,
    force_render = true,
  })

  session.manifest_scenes[#session.manifest_scenes + 1] = {
    id = scene.id,
    file = file_name,
    description = scene.description,
    frame = frame,
  }
  print_player(player, "Captured " .. file_name)

  session.current_scene = nil
  session.current_frame = nil
  session.step = "setup"
  session.wait = 20
end

script.on_event(defines.events.on_tick, function()
  init_storage()
  local session = storage.turret_xp_gui_snapshots.session
  if not session then
    return
  end

  if session.wait and session.wait > 0 then
    session.wait = session.wait - 1
    return
  end

  if session.step == "center" then
    center_current_scene(session)
  elseif session.step == "capture" then
    capture_current_scene(session)
  else
    setup_next_scene(session)
  end
end)

commands.add_command("turret-xp-snapshots", "Capture Turret XP GUI screenshots for local review.", function(command)
  init_storage()
  local player = command.player_index and game.get_player(command.player_index)
  if not player then
    return
  end
  if not remote.interfaces[IFACE] then
    print_player(player, "Missing Turret XP test API. Make sure turret_xp and turret_xp_gui_snapshots are both enabled.")
    return
  end
  if storage.turret_xp_gui_snapshots.session then
    print_player(player, "A snapshot session is already running.")
    return
  end

  local scenes = selected_scenes(command.parameter)
  if not scenes then
    print_player(player, "Unknown scene. Use /turret-xp-snapshots or /turret-xp-snapshots <scene-id>.")
    return
  end

  storage.turret_xp_gui_snapshots.session = {
    player_index = player.index,
    scenes = scenes,
    scene_index = 0,
    step = "setup",
    wait = 1,
    inserted_slots = {},
    manifest_scenes = {},
    original_surface_name = player.surface.name,
    original_position = {
      x = player.position.x,
      y = player.position.y,
    },
  }
  local session = storage.turret_xp_gui_snapshots.session
  session.capture_resolution = capture_resolution(player)
  session.layout = snapshot_layout()
  session.screenshot = {
    resolution = {
      x = session.capture_resolution.x,
      y = session.capture_resolution.y,
    },
    display_resolution = player_display_resolution(player),
    display_scale = player.display_scale,
    display_density_scale = player.display_density_scale,
  }

  print_player(player, "Capturing " .. tostring(#scenes) .. " GUI snapshot scene(s). Please do not move inventory items until it finishes.")
end)
