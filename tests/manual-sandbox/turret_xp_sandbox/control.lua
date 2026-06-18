local IFACE = "turret_xp_test"
local SURFACE_NAME = "turret_xp_sandbox"
local BOUNDS = {
  left_top = { x = -96, y = -64 },
  right_bottom = { x = 96, y = 64 },
}

local SCENARIOS = {
  {
    id = "core",
    title = "Core Movement And Bound Items",
    position = { x = -56, y = -28 },
  },
  {
    id = "evolution",
    title = "Evolution Gates And GUI",
    position = { x = -8, y = -28 },
  },
  {
    id = "feeder",
    title = "Feeder And Material Routing",
    position = { x = 40, y = -28 },
  },
  {
    id = "combat",
    title = "Combat XP And Scripted Stats",
    position = { x = -56, y = 22 },
  },
  {
    id = "automation",
    title = "Automation And Setup Policy",
    position = { x = -4, y = 22 },
  },
}

local function init_storage()
  storage.turret_xp_sandbox = storage.turret_xp_sandbox or {
    built = false,
    render_objects = {},
    seeded_players = {},
  }
  storage.turret_xp_sandbox.render_objects = storage.turret_xp_sandbox.render_objects or {}
  storage.turret_xp_sandbox.seeded_players = storage.turret_xp_sandbox.seeded_players or {}
  return storage.turret_xp_sandbox
end

local function sandbox_state()
  return init_storage()
end

local function prototype_exists(kind, name)
  local group = prototypes[kind]
  return group and group[name] ~= nil
end

local function entity_exists(name)
  return prototype_exists("entity", name)
end

local function item_exists(name)
  return prototype_exists("item", name)
end

local function tile_name()
  if prototype_exists("tile", "refined-concrete") then
    return "refined-concrete"
  end
  if prototype_exists("tile", "concrete") then
    return "concrete"
  end
  return "landfill"
end

local function print_player(player, message)
  if player and player.valid then
    player.print("[turret_xp_sandbox] " .. message)
  else
    game.print("[turret_xp_sandbox] " .. message)
  end
end

local function test_api_available()
  return remote.interfaces[IFACE] ~= nil
end

local function test_call(method, ...)
  if not remote.interfaces[IFACE] or not remote.interfaces[IFACE][method] then
    return nil
  end

  local ok, result = pcall(remote.call, IFACE, method, ...)
  if not ok then
    log("[turret_xp_sandbox] remote call failed: " .. tostring(method) .. ": " .. tostring(result))
    return nil
  end
  return result
end

local function scenario_by_id(id)
  for _, scenario in ipairs(SCENARIOS) do
    if scenario.id == id then
      return scenario
    end
  end
  return nil
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

local function make_surface()
  local surface = game.surfaces[SURFACE_NAME]
  if not surface then
    surface = game.create_surface(SURFACE_NAME)
  end
  surface.request_to_generate_chunks({ x = 0, y = 0 }, 8)
  surface.force_generate_chunk_requests()
  pcall(function()
    surface.always_day = true
  end)
  return surface
end

local function destroy_render_objects()
  local state = sandbox_state()
  for _, object in ipairs(state.render_objects or {}) do
    if object and object.valid then
      object.destroy()
    end
  end
  state.render_objects = {}
end

local function clear_chart_tags(surface)
  pcall(function()
    for _, tag in pairs(game.forces.player.find_chart_tags(surface)) do
      tag.destroy()
    end
  end)
end

local function clear_surface(surface)
  destroy_render_objects()
  clear_chart_tags(surface)
  for _, entity in pairs(surface.find_entities_filtered({ area = { BOUNDS.left_top, BOUNDS.right_bottom } })) do
    if entity.valid and entity.type ~= "character" and entity.type ~= "player" then
      if entity.type == "ammo-turret" then
        test_call("cleanup_entity", entity)
      end
      if entity.valid then
        entity.destroy({ raise_destroy = false })
      end
    end
  end
end

local function paint_surface(surface)
  local tiles = {}
  local name = tile_name()
  for x = BOUNDS.left_top.x, BOUNDS.right_bottom.x do
    for y = BOUNDS.left_top.y, BOUNDS.right_bottom.y do
      tiles[#tiles + 1] = {
        name = name,
        position = { x, y },
      }
    end
  end
  surface.set_tiles(tiles, true)
end

local function draw_text(surface, position, text, scale, color)
  local ok, object = pcall(function()
    return rendering.draw_text({
      text = text,
      surface = surface,
      target = position,
      color = color or { 1, 0.86, 0.46 },
      scale = scale or 1.2,
      font = "default-bold",
      alignment = "center",
      vertical_alignment = "middle",
      scale_with_zoom = true,
      only_in_alt_mode = false,
    })
  end)
  if ok and object then
    local state = sandbox_state()
    state.render_objects[#state.render_objects + 1] = object
  end
end

local function label(surface, position, title, detail)
  draw_text(surface, { x = position.x, y = position.y - 5 }, title, 1.35, { 1, 0.86, 0.46 })
  if detail then
    draw_text(surface, { x = position.x, y = position.y - 3.6 }, detail, 0.85, { 0.85, 0.85, 0.85 })
  end
end

local function chart_tag(surface, position, text)
  pcall(function()
    game.forces.player.add_chart_tag(surface, {
      icon = { type = "virtual", name = "signal-info" },
      position = position,
      text = text,
    })
  end)
end

local function create_entity(surface, parameters)
  if not entity_exists(parameters.name) then
    return nil
  end
  parameters.force = parameters.force or "player"
  parameters.raise_built = false
  local ok, entity = pcall(function()
    return surface.create_entity(parameters)
  end)
  if ok then
    return entity
  end
  return nil
end

local function create_turret(surface, position, ammo_count)
  local turret = create_entity(surface, {
    name = "gun-turret",
    position = position,
  })
  if turret and ammo_count and ammo_count > 0 and item_exists("firearm-magazine") then
    turret.insert({ name = "firearm-magazine", count = ammo_count })
  end
  return turret
end

local function create_power(surface, position)
  if entity_exists("electric-energy-interface") then
    create_entity(surface, {
      name = "electric-energy-interface",
      position = position,
    })
  elseif entity_exists("solar-panel") then
    create_entity(surface, {
      name = "solar-panel",
      position = position,
    })
  end
  if entity_exists("substation") then
    create_entity(surface, {
      name = "substation",
      position = { x = position.x + 2, y = position.y },
    })
  end
end

local function create_chest(surface, position, stacks)
  local chest = create_entity(surface, {
    name = "wooden-chest",
    position = position,
  })
  if chest then
    for _, stack in ipairs(stacks or {}) do
      chest.insert(stack)
    end
  end
  return chest
end

local function create_inserter(surface, name, position, direction)
  return create_entity(surface, {
    name = entity_exists(name) and name or "inserter",
    position = position,
    direction = direction or defines.direction.south,
  })
end

local function create_wall_line(surface, y, x1, x2)
  if not entity_exists("stone-wall") then
    return
  end
  for x = x1, x2 do
    create_entity(surface, {
      name = "stone-wall",
      position = { x = x, y = y },
    })
  end
end

local function create_core_stack(surface, position, profile, evolution)
  local turret = create_turret(surface, position, 10)
  if not turret then
    return nil
  end
  test_call("install_core", turret, profile or {})
  turret = current_turret(surface, position) or turret
  if evolution then
    test_call("set_evolution", turret, evolution)
    turret = current_turret(surface, position) or turret
  end
  local stack = test_call("make_chip_stack", turret)
  test_call("cleanup_entity", turret)
  if turret.valid then
    turret.destroy({ raise_destroy = false })
  end
  return stack
end

local function insert_stack(player, stack)
  local inventory = player and player.valid and player.get_main_inventory() or nil
  if not inventory or not stack then
    return false
  end
  return (inventory.insert(stack) or 0) > 0
end

local function seed_player_items(player, surface, force)
  if not player or not player.valid then
    return
  end

  local state = sandbox_state()
  if state.seeded_players[player.index] and not force then
    return
  end

  local samples = {
    {
      custom_name = "Sandbox Base",
      level = 8,
      show_label_level = true,
    },
    {
      custom_name = "Sandbox Sniper",
      level = 45,
      show_name_label = true,
      show_label_level = true,
      evolution = {
        specialization = "sniper",
        sub_specialization = "sniper_deadeye",
        elements = { "explosive", "fire" },
      },
    },
    {
      custom_name = "Sandbox Bulwark",
      level = 50,
      show_name_label = true,
      evolution = {
        specialization = "bulwark",
        sub_specialization = "bulwark_guardian",
        base = {
          shield = 8,
          resistance = 20,
        },
        augments = {
          repair = 2,
        },
      },
    },
  }

  local inserted = 0
  for index, sample in ipairs(samples) do
    local stack = create_core_stack(surface, { x = 80 + index, y = 52 }, sample, sample.evolution)
    if insert_stack(player, stack) then
      inserted = inserted + 1
    end
  end

  local bound_source = create_turret(surface, { x = 84, y = 52 }, 50)
  if bound_source then
    test_call("install_core", bound_source, {
      custom_name = "Sandbox Bound",
      level = 40,
      show_name_label = true,
      bound_turret = true,
    })
    bound_source = current_turret(surface, { x = 84, y = 52 }) or bound_source
    test_call("set_evolution", bound_source, {
      specialization = "machine_gun",
      sub_specialization = "machine_sustained",
    })
    test_call("set_bound", bound_source, true)
    if insert_stack(player, test_call("make_bound_turret_stack", bound_source)) then
      inserted = inserted + 1
    end
    test_call("cleanup_entity", bound_source)
    if bound_source.valid then
      bound_source.destroy({ raise_destroy = false })
    end
  end

  state.seeded_players[player.index] = true
  print_player(player, "Inserted " .. tostring(inserted) .. " sample item(s). Run /turret-xp-sandbox items for another set.")
end

local function build_core_scenario(surface, origin)
  label(surface, origin, "Core Movement", "Try empty picker, installed core, and bound quick-move mining.")
  create_turret(surface, { x = origin.x - 6, y = origin.y }, 40)

  local installed = create_turret(surface, { x = origin.x, y = origin.y }, 60)
  if installed then
    test_call("install_core", installed, {
      custom_name = "Installed Core",
      level = 15,
      show_name_label = true,
      show_label_level = true,
    })
  end

  local bound = create_turret(surface, { x = origin.x + 6, y = origin.y }, 60)
  if bound then
    test_call("install_core", bound, {
      custom_name = "Bound Move",
      level = 35,
      show_name_label = true,
      show_label_level = true,
      bound_turret = true,
    })
    bound = current_turret(surface, { x = origin.x + 6, y = origin.y }) or bound
    test_call("set_evolution", bound, {
      specialization = "sniper",
      sub_specialization = "sniper_overwatch",
    })
    test_call("set_bound", bound, true)
  end
end

local function build_evolution_scenario(surface, origin)
  label(surface, origin, "Evolution Gates", "Open each turret and inspect level gates, stats, labels, and reset/change controls.")
  local base = create_turret(surface, { x = origin.x - 6, y = origin.y }, 80)
  if base then
    test_call("install_core", base, {
      custom_name = "Level 9",
      level = 9,
      show_name_label = true,
      show_label_level = true,
    })
  end

  local choices = create_turret(surface, { x = origin.x, y = origin.y }, 80)
  if choices then
    test_call("install_core", choices, {
      custom_name = "Level 50 Choices",
      level = 50,
      show_name_label = true,
      show_label_level = true,
      show_unspent_label = true,
    })
  end

  local built = create_turret(surface, { x = origin.x + 6, y = origin.y }, 80)
  if built then
    test_call("install_core", built, {
      custom_name = "Stormfire",
      level = 60,
      show_name_label = true,
      show_label_level = true,
    })
    built = current_turret(surface, { x = origin.x + 6, y = origin.y }) or built
    test_call("set_evolution", built, {
      specialization = "machine_gun",
      sub_specialization = "machine_shredder",
      elements = { "fire", "electric" },
      base = {
        damage = 8,
        crit_chance = 5,
        ammo_regen = 20,
      },
      augments = {
        double_shot = 2,
        luck = 3,
        veteran_training = 2,
      },
      element_mastery = {
        fire = { rank = 2, delivered = 30 },
        electric = { rank = 1, delivered = 0 },
      },
    })
  end
end

local function build_feeder_scenario(surface, origin)
  label(surface, origin, "Feeder Routing", "Watch source-aware inserter filters, ammo forwarding, wrong-item cleanup, and mixed elements.")
  create_power(surface, { x = origin.x - 9, y = origin.y + 2 })
  create_power(surface, { x = origin.x + 9, y = origin.y + 2 })

  local fire = create_turret(surface, { x = origin.x - 6, y = origin.y }, 20)
  if fire then
    test_call("install_core", fire, {
      custom_name = "Fire Feeder",
      level = 25,
      show_name_label = true,
    })
    test_call("pick_element", fire, 1, "fire")
    create_chest(surface, { x = origin.x - 6, y = origin.y + 3 }, {
      { name = "sulfur", count = 200 },
      { name = "firearm-magazine", count = 50 },
    })
    create_inserter(surface, "inserter", { x = origin.x - 6, y = origin.y + 1 }, defines.direction.south)
  end

  local mixed = create_turret(surface, { x = origin.x + 2, y = origin.y }, 20)
  if mixed then
    test_call("install_core", mixed, {
      custom_name = "Fire + Explosive",
      level = 55,
      show_name_label = true,
    })
    mixed = current_turret(surface, { x = origin.x + 2, y = origin.y }) or mixed
    test_call("set_evolution", mixed, {
      elements = { "fire", "explosive" },
      element_mastery = {
        fire = { rank = 1, delivered = 0 },
        explosive = { rank = 1, delivered = 0 },
      },
    })
    create_chest(surface, { x = origin.x + 2, y = origin.y + 3 }, {
      { name = "sulfur", count = 200 },
      { name = "grenade", count = 200 },
      { name = "iron-plate", count = 20 },
    })
    create_inserter(surface, "fast-inserter", { x = origin.x + 2, y = origin.y + 1 }, defines.direction.south)
  end

  local toxic = create_turret(surface, { x = origin.x + 10, y = origin.y }, 20)
  if toxic then
    test_call("install_core", toxic, {
      custom_name = "Toxic Cleanup",
      level = 25,
      show_name_label = true,
    })
    test_call("pick_element", toxic, 1, "toxic")
    if item_exists("poison-capsule") then
      create_chest(surface, { x = origin.x + 10, y = origin.y + 3 }, {
        { name = "poison-capsule", count = 100 },
        { name = "copper-plate", count = 50 },
      })
      create_inserter(surface, "stack-inserter", { x = origin.x + 10, y = origin.y + 1 }, defines.direction.south)
    end
  end
end

local function build_combat_scenario(surface, origin)
  label(
    surface,
    origin,
    "Combat And Stats",
    "Let turrets shoot, damage them, and inspect XP, Shield, Resistance, Ammo Productivity, and effects."
  )
  create_wall_line(surface, origin.y - 2, origin.x - 9, origin.x + 13)
  create_wall_line(surface, origin.y + 4, origin.x - 9, origin.x + 13)

  local shield = create_turret(surface, { x = origin.x - 6, y = origin.y }, 100)
  if shield then
    test_call("install_core", shield, {
      custom_name = "Shield Tank",
      level = 80,
      show_name_label = true,
      show_label_level = true,
    })
    test_call("set_evolution", shield, {
      specialization = "bulwark",
      base = {
        shield = 8,
        resistance = 40,
        ammo_regen = 25,
      },
      augments = {
        repair = 2,
        shield_on_hit = 2,
      },
    })
    test_call("age_shield_damage", shield, 360)
    test_call("apply_shield_recharge", 600)
  end

  local brawler = create_turret(surface, { x = origin.x + 2, y = origin.y }, 100)
  if brawler then
    test_call("install_core", brawler, {
      custom_name = "Brawler Lifesteal",
      level = 50,
      show_name_label = true,
    })
    brawler = current_turret(surface, { x = origin.x + 2, y = origin.y }) or brawler
    test_call("set_evolution", brawler, {
      specialization = "brawler",
      sub_specialization = "brawler_vampire",
      elements = { "toxic", "fire" },
      augments = {
        luck = 3,
      },
    })
  end

  for index = 1, 8 do
    create_entity(surface, {
      name = "small-biter",
      position = { x = origin.x + 8 + (index % 4), y = origin.y + math.floor(index / 4) },
      force = "enemy",
    })
  end
end

local function build_automation_scenario(surface, origin)
  label(
    surface,
    origin,
    "Automation And Setup Policy",
    "Inspect presets, Auto, core requests, and copied setup policy without cloning XP/history."
  )
  local sniper = create_turret(surface, { x = origin.x - 8, y = origin.y }, 80)
  if sniper then
    test_call("install_core", sniper, {
      custom_name = "Auto Sniper",
      level = 50,
      show_name_label = true,
      show_label_level = true,
      show_unspent_label = true,
    })
    test_call("apply_automation", sniper, "sniper", true, true)
  end

  local conflict = create_turret(surface, { x = origin.x, y = origin.y }, 80)
  if conflict then
    test_call("install_core", conflict, {
      custom_name = "Manual Bulwark",
      level = 40,
      show_name_label = true,
    })
    conflict = current_turret(surface, { x = origin.x, y = origin.y }) or conflict
    test_call("set_evolution", conflict, {
      specialization = "bulwark",
    })
    test_call("apply_automation", conflict, "sniper", true, true)
  end

  local request = create_turret(surface, { x = origin.x + 8, y = origin.y }, 10)
  if request then
    test_call("set_core_request", request, true)
  end

  local delivered = create_turret(surface, { x = origin.x + 16, y = origin.y }, 10)
  if delivered then
    test_call("set_core_request", delivered, true)
    test_call("insert_requested_core", delivered, {
      custom_name = "Delivered Policy",
      level = 40,
      show_name_label = true,
    })
    test_call("process_core_requests", 64)
  end
end

local BUILDERS = {
  core = build_core_scenario,
  evolution = build_evolution_scenario,
  feeder = build_feeder_scenario,
  combat = build_combat_scenario,
  automation = build_automation_scenario,
}

local function build_sandbox(player)
  if not test_api_available() then
    print_player(player, "Missing Turret XP test API. Enable turret_xp and turret_xp_sandbox together.")
    return
  end

  local surface = make_surface()
  clear_surface(surface)
  paint_surface(surface)
  draw_text(surface, { x = 0, y = -56 }, "Turret XP Manual Sandbox", 1.8, { 1, 0.86, 0.46 })
  draw_text(
    surface,
    { x = 0, y = -53.5 },
    "Use /turret-xp-sandbox list, /turret-xp-sandbox goto <id>, /turret-xp-sandbox reset, /turret-xp-sandbox items.",
    0.9,
    { 0.85, 0.85, 0.85 }
  )
  create_power(surface, { x = 0, y = -48 })

  for _, scenario in ipairs(SCENARIOS) do
    local builder = BUILDERS[scenario.id]
    if builder then
      builder(surface, scenario.position)
      chart_tag(surface, scenario.position, scenario.title)
    end
  end

  local state = sandbox_state()
  state.built = true
  state.surface_name = surface.name

  if player and player.valid then
    seed_player_items(player, surface, false)
    player.teleport({ x = 0, y = -48 }, surface)
    pcall(function()
      player.force.chart(surface, { BOUNDS.left_top, BOUNDS.right_bottom })
    end)
  end
  print_player(player, "Built sandbox surface. Use /turret-xp-sandbox goto <id> to jump between scenarios.")
end

local function goto_scenario(player, id)
  if not player or not player.valid then
    return
  end
  local scenario = scenario_by_id(id)
  if not scenario then
    print_player(player, "Unknown scenario '" .. tostring(id) .. "'. Run /turret-xp-sandbox list.")
    return
  end
  local state = sandbox_state()
  if not state.built or not game.surfaces[SURFACE_NAME] then
    build_sandbox(player)
  end
  player.teleport({ x = scenario.position.x, y = scenario.position.y + 7 }, game.surfaces[SURFACE_NAME])
  print_player(player, "Showing " .. scenario.id .. ": " .. scenario.title)
end

local function list_scenarios(player)
  for _, scenario in ipairs(SCENARIOS) do
    print_player(player, scenario.id .. " - " .. scenario.title)
  end
end

local function destroy_sandbox(player)
  local surface = game.surfaces[SURFACE_NAME]
  if not surface then
    print_player(player, "Sandbox surface does not exist.")
    return
  end
  if player and player.valid and player.surface == surface then
    player.teleport({ x = 0, y = 0 }, game.surfaces.nauvis or game.surfaces[1])
  end
  clear_surface(surface)
  sandbox_state().built = false
  print_player(player, "Cleared sandbox entities. The surface remains available for rebuild.")
end

local function split_words(text)
  local words = {}
  for word in string.gmatch(text or "", "%S+") do
    words[#words + 1] = word
  end
  return words
end

local function print_help(player)
  print_player(player, "/turret-xp-sandbox build - rebuild the sandbox surface")
  print_player(player, "/turret-xp-sandbox list - list scenario ids")
  print_player(player, "/turret-xp-sandbox goto <id> - jump to a scenario")
  print_player(player, "/turret-xp-sandbox items - insert another sample item set")
  print_player(player, "/turret-xp-sandbox destroy - clear sandbox entities")
end

local function handle_command(command)
  init_storage()
  local player = command.player_index and game.get_player(command.player_index) or nil
  local words = split_words(command.parameter)
  local action = words[1] or "build"

  if action == "build" or action == "reset" then
    build_sandbox(player)
  elseif action == "list" then
    list_scenarios(player)
  elseif action == "goto" then
    goto_scenario(player, words[2])
  elseif action == "items" then
    seed_player_items(player, make_surface(), true)
  elseif action == "destroy" then
    destroy_sandbox(player)
  elseif action == "help" then
    print_help(player)
  elseif scenario_by_id(action) then
    goto_scenario(player, action)
  else
    print_help(player)
  end
end

script.on_init(init_storage)
script.on_configuration_changed(init_storage)

commands.add_command("turret-xp-sandbox", "Build or navigate the Turret XP manual development sandbox.", handle_command)
