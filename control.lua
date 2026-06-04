local MOD_PREFIX = "turret-xp-"
local CHIP_NAME = "turret-xp-veteran-core"
local FEEDER_NAME = "turret-xp-veteran-feeder"
local PROFILE_TAG = "turret_xp_profile"
local BASE_TURRET_NAME = "gun-turret"
local SPECIALIZED_TURRET_PREFIX = "turret-xp-gun-turret-"

local GUI = {
  panel = MOD_PREFIX .. "panel",
  core = MOD_PREFIX .. "core",
  core_slot = MOD_PREFIX .. "core-slot",
  core_status = MOD_PREFIX .. "core-status",
  core_actions = MOD_PREFIX .. "core-actions",
  core_name = MOD_PREFIX .. "core-name",
  core_name_visible = MOD_PREFIX .. "core-name-visible",
  core_profile = MOD_PREFIX .. "core-profile",
  level = MOD_PREFIX .. "level",
  xp = MOD_PREFIX .. "xp",
  xp_bar = MOD_PREFIX .. "xp-bar",
  xp_percent = MOD_PREFIX .. "xp-percent",
  hp = MOD_PREFIX .. "hp",
  shooting_speed = MOD_PREFIX .. "shooting-speed",
  range = MOD_PREFIX .. "range",
  ammo = MOD_PREFIX .. "ammo",
  damage = MOD_PREFIX .. "damage",
  dps = MOD_PREFIX .. "dps",
  kills = MOD_PREFIX .. "kills",
  damage_dealt = MOD_PREFIX .. "damage-dealt",
  dev = MOD_PREFIX .. "dev",
  skill_points = MOD_PREFIX .. "skill-points",
  evolution = MOD_PREFIX .. "evolution",
  feeder_status = MOD_PREFIX .. "feeder-status",
  active_elements = MOD_PREFIX .. "active-elements",
  active_specialization = MOD_PREFIX .. "active-specialization",
  active_combo = MOD_PREFIX .. "active-combo",
  element_project = MOD_PREFIX .. "element-project",
  element_project_bar = MOD_PREFIX .. "element-project-bar"
}

local GATES = {
  first_element = 10,
  specialization = 20,
  augments = 30,
  second_element = 40
}

local BASE_UPGRADES = {
  {
    id = "damage",
    sprite = "item/firearm-magazine",
    name = "Damage",
    description = "+0.5 damage per shot per rank.",
    value = "+0.5 / shot",
    effect = "damage"
  },
  {
    id = "repair",
    sprite = "item/repair-pack",
    name = "Regeneration",
    description = "+0.2 HP/s passive repair per rank.",
    value = "+0.2 HP/s",
    effect = "repair"
  },
  {
    id = "siphon",
    sprite = "item/steel-plate",
    name = "Lifesteal",
    description = "Heals for 0.4% of gun-turret damage dealt per rank.",
    value = "+0.4%",
    effect = "siphon"
  },
  {
    id = "crit_chance",
    sprite = "item/submachine-gun",
    name = "Crit chance",
    description = "+0.25% critical hit chance per rank.",
    value = "+0.25%",
    effect = "crit_chance"
  },
  {
    id = "crit_damage",
    sprite = "item/electronic-circuit",
    name = "Crit damage",
    description = "+1% critical hit damage per rank.",
    value = "+1%",
    effect = "crit_damage"
  }
}

local BASE_UPGRADE_BY_ID = {}
for _, upgrade in ipairs(BASE_UPGRADES) do
  BASE_UPGRADE_BY_ID[upgrade.id] = upgrade
end

local ELEMENTS = {
  {
    id = "explosive",
    sprite = "virtual-signal/signal-explosion",
    name = "Explosive",
    description = "Shots can splash explosion damage around the target.",
    resource = "grenade",
    base_requirement = 50
  },
  {
    id = "fire",
    sprite = "virtual-signal/signal-fire",
    name = "Fire",
    description = "Shots can add fire damage and power incendiary combos.",
    resource = "sulfur",
    base_requirement = 250
  },
  {
    id = "electric",
    sprite = "virtual-signal/signal-lightning",
    name = "Electric",
    description = "Shots can arc electric damage to a nearby enemy.",
    resource = "battery",
    base_requirement = 75
  }
}

local ELEMENT_BY_ID = {}
for _, element in ipairs(ELEMENTS) do
  ELEMENT_BY_ID[element.id] = element
end

local SPECIALIZATIONS = {
  {
    id = "sniper",
    sprite = "entity/radar",
    name = "Sniper",
    description = "Range 34, slower fire rate, much higher shot damage, lower durability."
  },
  {
    id = "machine_gun",
    sprite = "item/submachine-gun",
    name = "Machine gun",
    description = "Very fast fire rate, slightly shorter range, lower shot damage."
  },
  {
    id = "bulwark",
    sprite = "item/stone-wall",
    name = "Bulwark",
    description = "1200 HP, lower shot damage, slightly shorter range."
  },
  {
    id = "brawler",
    sprite = "item/shotgun",
    name = "Brawler",
    description = "Range 7, very high shot damage, stronger durability."
  }
}

local SPECIALIZATION_BY_ID = {}
for _, specialization in ipairs(SPECIALIZATIONS) do
  SPECIALIZATION_BY_ID[specialization.id] = specialization
end

local AUGMENTS = {
  {
    id = "bounce",
    sprite = "item/piercing-rounds-magazine",
    name = "Bullet bounce",
    description = "Chance for a shot to bounce to a nearby enemy."
  },
  {
    id = "piercing",
    sprite = "item/uranium-rounds-magazine",
    name = "Piercing follow-through",
    description = "Chance for a shot to hit another enemy behind the target."
  },
  {
    id = "longshot",
    sprite = "entity/radar",
    name = "Longshot optics",
    description = "Bonus damage against targets near the turret's current range limit."
  }
}

local AUGMENT_BY_ID = {}
for _, augment in ipairs(AUGMENTS) do
  AUGMENT_BY_ID[augment.id] = augment
end

local SETTINGS = {
  xp_per_damage = MOD_PREFIX .. "xp-per-damage",
  xp_per_kill_credit = MOD_PREFIX .. "xp-per-kill-credit",
  level_base_xp = MOD_PREFIX .. "level-base-xp",
  level_growth = MOD_PREFIX .. "level-growth"
}

local DEFAULTS = {
  xp_per_damage = 0.02,
  xp_per_kill_credit = 20,
  level_base_xp = 100,
  level_growth = 1.65
}

local COLOR = {
  caption = { 0.62, 0.62, 0.62 },
  muted = { 0.74, 0.74, 0.74 },
  bonus = { 0.58, 0.82, 0.38 }
}

local REFRESH_TICKS = 60
local TARGET_DAMAGE_TTL = 60 * 60 * 5
local FEEDER_CONSUME_LIMIT = 100
local safe_read
local build_turret_gui
local feeder = {}

local function ensure_storage()
  storage.turret_xp = storage.turret_xp or {}
  storage.turret_xp.turrets = storage.turret_xp.turrets or {}
  storage.turret_xp.chips = storage.turret_xp.chips or {}
  storage.turret_xp.next_chip_id = storage.turret_xp.next_chip_id or 1
  storage.turret_xp.players = storage.turret_xp.players or {}
  storage.turret_xp.targets = storage.turret_xp.targets or {}
  storage.turret_xp.feeders = storage.turret_xp.feeders or {}
end

local function unlock_core_recipes_for_existing_tech()
  if not game or not game.forces then
    return
  end

  for _, force in pairs(game.forces) do
    local recipe = force.recipes[CHIP_NAME]
    if recipe then
      local technology = force.technologies["military"]
      if not technology or technology.researched then
        recipe.enabled = true
      end
    end
  end
end

local function ensure_player_state(player)
  ensure_storage()
  local player_state = storage.turret_xp.players[player.index]
  if type(player_state) ~= "table" then
    player_state = {}
    storage.turret_xp.players[player.index] = player_state
  end

  return player_state
end

local function is_gun_turret(entity)
  return entity and entity.valid
    and (entity.name == BASE_TURRET_NAME or string.sub(entity.name, 1, #SPECIALIZED_TURRET_PREFIX) == SPECIALIZED_TURRET_PREFIX)
end

local function get_specialized_turret_name(specialization_id)
  if specialization_id and SPECIALIZATION_BY_ID[specialization_id] then
    return SPECIALIZED_TURRET_PREFIX .. specialization_id
  end

  return BASE_TURRET_NAME
end

local function turret_key(entity)
  if entity.unit_number then
    return tostring(entity.unit_number)
  end

  return table.concat({
    tostring(entity.surface.index),
    string.format("%.2f", entity.position.x),
    string.format("%.2f", entity.position.y)
  }, ":")
end

local function entity_tracking_key(entity)
  if not entity or not entity.valid then
    return nil
  end

  if entity.unit_number then
    return tostring(entity.unit_number)
  end

  return table.concat({
    tostring(entity.surface.index),
    entity.name,
    string.format("%.2f", entity.position.x),
    string.format("%.2f", entity.position.y)
  }, ":")
end

local function get_setting(name, fallback)
  local setting = settings.global[name]
  if setting == nil or setting.value == nil then
    return fallback
  end

  return setting.value
end

local function get_xp_settings()
  return {
    xp_per_damage = math.max(0, get_setting(SETTINGS.xp_per_damage, DEFAULTS.xp_per_damage)),
    xp_per_kill_credit = math.max(0, get_setting(SETTINGS.xp_per_kill_credit, DEFAULTS.xp_per_kill_credit)),
    level_base_xp = math.max(1, get_setting(SETTINGS.level_base_xp, DEFAULTS.level_base_xp)),
    level_growth = math.max(1.01, get_setting(SETTINGS.level_growth, DEFAULTS.level_growth))
  }
end

local function get_element_requirement_count(element, next_rank)
  return math.max(1, math.floor((element.base_requirement or 100) * (next_rank ^ 1.45) + 0.5))
end

local function get_element_requirements(element, next_rank)
  if not element then
    return {}
  end

  return {
    {
      name = element.resource,
      count = get_element_requirement_count(element, next_rank)
    }
  }
end

local function ensure_evolution_state(state)
  state.evolution = state.evolution or {}
  local evolution = state.evolution
  evolution.base = evolution.base or {}
  evolution.augments = evolution.augments or {}
  evolution.elements = evolution.elements or {}
  evolution.element_mastery = evolution.element_mastery or {}
  if evolution.elements.first or evolution.elements.second then
    evolution.elements = {
      evolution.elements[1] or evolution.elements.first,
      evolution.elements[2] or evolution.elements.second
    }
  end

  for _, upgrade in ipairs(BASE_UPGRADES) do
    evolution.base[upgrade.id] = math.max(0, math.floor(tonumber(evolution.base[upgrade.id]) or 0))
  end

  for _, augment in ipairs(AUGMENTS) do
    evolution.augments[augment.id] = math.max(0, math.floor(tonumber(evolution.augments[augment.id]) or 0))
  end

  if evolution.specialization and not SPECIALIZATION_BY_ID[evolution.specialization] then
    evolution.specialization = nil
  end

  for slot = 1, 2 do
    local element_id = evolution.elements[slot]
    if element_id and not ELEMENT_BY_ID[element_id] then
      evolution.elements[slot] = nil
    end
  end

  for _, element in ipairs(ELEMENTS) do
    local mastery = evolution.element_mastery[element.id]
    if type(mastery) ~= "table" then
      mastery = {
        rank = 0,
        delivered = 0
      }
      evolution.element_mastery[element.id] = mastery
    end
    mastery.rank = math.max(0, math.floor(tonumber(mastery.rank) or 0))
    mastery.delivered = math.max(0, math.floor(tonumber(mastery.delivered) or 0))
  end

  local project = evolution.element_project
  if project then
    local element = ELEMENT_BY_ID[project.element]
    if not element or (project.slot ~= 1 and project.slot ~= 2) then
      evolution.element_project = nil
    else
      project.delivered = project.delivered or {}
      local old_delivered = project.delivered[element.resource] or 0
      if project.requirements and project.requirements[1] and project.requirements[1].name ~= element.resource then
        for _, requirement in ipairs(project.requirements) do
          old_delivered = old_delivered + math.floor(tonumber(project.delivered[requirement.name]) or 0)
        end
        project.delivered = {
          [element.resource] = old_delivered
        }
      end
      project.requirements = get_element_requirements(element, 1)
      for _, requirement in ipairs(project.requirements) do
        project.delivered[requirement.name] = math.max(0, math.floor(tonumber(project.delivered[requirement.name]) or 0))
      end
    end
  end

  if not evolution.migrated_legacy_skills and type(state.skills) == "table" then
    evolution.base.damage = evolution.base.damage + math.max(0, math.floor(tonumber(state.skills.ballistics) or 0))
    evolution.base.xp = evolution.base.xp
      + math.max(0, math.floor(tonumber(state.skills.kill_chain) or 0))
      + math.max(0, math.floor(tonumber(state.skills.targeting_data) or 0))
    evolution.base.repair = evolution.base.repair + math.max(0, math.floor(tonumber(state.skills.field_repairs) or 0))
    evolution.migrated_legacy_skills = true
  end

  return evolution
end

local function get_base_rank(state, upgrade_id)
  if not state then
    return 0
  end

  local evolution = ensure_evolution_state(state)
  return evolution.base[upgrade_id] or 0
end

local function get_augment_rank(state, augment_id)
  if not state then
    return 0
  end

  local evolution = ensure_evolution_state(state)
  return evolution.augments[augment_id] or 0
end

local function get_element_rank(state, element_id)
  if not state or not ELEMENT_BY_ID[element_id] then
    return 0
  end

  local mastery = ensure_evolution_state(state).element_mastery[element_id]
  return mastery and mastery.rank or 0
end

local function get_spent_core_points(state)
  if not state then
    return 0
  end

  local evolution = ensure_evolution_state(state)
  local spent = 0

  for _, upgrade in ipairs(BASE_UPGRADES) do
    spent = spent + (evolution.base[upgrade.id] or 0)
  end

  return spent
end

local function get_spent_augment_points(state)
  if not state then
    return 0
  end

  local evolution = ensure_evolution_state(state)
  local spent = 0

  for _, augment in ipairs(AUGMENTS) do
    spent = spent + (evolution.augments[augment.id] or 0)
  end

  return spent
end

local function get_available_skill_points(state)
  if not state then
    return 0
  end

  return math.max(0, (state.level or 1) - 1 - get_spent_core_points(state))
end

local function get_total_augment_points(state)
  if not state or (state.level or 1) < GATES.augments then
    return 0
  end

  return 1 + math.floor(((state.level or 1) - GATES.augments) / 10)
end

local function get_available_augment_points(state)
  return math.max(0, get_total_augment_points(state) - get_spent_augment_points(state))
end

local function xp_required(level)
  local xp_settings = get_xp_settings()
  local growth_per_level = math.max(0.01, xp_settings.level_growth - 1)
  return math.max(1, math.floor((xp_settings.level_base_xp * (1 + ((level - 1) * growth_per_level))) + 0.5))
end

local function progression_from_total_xp(total_xp)
  local level = 1
  local remaining_xp = math.max(0, total_xp or 0)
  local required_xp = xp_required(level)

  while remaining_xp >= required_xp and level < 10000 do
    remaining_xp = remaining_xp - required_xp
    level = level + 1
    required_xp = xp_required(level)
  end

  return level, remaining_xp, required_xp
end

local function sync_turret_progression(state)
  state.kill_credit = state.kill_credit or state.kills or 0
  ensure_evolution_state(state)

  local xp_settings = get_xp_settings()
  local total_xp = (((state.damage or 0) * xp_settings.xp_per_damage)
    + ((state.kill_credit or 0) * xp_settings.xp_per_kill_credit))
    + (state.dev_xp or 0)
  local level, xp, required = progression_from_total_xp(total_xp)

  state.total_xp = total_xp
  state.level = level
  state.xp = xp

  return {
    total_xp = total_xp,
    level = level,
    xp = xp,
    required = required
  }
end

local function create_blank_profile()
  return {
    xp = 0,
    total_xp = 0,
    level = 1,
    kills = 0,
    kill_credit = 0,
    damage = 0,
    skills = {},
    evolution = {},
    chip_quality = "normal",
    custom_name = "",
    show_name_label = false
  }
end

local function normalize_profile(profile)
  if type(profile) ~= "table" then
    profile = create_blank_profile()
  end

  profile.xp = profile.xp or 0
  profile.total_xp = profile.total_xp or 0
  profile.level = math.max(1, profile.level or 1)
  profile.kills = profile.kills or 0
  profile.kill_credit = profile.kill_credit or profile.kills or 0
  profile.damage = profile.damage or 0
  profile.dev_xp = profile.dev_xp or 0
  profile.chip_quality = profile.chip_quality or "normal"
  profile.custom_name = profile.custom_name or ""
  profile.show_name_label = profile.show_name_label == true
  ensure_evolution_state(profile)
  sync_turret_progression(profile)
  return profile
end

local function allocate_chip_id()
  ensure_storage()
  local id = "core-" .. tostring(storage.turret_xp.next_chip_id)
  storage.turret_xp.next_chip_id = storage.turret_xp.next_chip_id + 1
  return id
end

local function get_turret_host(entity, create)
  if not is_gun_turret(entity) then
    return nil
  end

  ensure_storage()
  local key = turret_key(entity)
  local host = storage.turret_xp.turrets[key]

  if host and not host.chip_id and (host.evolution or host.skills or host.total_xp or host.damage or host.kills) then
    local profile = normalize_profile(host)
    profile.chip_id = profile.chip_id or allocate_chip_id()
    profile.entity = entity
    storage.turret_xp.chips[profile.chip_id] = profile
    host = {
      chip_id = profile.chip_id
    }
    storage.turret_xp.turrets[key] = host
  end

  if not host and create then
    host = {}
    storage.turret_xp.turrets[key] = host
  end

  if host then
    host.entity = entity
  end

  return host
end

local function get_installed_profile(entity)
  local host = get_turret_host(entity, false)
  if not host or not host.chip_id then
    return nil
  end

  local profile = storage.turret_xp.chips[host.chip_id]
  if not profile then
    host.chip_id = nil
    return nil
  end

  profile.chip_id = host.chip_id
  profile.entity = entity
  return normalize_profile(profile)
end

local function get_turret_state(entity)
  return get_installed_profile(entity)
end

local function remove_turret_state(entity, destroy_profile)
  if not is_gun_turret(entity) then
    return
  end

  ensure_storage()
  local key = turret_key(entity)
  local host = storage.turret_xp.turrets[key]
  if destroy_profile and host and host.chip_id then
    storage.turret_xp.chips[host.chip_id] = nil
  end
  storage.turret_xp.turrets[key] = nil
end

local function copy_serializable(value)
  if type(value) ~= "table" then
    return value
  end

  local result = {}
  for key, child in pairs(value) do
    if key ~= "entity" and key ~= "name_render" and key ~= "feeder" then
      result[key] = copy_serializable(child)
    end
  end
  return result
end

local function serialize_profile(profile)
  profile = normalize_profile(profile)
  local evolution = ensure_evolution_state(profile)

  return {
    schema = 1,
    chip_id = profile.chip_id,
    chip_quality = profile.chip_quality or "normal",
    custom_name = profile.custom_name or "",
    show_name_label = profile.show_name_label == true,
    xp = profile.xp or 0,
    total_xp = profile.total_xp or 0,
    level = profile.level or 1,
    kills = profile.kills or 0,
    kill_credit = profile.kill_credit or 0,
    damage = profile.damage or 0,
    dev_xp = profile.dev_xp or 0,
    evolution = {
      base = copy_serializable(evolution.base or {}),
      augments = copy_serializable(evolution.augments or {}),
      element_mastery = copy_serializable(evolution.element_mastery or {}),
      elements = {
        evolution.elements and evolution.elements[1] or nil,
        evolution.elements and evolution.elements[2] or nil
      },
      specialization = evolution.specialization,
      element_project = copy_serializable(evolution.element_project)
    }
  }
end

local function deserialize_profile(data)
  local profile = create_blank_profile()
  if type(data) == "table" then
    profile.chip_id = data.chip_id
    profile.chip_quality = data.chip_quality or "normal"
    profile.custom_name = data.custom_name or ""
    profile.show_name_label = data.show_name_label == true
    profile.xp = data.xp or 0
    profile.total_xp = data.total_xp or 0
    profile.level = data.level or 1
    profile.kills = data.kills or 0
    profile.kill_credit = data.kill_credit or data.kills or 0
    profile.damage = data.damage or 0
    profile.dev_xp = data.dev_xp or 0
    profile.evolution = copy_serializable(data.evolution or {})
  end

  if type(profile.evolution) ~= "table" then
    profile.evolution = {}
  end

  local elements = profile.evolution.elements
  if type(elements) == "table" then
    profile.evolution.elements = {
      elements[1] or elements.first,
      elements[2] or elements.second
    }
  end

  return normalize_profile(profile)
end

local function read_profile_from_chip_stack(stack)
  if not stack or not stack.valid_for_read or stack.name ~= CHIP_NAME then
    return nil
  end

  local data = nil
  pcall(function()
    data = stack.get_tag(PROFILE_TAG)
  end)

  local profile = deserialize_profile(data)
  pcall(function()
    if stack.quality and stack.quality.name then
      profile.chip_quality = stack.quality.name
    end
  end)
  return normalize_profile(profile)
end

local function profile_description(profile)
  profile = normalize_profile(profile)
  local name = profile.custom_name or ""
  if name ~= "" then
    return { "item-description.turret-xp-veteran-core-profile-named", name, profile.level or 1 }
  end
  return { "item-description.turret-xp-veteran-core-profile", profile.level or 1 }
end

local function make_chip_item_stack(profile)
  local serialized = serialize_profile(profile)
  return {
    name = CHIP_NAME,
    count = 1,
    quality = serialized.chip_quality or "normal",
    tags = {
      [PROFILE_TAG] = serialized
    },
    custom_description = profile_description(serialized)
  }
end

local function find_carried_chip_stack(player)
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == CHIP_NAME then
    return cursor_stack
  end

  local inventory = player.get_main_inventory()
  if not inventory or not inventory.valid then
    return nil
  end

  for index = 1, #inventory do
    local stack = inventory[index]
    if stack and stack.valid_for_read and stack.name == CHIP_NAME then
      return stack
    end
  end

  return nil
end

local function remove_one_chip_stack(stack)
  if not stack or not stack.valid_for_read or stack.name ~= CHIP_NAME then
    return false
  end

  if stack.count and stack.count > 1 then
    stack.count = stack.count - 1
  else
    stack.clear()
  end
  return true
end

local function insert_chip_item(player, profile)
  local stack = make_chip_item_stack(profile)
  local ok, can_insert = pcall(function()
    return player.can_insert(stack)
  end)

  if not ok or not can_insert then
    return false
  end

  local inserted = player.insert(stack)
  return inserted and inserted > 0
end

local function spill_chip_item(entity, profile)
  if not entity or not entity.valid then
    return false
  end

  local ok = pcall(function()
    entity.surface.spill_item_stack({
      position = entity.position,
      stack = make_chip_item_stack(profile),
      enable_looted = true,
      allow_belts = false
    })
  end)

  return ok
end

local function destroy_name_render(profile)
  if profile and profile.name_render and profile.name_render.valid then
    profile.name_render.destroy()
  end
  if profile then
    profile.name_render = nil
  end
end

local function get_profile_label_text(profile)
  profile = normalize_profile(profile)
  local name = profile.custom_name or ""
  if name == "" then
    return nil
  end

  return name .. " (lvl " .. tostring(profile.level or 1) .. ")"
end

local function update_name_render(entity, profile)
  if not profile then
    return
  end

  if not is_gun_turret(entity) or not profile.show_name_label then
    destroy_name_render(profile)
    return
  end

  local text = get_profile_label_text(profile)
  if not text then
    destroy_name_render(profile)
    return
  end

  if profile.name_render and profile.name_render.valid then
    local ok = pcall(function()
      profile.name_render.text = text
      profile.name_render.target = {
        entity = entity,
        offset = { 0, -1.55 }
      }
      profile.name_render.surface = entity.surface
      profile.name_render.forces = { entity.force }
    end)
    if ok then
      return
    end
    destroy_name_render(profile)
  end

  local ok, render_object = pcall(function()
    return rendering.draw_text({
      text = text,
      surface = entity.surface,
      target = {
        entity = entity,
        offset = { 0, -1.55 }
      },
      color = { 1, 0.86, 0.46 },
      scale = 0.9,
      font = "default-bold",
      alignment = "center",
      vertical_alignment = "middle",
      scale_with_zoom = true,
      only_in_alt_mode = false,
      forces = { entity.force }
    })
  end)

  if ok then
    profile.name_render = render_object
  end
end

local function chip_id_is_installed(chip_id)
  if not chip_id then
    return false
  end

  ensure_storage()
  for _, host in pairs(storage.turret_xp.turrets) do
    if host and host.chip_id == chip_id then
      return true
    end
  end

  return false
end

local function install_profile_on_turret(entity, profile)
  if not is_gun_turret(entity) then
    return nil
  end

  ensure_storage()
  local host = get_turret_host(entity, true)
  if host.chip_id then
    return nil
  end

  profile = normalize_profile(profile)
  if not profile.chip_id or chip_id_is_installed(profile.chip_id) or storage.turret_xp.chips[profile.chip_id] then
    profile.chip_id = allocate_chip_id()
  end

  profile.entity = entity
  storage.turret_xp.chips[profile.chip_id] = profile
  host.chip_id = profile.chip_id
  feeder.ensure(entity, profile)
  update_name_render(entity, profile)
  return profile
end

local function detach_profile_from_turret(entity)
  local profile = get_installed_profile(entity)
  if not profile then
    return nil
  end

  local chip_id = profile.chip_id
  destroy_name_render(profile)
  feeder.destroy(profile, entity.position, true)
  profile.entity = nil
  if chip_id then
    storage.turret_xp.chips[chip_id] = nil
  end

  local host = get_turret_host(entity, false)
  if host then
    host.chip_id = nil
  end

  return profile
end

local function swap_turret_body(entity, target_name)
  if not is_gun_turret(entity) or entity.name == target_name then
    return entity
  end

  local function snapshot_inventory_contents(source, inventory_id)
    local inventory = source.get_inventory(inventory_id)
    local contents = {}
    if not inventory or not inventory.valid then
      return contents
    end

    for i = 1, #inventory do
      local stack = inventory[i]
      if stack and stack.valid_for_read then
        local entry = {
          name = stack.name,
          count = stack.count
        }
        pcall(function()
          if stack.quality and stack.quality.name then
            entry.quality = stack.quality.name
          end
        end)
        contents[i] = entry
      end
    end

    return contents
  end

  local function restore_inventory_contents(destination, inventory_id, contents)
    local inventory = destination.get_inventory(inventory_id)
    if not inventory or not inventory.valid then
      return
    end

    for i = 1, #inventory do
      local stack = inventory[i]
      if stack then
        stack.clear()
      end
    end

    for i, entry in pairs(contents or {}) do
      local stack = inventory[i]
      if stack and entry and entry.name and entry.count and entry.count > 0 then
        pcall(function()
          stack.set_stack(entry)
        end)
      end
    end
  end

  local surface = entity.surface
  local position = entity.position
  local force = entity.force
  local direction = entity.direction
  local original_name = entity.name
  local quality = safe_read(entity, "quality")
  local health = safe_read(entity, "health")
  local max_health = safe_read(entity, "max_health")
  local health_ratio = max_health and max_health > 0 and health and math.max(0.01, health / max_health) or 1
  local host = get_turret_host(entity, false)
  local chip_id = host and host.chip_id or nil
  local old_key = turret_key(entity)
  local ammo_contents = snapshot_inventory_contents(entity, defines.inventory.turret_ammo)

  local create_parameters = {
    name = target_name,
    position = position,
    force = force,
    direction = direction,
    spill = false,
    raise_built = false,
    create_build_effect_smoke = false
  }
  if quality and quality.name then
    create_parameters.quality = quality.name
  end

  entity.destroy({ raise_destroy = false })
  storage.turret_xp.turrets[old_key] = nil

  local ok, new_entity = pcall(function()
    return surface.create_entity(create_parameters)
  end)
  if not ok or not new_entity then
    create_parameters.quality = nil
    ok, new_entity = pcall(function()
      return surface.create_entity(create_parameters)
    end)
  end

  if not ok or not new_entity then
    create_parameters.name = original_name
    ok, new_entity = pcall(function()
      return surface.create_entity(create_parameters)
    end)
  end

  if not ok or not new_entity then
    return nil
  end

  local profile = chip_id and storage.turret_xp.chips[chip_id] or nil
  if profile then
    destroy_name_render(profile)
    profile.entity = new_entity
  end

  restore_inventory_contents(new_entity, defines.inventory.turret_ammo, ammo_contents)

  local new_max_health = safe_read(new_entity, "max_health")
  if new_max_health then
    new_entity.health = math.max(1, math.min(new_max_health, new_max_health * health_ratio))
  end

  local new_host = get_turret_host(new_entity, true)
  new_host.chip_id = chip_id

  if profile then
    update_name_render(new_entity, profile)
    feeder.ensure(new_entity, profile)
  end

  return new_entity
end

local function ensure_specialized_turret_body(entity, state)
  if not is_gun_turret(entity) then
    return entity
  end

  local specialization = state and ensure_evolution_state(state).specialization or nil
  local target_name = get_specialized_turret_name(specialization)
  return swap_turret_body(entity, target_name)
end

local function destroy_gui(player)
  local roots = {
    player.gui.relative,
    player.gui.left
  }

  for _, root in pairs(roots) do
    local panel = root[GUI.panel]
    if panel and panel.valid then
      panel.destroy()
    end
  end
end

local function remember_open_turret(player, entity)
  local player_state = ensure_player_state(player)
  player_state.entity = entity
  player_state.unit_number = entity.unit_number
end

local function forget_open_turret(player)
  ensure_storage()
  storage.turret_xp.players[player.index] = nil
end

local function get_remembered_turret(player)
  ensure_storage()
  local player_state = storage.turret_xp.players[player.index]
  if not player_state or not player_state.entity or not player_state.entity.valid then
    return nil
  end

  if not is_gun_turret(player_state.entity) then
    return nil
  end

  return player_state.entity
end

local function set_style(element, property, value)
  if element and element.valid and element.style then
    pcall(function()
      element.style[property] = value
    end)
  end
end

local function set_element_style(element, style)
  if element and element.valid then
    pcall(function()
      element.style = style
    end)
  end
end

local function find_gui_element(parent, name)
  if not parent or not parent.valid then
    return nil
  end

  if parent.name == name then
    return parent
  end

  for _, child in pairs(parent.children or {}) do
    local found = find_gui_element(child, name)
    if found then
      return found
    end
  end

  return nil
end

local function get_gui_panel(player)
  local panel = player.gui.relative[GUI.panel]
  if panel and panel.valid then
    return panel
  end

  panel = player.gui.left[GUI.panel]
  if panel and panel.valid then
    return panel
  end

  return nil
end

local function set_gui_caption(panel, name, caption, tooltip)
  local element = find_gui_element(panel, name)
  if element then
    element.caption = caption
    element.tooltip = tooltip
  end
end

local function set_gui_progress(panel, name, value)
  local element = find_gui_element(panel, name)
  if element then
    element.value = value
  end
end

safe_read = function(object, property)
  if not object then
    return nil
  end

  local ok, value = pcall(function()
    return object[property]
  end)

  if ok then
    return value
  end

  return nil
end

function feeder.get_inventory(entity)
  if not entity or not entity.valid then
    return nil
  end

  local ok, inventory = pcall(function()
    return entity.get_inventory(defines.inventory.chest)
  end)

  if ok and inventory and inventory.valid then
    return inventory
  end

  return nil
end

function feeder.spill_contents(entity, position)
  local inventory = feeder.get_inventory(entity)
  if not inventory then
    return
  end

  for index = 1, #inventory do
    local stack = inventory[index]
    if stack and stack.valid_for_read then
      local item = {
        name = stack.name,
        count = stack.count
      }
      pcall(function()
        if stack.quality and stack.quality.name then
          item.quality = stack.quality.name
        end
      end)
      pcall(function()
        entity.surface.spill_item_stack({
          position = position or entity.position,
          stack = item,
          enable_looted = true,
          allow_belts = false
        })
      end)
      stack.clear()
    end
  end
end

function feeder.destroy(state, position, spill)
  if not state then
    return
  end

  local entity = state.feeder
  state.feeder = nil
  if not entity or not entity.valid then
    return
  end

  ensure_storage()
  if entity.unit_number then
    storage.turret_xp.feeders[entity.unit_number] = nil
  end

  if spill then
    feeder.spill_contents(entity, position or entity.position)
  end

  pcall(function()
    entity.destroy({ raise_destroy = false })
  end)
end

function feeder.find_position(entity)
  if not is_gun_turret(entity) then
    return nil
  end

  local offsets = {
    { 1.5, 0 },
    { -1.5, 0 },
    { 0, 1.5 },
    { 0, -1.5 },
    { 1.5, 1.5 },
    { -1.5, 1.5 },
    { 1.5, -1.5 },
    { -1.5, -1.5 }
  }

  for _, offset in ipairs(offsets) do
    local position = {
      x = entity.position.x + offset[1],
      y = entity.position.y + offset[2]
    }
    local ok, can_place = pcall(function()
      return entity.surface.can_place_entity({
        name = FEEDER_NAME,
        position = position,
        force = entity.force
      })
    end)
    if ok and can_place then
      return position
    end
  end

  local ok, position = pcall(function()
    return entity.surface.find_non_colliding_position(FEEDER_NAME, entity.position, 4, 0.5)
  end)
  if ok then
    return position
  end

  return nil
end

function feeder.ensure(entity, state)
  if not is_gun_turret(entity) or not state then
    return nil
  end

  ensure_storage()

  local current = state.feeder
  if current and current.valid and current.name == FEEDER_NAME and current.surface == entity.surface then
    local dx = math.abs((current.position.x or 0) - (entity.position.x or 0))
    local dy = math.abs((current.position.y or 0) - (entity.position.y or 0))
    if dx <= 4 and dy <= 4 then
      if current.unit_number and state.chip_id then
        storage.turret_xp.feeders[current.unit_number] = state.chip_id
      end
      return current
    end
  end

  if current and current.valid then
    feeder.destroy(state, current.position, true)
  else
    state.feeder = nil
  end

  local position = feeder.find_position(entity)
  if not position then
    return nil
  end

  local ok, created = pcall(function()
    return entity.surface.create_entity({
      name = FEEDER_NAME,
      position = position,
      force = entity.force,
      raise_built = false,
      create_build_effect_smoke = false
    })
  end)

  if not ok or not created then
    return nil
  end

  pcall(function()
    created.destructible = false
  end)
  pcall(function()
    created.minable_flag = false
  end)

  state.feeder = created
  if created.unit_number and state.chip_id then
    storage.turret_xp.feeders[created.unit_number] = state.chip_id
  end

  return created
end

function feeder.remove_items(state, item_name, count)
  count = math.max(0, math.floor(tonumber(count) or 0))
  if count <= 0 or not item_name then
    return 0
  end

  local entity = state and state.feeder
  if state and is_gun_turret(state.entity) then
    entity = feeder.ensure(state.entity, state) or entity
  end

  local inventory = feeder.get_inventory(entity)
  if not inventory then
    return 0
  end

  local ok, removed = pcall(function()
    return inventory.remove({
      name = item_name,
      count = count
    })
  end)

  if ok and removed then
    return removed
  end

  return 0
end

function feeder.describe(state)
  local entity = state and state.feeder
  if state and is_gun_turret(state.entity) then
    entity = feeder.ensure(state.entity, state) or entity
  end
  local inventory = feeder.get_inventory(entity)
  if not inventory then
    return {
      valid = false,
      used = 0,
      total = 0,
      summary = { "turret-xp.feeder-missing" }
    }
  end

  local used = 0
  local counts = {}
  for index = 1, #inventory do
    local stack = inventory[index]
    if stack and stack.valid_for_read then
      used = used + 1
      counts[stack.name] = (counts[stack.name] or 0) + stack.count
    end
  end

  local parts = {}
  for _, element in ipairs(ELEMENTS) do
    local count = counts[element.resource] or 0
    if count > 0 then
      parts[#parts + 1] = "[item=" .. element.resource .. "] " .. tostring(math.floor(count + 0.5))
    end
  end

  local summary = #parts > 0 and table.concat(parts, "   ") or { "turret-xp.feeder-empty" }
  return {
    valid = true,
    used = used,
    total = #inventory,
    summary = summary
  }
end

function feeder.add_status(parent, state)
  if not parent or not parent.valid then
    return
  end

  local status = feeder.describe(state)
  local frame = parent.add({
    type = "frame",
    name = GUI.feeder_status,
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  })
  set_style(frame, "top_margin", 6)
  set_style(frame, "horizontally_stretchable", true)

  local row = frame.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(row, "horizontally_stretchable", true)
  set_style(row, "vertical_align", "center")

  local ok = pcall(function()
    row.add({
      type = "sprite",
      sprite = "entity/" .. FEEDER_NAME
    })
  end)
  if not ok then
    row.add({
      type = "sprite",
      sprite = "item/iron-chest"
    })
  end

  local title = row.add({
    type = "label",
    caption = { "turret-xp.feeder-title" },
    style = "caption_label"
  })
  set_style(title, "font", "default-bold")

  row.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })

  local slots = row.add({
    type = "label",
    caption = status.valid
      and { "turret-xp.feeder-slots", status.used, status.total }
      or { "turret-xp.feeder-no-slots" },
    style = "caption_label"
  })
  set_style(slots, "font_color", status.valid and COLOR.muted or { 1, 0.55, 0.45 })

  local contents = frame.add({
    type = "label",
    caption = status.summary,
    style = "caption_label"
  })
  set_style(contents, "font_color", status.valid and COLOR.muted or { 1, 0.55, 0.45 })
  set_style(contents, "single_line", false)
end

local function as_array(value)
  if not value then
    return {}
  end

  if value[1] ~= nil then
    return value
  end

  return { value }
end

local sum_trigger_items
local find_damage_type_in_trigger_items

local function sum_damage_effects(effects)
  local total = 0

  for _, effect in pairs(as_array(effects)) do
    local repeats = effect.repeat_count or 1
    local probability = effect.probability or 1

    if effect.type == "damage" and effect.damage and effect.damage.amount then
      total = total + (effect.damage.amount * repeats * probability)
    elseif effect.type == "nested-result" then
      total = total + (sum_trigger_items(effect.action) * repeats * probability)
    end
  end

  return total
end

local function find_damage_type_in_effects(effects)
  for _, effect in pairs(as_array(effects)) do
    if effect.type == "damage" and effect.damage and effect.damage.type then
      return effect.damage.type
    elseif effect.type == "nested-result" then
      local damage_type = find_damage_type_in_trigger_items(effect.action)
      if damage_type then
        return damage_type
      end
    end
  end

  return nil
end

local function sum_trigger_deliveries(deliveries)
  local total = 0

  for _, delivery in pairs(as_array(deliveries)) do
    total = total + sum_damage_effects(delivery.target_effects)
  end

  return total
end

local function find_damage_type_in_deliveries(deliveries)
  for _, delivery in pairs(as_array(deliveries)) do
    local damage_type = find_damage_type_in_effects(delivery.target_effects)
    if damage_type then
      return damage_type
    end
  end

  return nil
end

sum_trigger_items = function(items)
  local total = 0

  for _, item in pairs(as_array(items)) do
    local repeats = item.repeat_count or 1
    local probability = item.probability or 1
    local damage = sum_trigger_deliveries(item.action_delivery)

    if item.type == "line" then
      damage = damage + sum_damage_effects(item.range_effects)
    end

    total = total + (damage * repeats * probability)
  end

  return total
end

find_damage_type_in_trigger_items = function(items)
  for _, item in pairs(as_array(items)) do
    local damage_type = find_damage_type_in_deliveries(item.action_delivery)
    if damage_type then
      return damage_type
    end

    if item.type == "line" then
      damage_type = find_damage_type_in_effects(item.range_effects)
      if damage_type then
        return damage_type
      end
    end
  end

  return nil
end

local function get_attack_parameters(entity)
  return safe_read(safe_read(entity, "prototype"), "attack_parameters") or {}
end

local function get_loaded_ammo(entity)
  local inventory = entity.get_inventory(defines.inventory.turret_ammo)
  if not inventory or not inventory.valid then
    return nil, 0, nil
  end

  local ammo_name = nil
  local ammo_quality = nil
  local count = 0

  for i = 1, #inventory do
    local stack = inventory[i]
    if stack and stack.valid_for_read then
      ammo_name = ammo_name or stack.name
      if not ammo_quality and stack.name == ammo_name then
        local quality = safe_read(stack, "quality")
        ammo_quality = quality and quality.name or "normal"
      end
      if stack.name == ammo_name then
        count = count + stack.count
      end
    end
  end

  return ammo_name, count, ammo_quality
end

local function get_ammo_type(ammo_name)
  if not ammo_name then
    return nil
  end

  local ammo = prototypes.item[ammo_name]
  if not ammo then
    return nil
  end

  local ok, ammo_type = pcall(function()
    return ammo.get_ammo_type("turret")
  end)

  if ok then
    return ammo_type
  end

  return nil
end

local function get_ammo_category_name(entity, ammo_name)
  if ammo_name then
    local ammo = prototypes.item[ammo_name]
    local ammo_category = safe_read(ammo, "ammo_category")
    local ammo_category_name = safe_read(ammo_category, "name")
    if ammo_category_name then
      return ammo_category_name
    end
  end

  local attack_parameters = get_attack_parameters(entity)
  local categories = attack_parameters.ammo_categories
  if categories and categories[1] then
    return categories[1]
  end

  return nil
end

local function format_number(value, decimals)
  if not value then
    return "-"
  end

  if math.abs(value - math.floor(value)) < 0.01 then
    return string.format("%d", math.floor(value + 0.5))
  end

  return string.format("%." .. tostring(decimals or 1) .. "f", value)
end

local function format_colored_bonus(value, decimals)
  local formatted = format_number(math.abs(value), decimals)
  local sign = value < 0 and "- " or "+ "
  return "[color=" .. COLOR.bonus[1] .. "," .. COLOR.bonus[2] .. "," .. COLOR.bonus[3] .. "]" .. sign .. formatted .. "[/color]"
end

local function format_base_plus_bonus(base, bonus, suffix, decimals)
  suffix = suffix or ""

  if not base then
    return "-"
  end

  if bonus and math.abs(bonus) >= 0.005 then
    return format_number(base, decimals) .. " " .. format_colored_bonus(bonus, decimals) .. suffix
  end

  return format_number(base, decimals) .. suffix
end

local function get_entity_quality_name(entity)
  local quality = safe_read(entity, "quality")
  return quality and quality.name or "normal"
end

local function get_quality_prototypes()
  local qualities = {}
  local quality_prototypes = safe_read(prototypes, "quality")

  if not quality_prototypes then
    return qualities
  end

  for _, quality in pairs(quality_prototypes) do
    if quality and quality.valid and quality.name ~= "quality-unknown" and not safe_read(quality, "hidden") then
      qualities[#qualities + 1] = quality
    end
  end

  table.sort(qualities, function(a, b)
    local a_level = safe_read(a, "level") or 0
    local b_level = safe_read(b, "level") or 0
    if a_level == b_level then
      return a.name < b.name
    end
    return a_level < b_level
  end)

  return qualities
end

local function get_quality_localised_name(quality)
  return safe_read(quality, "localised_name") or { "quality-name." .. quality.name }
end

local function get_quality_multiplier(quality, property)
  return safe_read(quality, property) or safe_read(quality, "default_multiplier") or 1
end

local function make_quality_tooltip(value_for_quality, suffix)
  local qualities = get_quality_prototypes()
  if #qualities < 2 then
    return nil
  end

  local tooltip = { "", { "turret-xp.quality-summary-title" }, "\n" }
  for index, quality in ipairs(qualities) do
    local value = value_for_quality(quality)
    if value then
      tooltip[#tooltip + 1] = {
        "",
        "[quality=", quality.name, "] ",
        get_quality_localised_name(quality),
        ": ",
        value,
        suffix or ""
      }
      if index < #qualities then
        tooltip[#tooltip + 1] = "\n"
      end
    end
  end

  return tooltip
end

local function with_info_marker(caption, tooltip)
  if tooltip then
    return { "", caption, " [img=info]" }
  end

  return caption
end

local function with_quality_marker(caption, tooltip)
  if tooltip then
    return { "", caption, " [img=quality_info]" }
  end

  return caption
end

local function get_shooting_speed_values(entity, ammo_name)
  local attack_parameters = get_attack_parameters(entity)
  if not attack_parameters.cooldown or attack_parameters.cooldown <= 0 then
    return nil, nil
  end

  local cooldown = attack_parameters.cooldown

  if ammo_name then
    local ammo_type = get_ammo_type(ammo_name)
    if ammo_type and ammo_type.cooldown_modifier then
      cooldown = cooldown * ammo_type.cooldown_modifier
    end
  end

  local base_speed = 60 / cooldown
  local speed_modifier = 0
  local force = safe_read(entity, "force")
  local ammo_category_name = get_ammo_category_name(entity, ammo_name)

  if force and ammo_category_name then
    local ok, modifier = pcall(function()
      return force.get_gun_speed_modifier(ammo_category_name)
    end)

    if ok and modifier then
      speed_modifier = modifier
    end
  end

  local bonus_speed = base_speed * speed_modifier
  return base_speed, bonus_speed
end

local function format_shots_per_second(entity, ammo_name)
  local base_speed, bonus_speed = get_shooting_speed_values(entity, ammo_name)
  return format_base_plus_bonus(base_speed, bonus_speed, "/s", 2)
end

local function get_damage_values(entity, ammo_name)
  if not ammo_name then
    return nil, nil
  end

  local ammo_type = get_ammo_type(ammo_name)
  if not ammo_type then
    return nil, nil
  end

  local attack_parameters = get_attack_parameters(entity)
  local base_damage = sum_trigger_items(ammo_type.action) * (attack_parameters.damage_modifier or 1)
  local bonus_damage = 0
  local force = safe_read(entity, "force")
  local ammo_category_name = get_ammo_category_name(entity, ammo_name)
  local ammo_modifier = 0
  local turret_modifier = 0

  if force and ammo_category_name then
    local ok, modifier = pcall(function()
      return force.get_ammo_damage_modifier(ammo_category_name)
    end)

    if ok and modifier then
      ammo_modifier = modifier
    end
  end

  if force then
    local ok, modifier = pcall(function()
      return force.get_turret_attack_modifier(entity.name)
    end)

    if ok and modifier then
      turret_modifier = modifier
    end
  end

  local final_damage = base_damage * (1 + ammo_modifier) * (1 + turret_modifier)
  bonus_damage = final_damage - base_damage

  local damage_type = find_damage_type_in_trigger_items(ammo_type.action) or "physical"

  return base_damage, bonus_damage, damage_type
end

local function format_damage_per_shot(entity, ammo_name)
  local base_damage, bonus_damage, damage_type = get_damage_values(entity, ammo_name)
  local formatted = format_base_plus_bonus(base_damage, bonus_damage, "", 1)
  if damage_type and formatted ~= "-" then
    return { "turret-xp.damage-value-with-type", formatted, { "damage-type-name." .. damage_type } }
  end

  return formatted
end

local function get_final_damage_per_shot(entity, ammo_name)
  local base_damage, bonus_damage = get_damage_values(entity, ammo_name)
  if not base_damage then
    return nil
  end

  return base_damage + (bonus_damage or 0)
end

local function get_final_shots_per_second(entity, ammo_name)
  local base_speed, bonus_speed = get_shooting_speed_values(entity, ammo_name)
  if not base_speed then
    return nil
  end

  return base_speed + (bonus_speed or 0)
end

local function format_estimated_dps(entity, ammo_name)
  local damage = get_final_damage_per_shot(entity, ammo_name)
  local speed = get_final_shots_per_second(entity, ammo_name)
  if not damage or not speed then
    return "-"
  end

  return format_number(damage * speed, 1) .. "/s"
end

local function get_max_health_for_quality(entity, quality_name)
  local prototype = safe_read(entity, "prototype")
  if not prototype then
    return nil
  end

  local ok, max_health = pcall(function()
    return prototype.get_max_health(quality_name)
  end)

  if ok then
    return max_health
  end

  return nil
end

local format_range_for_quality

local function format_range(entity)
  return format_range_for_quality(entity, get_entity_quality_name(entity))
end

local function get_range_for_quality(entity, quality_name)
  local attack_parameters = get_attack_parameters(entity)
  if not attack_parameters.range then
    return nil
  end

  local quality = safe_read(prototypes.quality, quality_name)
  if not quality then
    return attack_parameters.range
  end

  return attack_parameters.range * get_quality_multiplier(quality, "range_multiplier")
end

format_range_for_quality = function(entity, quality_name)
  return format_number(get_range_for_quality(entity, quality_name), 1)
end

local function target_prior_damage(event, damage)
  local max_health = safe_read(event.entity, "max_health")
  local final_health = event.final_health

  if not max_health or not final_health then
    return 0
  end

  local pre_hit_health = final_health + damage
  return math.max(0, max_health - pre_hit_health)
end

local function get_or_create_target_damage(event, damage, create)
  ensure_storage()

  local key = entity_tracking_key(event.entity)
  if not key then
    return nil
  end

  local entry = storage.turret_xp.targets[key]
  if not entry and create then
    entry = {
      total_damage = target_prior_damage(event, damage),
      turrets = {},
      tick = game.tick
    }
    storage.turret_xp.targets[key] = entry
  end

  return entry, key
end

local function record_damage_contribution(event, turret, damage)
  local profile = is_gun_turret(turret) and get_turret_state(turret) or nil
  local create = profile ~= nil
  local entry = get_or_create_target_damage(event, damage, create)

  if not entry then
    return
  end

  entry.total_damage = (entry.total_damage or 0) + damage
  entry.tick = game.tick

  if not create then
    return
  end

  local key = turret_key(turret)
  local contributor = entry.turrets[key]
  if not contributor then
    contributor = {
      damage = 0,
      entity = turret,
      chip_id = profile.chip_id
    }
    entry.turrets[key] = contributor
  end

  contributor.damage = (contributor.damage or 0) + damage
  contributor.entity = turret
  contributor.chip_id = profile.chip_id
end

local function award_kill_credit(target, killing_turret)
  ensure_storage()

  local target_key = entity_tracking_key(target)
  local entry = target_key and storage.turret_xp.targets[target_key] or nil

  if entry and entry.total_damage and entry.total_damage > 0 then
    for contributor_key, contributor in pairs(entry.turrets or {}) do
      local contribution = math.max(0, contributor.damage or 0)
      local credit = contribution / entry.total_damage

      if credit > 0 then
        local turret = contributor.entity
        local state = nil

        if contributor.chip_id then
          state = storage.turret_xp.chips[contributor.chip_id]
        elseif is_gun_turret(turret) then
          state = get_turret_state(turret)
        end

        if state then
          state.kill_credit = (state.kill_credit or state.kills or 0) + credit
          sync_turret_progression(state)
          if is_gun_turret(state.entity) then
            update_name_render(state.entity, state)
          end
        end
      end
    end

    storage.turret_xp.targets[target_key] = nil
    return
  end

  if is_gun_turret(killing_turret) then
    local state = get_turret_state(killing_turret)
    if state then
      state.kill_credit = (state.kill_credit or state.kills or 0) + 1
      sync_turret_progression(state)
      if is_gun_turret(state.entity) then
        update_name_render(state.entity, state)
      end
    end
  end
end

local function cleanup_target_damage()
  ensure_storage()

  for key, entry in pairs(storage.turret_xp.targets) do
    if not entry.tick or game.tick - entry.tick > TARGET_DAMAGE_TTL then
      storage.turret_xp.targets[key] = nil
    end
  end
end

local function add_stat_row(parent, label, element_name, options)
  options = options or {}

  local label_element = parent.add({
    type = "label",
    caption = with_info_marker(label, options.info_tooltip),
    tooltip = options.info_tooltip,
    style = "caption_label"
  })
  set_style(label_element, "font_color", COLOR.caption)
  set_style(label_element, "single_line", true)

  local value_flow = parent.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(value_flow, "horizontal_align", "right")
  set_style(value_flow, "horizontally_stretchable", true)

  local value_element = value_flow.add({
    type = "label",
    name = element_name,
    caption = "-",
    style = options.value_style or "label"
  })
  set_style(value_element, "horizontal_align", "right")
  set_style(value_element, "single_line", false)
  set_style(value_element, "maximal_width", options.maximal_width or 240)

  return label_element, value_element
end

local function make_stats_table(parent)
  local stat_table = parent.add({
    type = "table",
    column_count = 2,
    draw_horizontal_lines = true
  })
  set_style(stat_table, "horizontally_stretchable", true)
  set_style(stat_table, "horizontal_spacing", 12)
  pcall(function()
    stat_table.style.column_alignments[1] = "left"
    stat_table.style.column_alignments[2] = "right"
  end)
  return stat_table
end

local function add_xp_panel(parent)
  local xp_panel = parent.add({
    type = "frame",
    direction = "vertical",
    style = "deep_frame_in_shallow_frame"
  })
  set_style(xp_panel, "horizontally_stretchable", true)
  set_style(xp_panel, "padding", { 8, 8, 8, 8 })

  local top = xp_panel.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(top, "horizontally_stretchable", true)
  set_style(top, "vertical_align", "center")

  local level = top.add({
    type = "label",
    name = GUI.level,
    caption = { "turret-xp.level", 1 },
    style = "heading_2_label"
  })
  set_style(level, "font", "default-bold")

  top.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })

  local xp = top.add({
    type = "label",
    name = GUI.xp,
    caption = { "turret-xp.xp-progress", 0, 0 },
    style = "caption_label"
  })
  set_style(xp, "font_color", COLOR.muted)

  local bar = xp_panel.add({
    type = "progressbar",
    name = GUI.xp_bar,
    style = "turret_xp_xp_progressbar",
    value = 0
  })
  set_style(bar, "horizontally_stretchable", true)
  set_style(bar, "height", 18)
  set_style(bar, "top_margin", 4)
  set_style(bar, "bottom_margin", 0)

  local percent = xp_panel.add({
    type = "label",
    name = GUI.xp_percent,
    caption = { "turret-xp.progress-percent", 0 },
    style = "caption_label"
  })
  set_style(percent, "font_color", COLOR.muted)
  set_style(percent, "top_margin", 2)
end

local function add_core_panel(parent)
  local core_panel = parent.add({
    type = "frame",
    name = GUI.core,
    direction = "vertical",
    style = "deep_frame_in_shallow_frame"
  })
  set_style(core_panel, "horizontally_stretchable", true)
  set_style(core_panel, "padding", { 8, 8, 8, 8 })
  set_style(core_panel, "bottom_margin", 6)
  return core_panel
end

local function core_panel_key(player, state)
  if state then
    return "installed:" .. tostring(state.chip_id or "")
  end

  return "empty:" .. (find_carried_chip_stack(player) and "ready" or "none")
end

local function add_dev_controls_panel(parent)
  local panel = parent.add({
    type = "frame",
    name = GUI.dev,
    direction = "horizontal",
    style = "deep_frame_in_shallow_frame"
  })
  set_style(panel, "horizontally_stretchable", true)
  set_style(panel, "padding", { 6, 6, 6, 6 })
  set_style(panel, "bottom_margin", 6)
  set_style(panel, "vertical_align", "center")

  local label = panel.add({
    type = "label",
    caption = "Dev",
    style = "caption_label"
  })
  set_style(label, "font", "default-bold")
  set_style(label, "right_margin", 4)

  panel.add({
    type = "button",
    caption = "+1 level",
    tags = {
      turret_xp_action = "dev-level",
      levels = 1
    }
  })
  panel.add({
    type = "button",
    caption = "+5 levels",
    tags = {
      turret_xp_action = "dev-level",
      levels = 5
    }
  })
  panel.add({
    type = "button",
    caption = "Materials",
    tags = {
      turret_xp_action = "dev-complete-project"
    }
  })
end

local function update_core_panel(root, player, entity, state)
  local core_panel = find_gui_element(root, GUI.core)
  if not core_panel then
    return
  end

  local key = core_panel_key(player, state)
  if (core_panel.tags or {}).key == key then
    local profile_line = find_gui_element(core_panel, GUI.core_profile)
    if profile_line and state then
      profile_line.caption = {
        "turret-xp.core-profile-summary",
        state.chip_id or "-",
        state.level or 1,
        state.kills or 0,
        format_number(state.damage or 0, 0)
      }
    end
    if state then
      update_name_render(entity, state)
    end
    return
  end

  core_panel.clear()
  core_panel.tags = {
    key = key
  }

  local top = core_panel.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(top, "horizontally_stretchable", true)
  set_style(top, "vertical_align", "center")

  local icon = top.add({
    type = "sprite-button",
    name = GUI.core_slot,
    sprite = "item/" .. CHIP_NAME,
    quality = state and (state.chip_quality or "normal") or "normal",
    elem_tooltip = {
      type = "item-with-quality",
      name = CHIP_NAME,
      quality = state and (state.chip_quality or "normal") or "normal"
    },
    tooltip = state and { "turret-xp.extract-core-tooltip" } or { "turret-xp.install-core-tooltip" },
    tags = {
      turret_xp_action = state and "extract-core" or "install-core"
    },
    enabled = state ~= nil or find_carried_chip_stack(player) ~= nil
  })
  set_element_style(icon, state and "flib_slot_button_green" or "slot_button")
  set_style(icon, "size", 40)

  local label = top.add({
    type = "label",
    name = GUI.core_status,
    caption = state and "Veteran Core installed" or "No Veteran Core installed",
    style = "caption_label"
  })
  set_style(label, "font", "default-bold")

  top.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })

  if not state then
    local actions = top.add({
      type = "flow",
      name = GUI.core_actions,
      direction = "horizontal"
    })
    set_style(actions, "horizontal_spacing", 4)
    actions.add({
      type = "button",
      caption = "Dev core",
      tags = {
        turret_xp_action = "dev-create-core"
      }
    })
  end

  if not state then
    local note = core_panel.add({
      type = "label",
      caption = { "turret-xp.no-core-note" },
      style = "caption_label"
    })
    set_style(note, "font_color", COLOR.muted)
    set_style(note, "single_line", false)
    return
  end

  local profile_line = core_panel.add({
    type = "label",
    name = GUI.core_profile,
    caption = {
      "turret-xp.core-profile-summary",
      state.chip_id or "-",
      state.level or 1,
      state.kills or 0,
      format_number(state.damage or 0, 0)
    },
    style = "caption_label"
  })
  set_style(profile_line, "font_color", COLOR.muted)
  set_style(profile_line, "single_line", false)

  local name_flow = core_panel.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(name_flow, "top_margin", 4)
  set_style(name_flow, "vertical_align", "center")

  name_flow.add({
    type = "label",
    caption = "Name",
    style = "caption_label"
  })

  local textfield = name_flow.add({
    type = "textfield",
    name = GUI.core_name,
    text = state.custom_name or "",
    clear_and_focus_on_right_click = true,
    lose_focus_on_confirm = true
  })
  set_style(textfield, "minimal_width", 150)
  set_style(textfield, "maximal_width", 190)

  name_flow.add({
    type = "checkbox",
    name = GUI.core_name_visible,
    caption = "Show label",
    state = state.show_name_label == true,
    tags = {
      turret_xp_action = "toggle-core-label"
    }
  })

  update_name_render(entity, state)
end

local function update_ammo_row(panel, ammo_name, ammo_count, ammo_quality)
  local flow = find_gui_element(panel, GUI.ammo)
  if not flow then
    return
  end

  local current_tags = flow.tags or {}
  if current_tags.ammo_name == (ammo_name or "")
    and current_tags.ammo_count == (ammo_count or 0)
    and current_tags.ammo_quality == (ammo_quality or "")
  then
    return
  end

  flow.tags = {
    ammo_name = ammo_name or "",
    ammo_count = ammo_count or 0,
    ammo_quality = ammo_quality or ""
  }

  flow.clear()
  if not ammo_name then
    flow.add({
      type = "sprite",
      sprite = "flib_indicator_yellow",
      style = "flib_indicator",
      tooltip = { "turret-xp.no-ammo" }
    })
    return
  end

  local ok, button = pcall(function()
    return flow.add({
      type = "sprite-button",
      sprite = "item/" .. ammo_name,
      quality = ammo_quality or "normal",
      number = ammo_count,
      elem_tooltip = {
        type = "item-with-quality",
        name = ammo_name,
        quality = ammo_quality or "normal"
      }
    })
  end)

  if ok and button then
    set_element_style(button, "flib_slot_button_green")
    set_style(button, "size", 36)
    return
  end

  flow.add({
    type = "label",
    caption = string.format("[item=%s] x%d", ammo_name, ammo_count)
  })
end

local function add_evolution_panel(parent)
  local outer = parent.add({
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  })
  set_style(outer, "top_margin", 6)
  set_style(outer, "horizontally_stretchable", true)

  local panel = outer.add({
    type = "scroll-pane",
    name = GUI.evolution,
    direction = "vertical",
    vertical_scroll_policy = "auto",
    horizontal_scroll_policy = "never"
  })
  set_style(panel, "horizontally_stretchable", true)
  set_style(panel, "maximal_height", 360)
  set_style(panel, "padding", { 0, 0, 0, 0 })
  return panel
end

local function element_name(element_id)
  local element = ELEMENT_BY_ID[element_id]
  return element and element.name or "None"
end

local function has_level(state, level)
  return (state.level or 1) >= level
end

local function add_header(parent, title, state)
  local header = parent.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(header, "horizontally_stretchable", true)
  set_style(header, "vertical_align", "center")

  local label = header.add({
    type = "label",
    caption = title,
    style = "heading_2_label"
  })
  set_style(label, "font", "default-bold")

  header.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })

  local points = header.add({
    type = "label",
    name = GUI.skill_points,
    caption = "Core points: " .. tostring(get_available_skill_points(state)),
    style = "caption_label"
  })
  set_style(points, "font_color", COLOR.muted)
end

local function add_section(parent, title, unlocked, gate_level)
  local section = parent.add({
    type = "frame",
    direction = "vertical",
    style = "deep_frame_in_shallow_frame"
  })
  set_style(section, "top_margin", 6)
  set_style(section, "padding", { 6, 6, 6, 6 })
  set_style(section, "horizontally_stretchable", true)

  if not unlocked then
    set_style(section, "height", 70)
    set_style(section, "vertical_align", "center")
    local locked = section.add({
      type = "label",
      caption = "Unlocks at level " .. tostring(gate_level),
      style = "caption_label"
    })
    set_style(locked, "font", "default-bold")
    set_style(locked, "horizontally_stretchable", true)
    set_style(locked, "horizontal_align", "center")
    return section
  end

  if not title or title == "" then
    return section
  end

  local header = section.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(header, "horizontally_stretchable", true)
  set_style(header, "vertical_align", "center")

  local title_label = header.add({
    type = "label",
    caption = title,
    style = "caption_label"
  })
  set_style(title_label, "font", "default-bold")

  return section
end

local function add_row(parent, sprite, name, detail, right_caption, tags, enabled)
  local row = parent.add({
    type = "table",
    column_count = 3
  })
  set_style(row, "horizontally_stretchable", true)
  set_style(row, "horizontal_spacing", 8)
  set_style(row, "vertical_spacing", 2)
  pcall(function()
    row.style.column_alignments[1] = "left"
    row.style.column_alignments[2] = "left"
    row.style.column_alignments[3] = "right"
  end)

  local icon = row.add({
    type = "sprite",
    sprite = sprite
  })
  set_style(icon, "size", 28)

  local details = row.add({
    type = "flow",
    direction = "vertical"
  })
  set_style(details, "horizontally_stretchable", true)

  local title = details.add({
    type = "label",
    caption = name,
    style = "caption_label"
  })
  set_style(title, "font", "default-bold")

  if detail and detail ~= "" then
    local desc = details.add({
      type = "label",
      caption = detail,
      style = "caption_label"
    })
    set_style(desc, "font_color", COLOR.muted)
    set_style(desc, "single_line", false)
    set_style(desc, "maximal_width", 260)
  end

  if tags then
    local button = row.add({
      type = "button",
      caption = right_caption,
      tags = tags,
      enabled = enabled
    })
    set_style(button, "minimal_width", 72)
    return button
  end

  local value = row.add({
    type = "label",
    caption = right_caption or "",
    style = "caption_label"
  })
  set_style(value, "font_color", COLOR.muted)
  return value
end

local function add_allocation_row(parent, sprite, name, value_caption, button_caption, tags, enabled)
  local row = parent.add({
    type = "table",
    column_count = 4
  })
  set_style(row, "horizontally_stretchable", true)
  set_style(row, "horizontal_spacing", 8)
  set_style(row, "vertical_spacing", 2)
  pcall(function()
    row.style.column_alignments[1] = "left"
    row.style.column_alignments[2] = "left"
    row.style.column_alignments[3] = "right"
    row.style.column_alignments[4] = "right"
  end)

  local icon = row.add({
    type = "sprite",
    sprite = sprite
  })
  set_style(icon, "size", 28)

  local title = row.add({
    type = "label",
    caption = name,
    style = "caption_label"
  })
  set_style(title, "font", "default-bold")
  set_style(title, "horizontally_stretchable", true)

  local value = row.add({
    type = "label",
    caption = value_caption or "",
    style = "caption_label"
  })
  set_style(value, "font_color", COLOR.bonus)
  set_style(value, "horizontal_align", "right")

  local button = row.add({
    type = "button",
    caption = button_caption or "+",
    tags = tags,
    enabled = enabled
  })
  set_style(button, "size", 28)
  set_style(button, "minimal_width", 28)
  set_style(button, "maximal_width", 28)

  return button
end

local function get_project_totals(project)
  local delivered_total = 0
  local required_total = 0

  for _, requirement in ipairs(project.requirements or {}) do
    local delivered = math.min(requirement.count, (project.delivered and project.delivered[requirement.name]) or 0)
    delivered_total = delivered_total + delivered
    required_total = required_total + requirement.count
  end

  return delivered_total, required_total
end

local function finish_element_project(state)
  local evolution = ensure_evolution_state(state)
  local project = evolution.element_project
  local delivered, required = 0, 0
  if project then
    delivered, required = get_project_totals(project)
  end
  if not project or required <= 0 or delivered < required then
    return false
  end

  evolution.elements[project.slot] = project.element
  local mastery = evolution.element_mastery[project.element]
  if mastery then
    mastery.rank = math.max(1, mastery.rank or 0)
    mastery.delivered = 0
  end
  evolution.element_project = nil
  return true
end

local function advance_element_mastery(state, element_id)
  local element = ELEMENT_BY_ID[element_id]
  if not state or not element then
    return
  end

  local evolution = ensure_evolution_state(state)
  local mastery = evolution.element_mastery[element_id]
  if not mastery or (mastery.rank or 0) <= 0 then
    return
  end

  while true do
    local required = get_element_requirement_count(element, (mastery.rank or 0) + 1)
    if (mastery.delivered or 0) < required then
      break
    end
    mastery.delivered = mastery.delivered - required
    mastery.rank = mastery.rank + 1
  end
end

local function make_project_requirement_text(project)
  local parts = {}
  for _, requirement in ipairs(project.requirements or {}) do
    local delivered = (project.delivered and project.delivered[requirement.name]) or 0
    parts[#parts + 1] = {
      "",
      "[item=", requirement.name, "] ",
      { "item-name." .. requirement.name },
      " ",
      format_number(math.min(delivered, requirement.count), 0),
      " / ",
      format_number(requirement.count, 0)
    }
  end

  local text = { "" }
  for index, part in ipairs(parts) do
    if index > 1 then
      text[#text + 1] = "\n"
    end
    text[#text + 1] = part
  end

  return text
end

local function make_requirement_summary(requirements)
  local parts = {}
  for _, requirement in ipairs(requirements or {}) do
    parts[#parts + 1] = requirement.name .. " x" .. tostring(requirement.count)
  end

  if #parts == 0 then
    return "No materials required."
  end

  return "Requires: " .. table.concat(parts, ", ")
end

local function add_project_panel(parent, state)
  local evolution = ensure_evolution_state(state)
  local project = evolution.element_project
  if not project then
    return
  end

  local element = ELEMENT_BY_ID[project.element]
  if not element then
    return
  end

  local frame = parent.add({
    type = "frame",
    name = GUI.element_project,
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  })
  set_style(frame, "top_margin", 6)
  set_style(frame, "horizontally_stretchable", true)

  local delivered, required = get_project_totals(project)
  local progress = required > 0 and math.min(1, delivered / required) or 0

  local title = frame.add({
    type = "label",
    caption = "Active project: " .. element.name .. " slot " .. tostring(project.slot),
    style = "caption_label"
  })
  set_style(title, "font", "default-bold")

  local requirements = frame.add({
    type = "label",
    caption = make_project_requirement_text(project),
    style = "caption_label"
  })
  set_style(requirements, "single_line", false)

  local bar = frame.add({
    type = "progressbar",
    name = GUI.element_project_bar,
    value = progress
  })
  set_style(bar, "horizontally_stretchable", true)

  local note = frame.add({
    type = "label",
    caption = { "turret-xp.feeder-project-note" },
    style = "caption_label"
  })
  set_style(note, "font_color", COLOR.muted)
end

local function add_element_mastery_panel(parent, state, element_id)
  local element = ELEMENT_BY_ID[element_id]
  if not element then
    return
  end

  local evolution = ensure_evolution_state(state)
  local mastery = evolution.element_mastery[element_id]
  if not mastery or (mastery.rank or 0) <= 0 then
    return
  end

  local next_rank = mastery.rank + 1
  local required = get_element_requirement_count(element, next_rank)
  local delivered = math.min(required, mastery.delivered or 0)

  local frame = parent.add({
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  })
  set_style(frame, "top_margin", 6)
  set_style(frame, "horizontally_stretchable", true)

  local top = frame.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(top, "horizontally_stretchable", true)
  set_style(top, "vertical_align", "center")

  top.add({
    type = "sprite",
    sprite = element.sprite
  })

  local title = top.add({
    type = "label",
    caption = element.name .. " rank " .. tostring(mastery.rank),
    style = "caption_label"
  })
  set_style(title, "font", "default-bold")

  top.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })

  local requirement = top.add({
    type = "label",
    caption = "[item=" .. element.resource .. "] " .. format_number(delivered, 0) .. " / " .. format_number(required, 0),
    style = "caption_label"
  })
  set_style(requirement, "font_color", COLOR.muted)

  local bar = frame.add({
    type = "progressbar",
    value = required > 0 and math.min(1, delivered / required) or 0
  })
  set_style(bar, "horizontally_stretchable", true)

  local note = frame.add({
    type = "label",
    caption = { "turret-xp.feeder-project-note" },
    style = "caption_label"
  })
  set_style(note, "font_color", COLOR.muted)
end

local get_combo_caption_for_pair

local function get_combo_caption(state)
  local evolution = ensure_evolution_state(state)
  local first = evolution.elements[1]
  local second = evolution.elements[2]

  return get_combo_caption_for_pair(first, second)
end

get_combo_caption_for_pair = function(first, second)
  if not first or not second then
    return "No combo yet"
  end

  if first == second then
    return "Pure " .. element_name(first) .. ": stronger " .. string.lower(element_name(first)) .. " effects"
  end

  local key = first < second and (first .. "+" .. second) or (second .. "+" .. first)
  local combos = {
    ["electric+fire"] = "Stormfire: arcs can add burn damage",
    ["electric+explosive"] = "Shockburst: explosive splashes arc to one target",
    ["explosive+fire"] = "Incendiary burst: explosive splashes add fire damage"
  }

  return combos[key] or (element_name(first) .. " + " .. element_name(second))
end

local function add_base_section(parent, state)
  local section = add_section(parent, nil, true)
  local available = get_available_skill_points(state)

  for _, upgrade in ipairs(BASE_UPGRADES) do
    local rank = get_base_rank(state, upgrade.id)
    add_allocation_row(
      section,
      upgrade.sprite,
      upgrade.name .. "  Rank " .. tostring(rank),
      upgrade.value,
      "+",
      {
        turret_xp_action = "allocate-base",
        upgrade = upgrade.id
      },
      available >= 1
    )
  end
end

local function add_element_choices(section, state, slot)
  local evolution = ensure_evolution_state(state)
  if evolution.elements[slot] then
    add_element_mastery_panel(section, state, evolution.elements[slot])
    return
  end

  if evolution.element_project then
    add_project_panel(section, state)
    return
  end

  for _, element in ipairs(ELEMENTS) do
    local detail = element.description .. "\n" .. make_requirement_summary(get_element_requirements(element, 1))
    if slot == 2 and evolution.elements[1] then
      detail = detail .. "\nCombo: " .. get_combo_caption_for_pair(evolution.elements[1], element.id)
    end
    add_row(
      section,
      element.sprite,
      element.name,
      detail,
      "Start",
      {
        turret_xp_action = "start-element",
        element = element.id,
        slot = slot
      },
      true
    )
  end
end

local function add_first_element_section(parent, state)
  local unlocked = has_level(state, GATES.first_element)
  local section = add_section(parent, nil, unlocked, GATES.first_element)
  if unlocked then
    add_element_choices(section, state, 1)
  end
end

local function add_specialization_section(parent, state)
  local unlocked = has_level(state, GATES.specialization)
  local section = add_section(parent, nil, unlocked, GATES.specialization)
  if not unlocked then
    return
  end

  local evolution = ensure_evolution_state(state)
  if evolution.specialization then
    local specialization = SPECIALIZATION_BY_ID[evolution.specialization]
    add_row(section, specialization.sprite, "Selected: " .. specialization.name, specialization.description, "Active")
    return
  end

  for _, specialization in ipairs(SPECIALIZATIONS) do
    add_row(
      section,
      specialization.sprite,
      specialization.name,
      specialization.description,
      "Pick",
      {
        turret_xp_action = "choose-specialization",
        specialization = specialization.id
      },
      true
    )
  end
end

local function add_augments_section(parent, state)
  local unlocked = has_level(state, GATES.augments)
  local section = add_section(parent, nil, unlocked, GATES.augments)
  if not unlocked then
    return
  end

  local available = get_available_augment_points(state)
  local total = get_total_augment_points(state)
  local info = section.add({
    type = "label",
    caption = "Augment points: " .. tostring(available) .. " / " .. tostring(total) .. " (+1 every 10 levels)",
    style = "caption_label"
  })
  set_style(info, "font_color", COLOR.muted)
  set_style(info, "horizontal_align", "center")
  set_style(info, "horizontally_stretchable", true)

  for _, augment in ipairs(AUGMENTS) do
    local rank = get_augment_rank(state, augment.id)
    local cost = 1
    add_allocation_row(
      section,
      augment.sprite,
      augment.name .. "  Rank " .. tostring(rank),
      tostring(cost) .. " AP",
      "+",
      {
        turret_xp_action = "allocate-augment",
        augment = augment.id
      },
      available >= cost
    )
  end
end

local function add_second_element_section(parent, state)
  local unlocked = has_level(state, GATES.second_element)
  local section = add_section(parent, nil, unlocked, GATES.second_element)
  if not unlocked then
    return
  end

  local evolution = ensure_evolution_state(state)
  if not evolution.elements[1] then
    local label = section.add({
      type = "label",
      caption = "Unlock the first element before starting the second.",
      style = "caption_label"
    })
    set_style(label, "font_color", COLOR.muted)
    return
  end

  add_element_choices(section, state, 2)

  local combo = section.add({
    type = "label",
    name = GUI.active_combo,
    caption = "Combo: " .. get_combo_caption(state),
    style = "caption_label"
  })
  set_style(combo, "font", "default-bold")
  set_style(combo, "top_margin", 4)
end

local function update_evolution_panel(panel, state)
  local evolution_panel = find_gui_element(panel, GUI.evolution)
  if not evolution_panel then
    return
  end

  evolution_panel.clear()

  if not state then
    local label = evolution_panel.add({
      type = "label",
      caption = { "turret-xp.evolution-needs-core" },
      style = "caption_label"
    })
    set_style(label, "font_color", COLOR.muted)
    set_style(label, "single_line", false)
    return
  end

  ensure_evolution_state(state)
  add_header(evolution_panel, "Evolution", state)
  feeder.add_status(evolution_panel, state)

  add_base_section(evolution_panel, state)
  add_first_element_section(evolution_panel, state)
  add_specialization_section(evolution_panel, state)
  add_augments_section(evolution_panel, state)
  add_second_element_section(evolution_panel, state)
end

local function update_turret_gui(player, entity)
  local panel = get_gui_panel(player)
  if not panel then
    return false
  end

  local state = get_turret_state(entity)
  local progression = state and sync_turret_progression(state) or nil
  local required = progression and progression.required or 1
  local progress = progression and required > 0 and math.min(1, progression.xp / required) or 0
  local ammo_name, ammo_count, ammo_quality = get_loaded_ammo(entity)
  local quality_name = get_entity_quality_name(entity)
  local max_health = safe_read(entity, "max_health") or get_max_health_for_quality(entity, quality_name)
  local health = safe_read(entity, "health") or max_health

  update_core_panel(panel, player, entity, state)

  if state then
    set_gui_caption(panel, GUI.level, { "turret-xp.level", progression.level })
    set_gui_caption(panel, GUI.xp, { "turret-xp.xp-progress", format_number(progression.xp, 0), format_number(required, 0) })
  else
    set_gui_caption(panel, GUI.level, { "turret-xp.no-core-level" })
    set_gui_caption(panel, GUI.xp, { "turret-xp.no-core-xp" })
  end
  set_gui_progress(panel, GUI.xp_bar, progress)
  set_gui_caption(panel, GUI.xp_percent, state and { "turret-xp.progress-percent", format_number(progress * 100, 0) } or "")

  local health_tooltip = make_quality_tooltip(function(quality)
    return format_number(get_max_health_for_quality(entity, quality.name), 0)
  end)
  set_gui_caption(
    panel,
    GUI.hp,
    with_quality_marker(string.format("%s / %s", format_number(health, 0), format_number(max_health, 0)), health_tooltip),
    health_tooltip
  )

  set_gui_caption(panel, GUI.shooting_speed, format_shots_per_second(entity, ammo_name), { "turret-xp.shooting-speed-tooltip" })

  local range_tooltip = make_quality_tooltip(function(quality)
    return format_range_for_quality(entity, quality.name)
  end)
  set_gui_caption(panel, GUI.range, with_quality_marker(format_range(entity), range_tooltip), range_tooltip)

  update_ammo_row(panel, ammo_name, ammo_count, ammo_quality)

  if ammo_name then
    set_gui_caption(panel, GUI.damage, { "turret-xp.damage-value", format_damage_per_shot(entity, ammo_name) }, { "turret-xp.damage-tooltip" })
    set_gui_caption(panel, GUI.dps, format_estimated_dps(entity, ammo_name), { "turret-xp.dps-tooltip" })
  else
    set_gui_caption(panel, GUI.damage, { "turret-xp.damage-unknown" }, nil)
    set_gui_caption(panel, GUI.dps, "-", nil)
  end

  set_gui_caption(panel, GUI.kills, state and format_number(state.kills, 0) or "-")
  set_gui_caption(panel, GUI.damage_dealt, state and format_number(state.damage, 0) or "-")
  update_evolution_panel(panel, state)

  return true
end

local function get_open_turret_state(player)
  local entity = get_remembered_turret(player)
  if not entity or player.opened ~= entity then
    return nil, nil
  end

  return entity, get_turret_state(entity)
end

local function refresh_open_turret(player, entity)
  if entity and entity.valid then
    update_turret_gui(player, entity)
  end
end

local function sanitize_core_name(name)
  name = tostring(name or "")
  name = name:gsub("[%c\r\n\t]", " ")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  if #name > 48 then
    name = string.sub(name, 1, 48)
  end
  return name
end

local function install_core(player)
  local entity = get_remembered_turret(player)
  if not entity or player.opened ~= entity then
    return
  end

  if get_turret_state(entity) then
    refresh_open_turret(player, entity)
    return
  end

  local stack = find_carried_chip_stack(player)
  if not stack then
    player.print({ "turret-xp.no-core-to-install" })
    refresh_open_turret(player, entity)
    return
  end

  local profile = read_profile_from_chip_stack(stack) or create_blank_profile()
  if not remove_one_chip_stack(stack) then
    refresh_open_turret(player, entity)
    return
  end

  local installed = install_profile_on_turret(entity, profile)
  if not installed then
    insert_chip_item(player, profile)
  else
    local new_entity = ensure_specialized_turret_body(entity, installed)
    if new_entity and new_entity ~= entity then
      player.opened = new_entity
      remember_open_turret(player, new_entity)
      build_turret_gui(player, new_entity)
      return
    end
  end

  refresh_open_turret(player, entity)
end

local function extract_core(player)
  local entity, state = get_open_turret_state(player)
  if not state then
    return
  end

  local stack = make_chip_item_stack(state)
  local ok, can_insert = pcall(function()
    return player.can_insert(stack)
  end)

  if not ok or not can_insert then
    player.print({ "turret-xp.no-room-for-core" })
    refresh_open_turret(player, entity)
    return
  end

  local profile = detach_profile_from_turret(entity)
  if not profile then
    refresh_open_turret(player, entity)
    return
  end

  if not insert_chip_item(player, profile) then
    install_profile_on_turret(entity, profile)
    player.print({ "turret-xp.no-room-for-core" })
    refresh_open_turret(player, entity)
    return
  end

  local new_entity = swap_turret_body(entity, BASE_TURRET_NAME)
  if new_entity and new_entity ~= entity then
    player.opened = new_entity
    remember_open_turret(player, new_entity)
    build_turret_gui(player, new_entity)
    return
  end

  refresh_open_turret(player, new_entity or entity)
end

local function dev_create_core(player)
  local profile = create_blank_profile()
  if not insert_chip_item(player, profile) then
    local entity = get_remembered_turret(player) or player.character
    if entity and entity.valid then
      spill_chip_item(entity, profile)
    end
  end

  local entity = get_remembered_turret(player)
  if entity then
    refresh_open_turret(player, entity)
  end
end

local function update_core_name_from_textfield(player, element)
  if not element or not element.valid or element.name ~= GUI.core_name then
    return
  end

  local entity, state = get_open_turret_state(player)
  if not state then
    return
  end

  state.custom_name = sanitize_core_name(element.text)
  if state.custom_name ~= element.text then
    element.text = state.custom_name
  end
  update_name_render(entity, state)
end

local function set_core_label_visibility(player, visible)
  local entity, state = get_open_turret_state(player)
  if not state then
    return
  end

  state.show_name_label = visible == true
  update_name_render(entity, state)
  refresh_open_turret(player, entity)
end

local function allocate_base_upgrade(player, upgrade_id)
  if not BASE_UPGRADE_BY_ID[upgrade_id] then
    return
  end

  local entity, state = get_open_turret_state(player)
  if not state then
    return
  end

  if get_available_skill_points(state) < 1 then
    refresh_open_turret(player, entity)
    return
  end

  local evolution = ensure_evolution_state(state)
  evolution.base[upgrade_id] = (evolution.base[upgrade_id] or 0) + 1
  sync_turret_progression(state)
  refresh_open_turret(player, entity)
end

local function choose_specialization(player, specialization_id)
  if not SPECIALIZATION_BY_ID[specialization_id] then
    return
  end

  local entity, state = get_open_turret_state(player)
  if not state then
    return
  end

  if not has_level(state, GATES.specialization) then
    refresh_open_turret(player, entity)
    return
  end

  local evolution = ensure_evolution_state(state)
  if evolution.specialization then
    refresh_open_turret(player, entity)
    return
  end

  evolution.specialization = specialization_id
  local new_entity = ensure_specialized_turret_body(entity, state)
  if new_entity and new_entity ~= entity then
    player.opened = new_entity
    remember_open_turret(player, new_entity)
    build_turret_gui(player, new_entity)
    return
  end
  refresh_open_turret(player, entity)
end

local function allocate_augment(player, augment_id)
  if not AUGMENT_BY_ID[augment_id] then
    return
  end

  local entity, state = get_open_turret_state(player)
  if not state then
    return
  end

  if not has_level(state, GATES.augments) then
    refresh_open_turret(player, entity)
    return
  end

  local cost = 1
  if get_available_augment_points(state) < cost then
    refresh_open_turret(player, entity)
    return
  end

  local evolution = ensure_evolution_state(state)
  evolution.augments[augment_id] = (evolution.augments[augment_id] or 0) + 1
  refresh_open_turret(player, entity)
end

local function start_element_project(player, slot, element_id)
  slot = math.floor(tonumber(slot) or 0)
  if (slot ~= 1 and slot ~= 2) or not ELEMENT_BY_ID[element_id] then
    return
  end

  local entity, state = get_open_turret_state(player)
  if not state then
    return
  end

  if slot == 1 and not has_level(state, GATES.first_element) then
    refresh_open_turret(player, entity)
    return
  end

  if slot == 2 and (not has_level(state, GATES.second_element) or not ensure_evolution_state(state).elements[1]) then
    refresh_open_turret(player, entity)
    return
  end

  local evolution = ensure_evolution_state(state)
  if evolution.elements[slot] or evolution.element_project then
    refresh_open_turret(player, entity)
    return
  end

  local element = ELEMENT_BY_ID[element_id]
  evolution.element_project = {
    slot = slot,
    element = element_id,
    requirements = get_element_requirements(element, 1),
    delivered = {}
  }
  ensure_evolution_state(state)
  refresh_open_turret(player, entity)
end

local function auto_feed_element_project(state)
  local evolution = ensure_evolution_state(state)
  local project = evolution.element_project
  if not project then
    return false
  end

  local changed = false
  for _, requirement in ipairs(project.requirements or {}) do
    local delivered = project.delivered[requirement.name] or 0
    local needed = math.max(0, requirement.count - delivered)
    local removed = feeder.remove_items(state, requirement.name, math.min(needed, FEEDER_CONSUME_LIMIT))
    if removed > 0 then
      project.delivered[requirement.name] = delivered + removed
      changed = true
    end
  end

  if finish_element_project(state) then
    changed = true
  end

  return changed
end

local function auto_feed_element_mastery(state)
  local evolution = ensure_evolution_state(state)
  local changed = false

  for _, element in ipairs(ELEMENTS) do
    local mastery = evolution.element_mastery[element.id]
    if mastery and (mastery.rank or 0) > 0 then
      local required = get_element_requirement_count(element, mastery.rank + 1)
      local needed = math.max(0, required - (mastery.delivered or 0))
      local removed = feeder.remove_items(state, element.resource, math.min(needed, FEEDER_CONSUME_LIMIT))
      if removed > 0 then
        mastery.delivered = (mastery.delivered or 0) + removed
        advance_element_mastery(state, element.id)
        changed = true
      end
    end
  end

  return changed
end

local function auto_feed_open_turret(state)
  if not state then
    return false
  end

  local changed_project = auto_feed_element_project(state)
  local changed_mastery = auto_feed_element_mastery(state)
  return changed_project or changed_mastery
end

local function dev_complete_project(player)
  local entity, state = get_open_turret_state(player)
  if not state then
    return
  end

  local evolution = ensure_evolution_state(state)
  local project = evolution.element_project
  if project then
    for _, requirement in ipairs(project.requirements or {}) do
      project.delivered[requirement.name] = requirement.count
    end
    finish_element_project(state)
  else
    for _, element_id in ipairs(evolution.elements or {}) do
      local element = ELEMENT_BY_ID[element_id]
      local mastery = element and evolution.element_mastery[element_id] or nil
      if mastery and (mastery.rank or 0) > 0 then
        mastery.delivered = get_element_requirement_count(element, mastery.rank + 1)
        advance_element_mastery(state, element_id)
        break
      end
    end
  end

  refresh_open_turret(player, entity)
end

local function add_dev_levels(player, levels)
  local entity, state = get_open_turret_state(player)
  if not state then
    return
  end

  levels = math.max(1, math.floor(tonumber(levels) or 1))
  sync_turret_progression(state)
  local target_level = (state.level or 1) + levels
  local needed_total = 0
  for level = 1, target_level - 1 do
    needed_total = needed_total + xp_required(level)
  end

  state.dev_xp = (state.dev_xp or 0) + math.max(0, needed_total - (state.total_xp or 0))
  sync_turret_progression(state)
  refresh_open_turret(player, entity)
end

local function apply_passive_evolution_effects()
  ensure_storage()

  for _, state in pairs(storage.turret_xp.chips) do
    ensure_evolution_state(state)
    local entity = state.entity
    if is_gun_turret(entity) then
      feeder.ensure(entity, state)
      auto_feed_open_turret(state)
      local repair_rank = get_base_rank(state, "repair")
      local repair_per_second = 0.2 * repair_rank
      if repair_per_second > 0 then
        local max_health = safe_read(entity, "max_health")
        local health = safe_read(entity, "health")
        if max_health and health and health > 0 and health < max_health then
          entity.health = math.min(max_health, health + (repair_per_second * (REFRESH_TICKS / 60)))
        end
      end
      update_name_render(entity, state)
    elseif entity and not entity.valid then
      destroy_name_render(state)
      state.entity = nil
    end
  end
end

local function chance_roll(chance)
  chance = math.max(0, math.min(0.95, chance or 0))
  return chance > 0 and math.random() < chance
end

local function get_distance(a, b)
  if not a or not b then
    return 0
  end

  local dx = (a.x or a[1] or 0) - (b.x or b[1] or 0)
  local dy = (a.y or a[2] or 0) - (b.y or b[2] or 0)
  return math.sqrt((dx * dx) + (dy * dy))
end

local function apply_runtime_damage(target, amount, force, damage_type)
  if not target or not target.valid or amount <= 0 then
    return false
  end

  local ok = pcall(function()
    target.damage(amount, force, damage_type or "physical")
  end)

  return ok
end

local function heal_turret(entity, amount)
  if not is_gun_turret(entity) or amount <= 0 then
    return
  end

  local max_health = safe_read(entity, "max_health")
  local health = safe_read(entity, "health")
  if max_health and health and health > 0 and health < max_health then
    entity.health = math.min(max_health, health + amount)
  end
end

local function find_nearby_enemy(surface, position, force, radius, exclude)
  if not surface or not position then
    return nil
  end

  local entities = surface.find_entities_filtered({
    area = {
      { position.x - radius, position.y - radius },
      { position.x + radius, position.y + radius }
    }
  })

  for _, entity in pairs(entities) do
    if entity.valid
      and entity ~= exclude
      and safe_read(entity, "health")
      and entity.force ~= force
      and get_distance(position, entity.position) <= radius
    then
      return entity
    end
  end

  return nil
end

local function find_pierce_target(turret, target, force)
  if not is_gun_turret(turret) or not target or not target.valid then
    return nil
  end

  local tx = target.position.x - turret.position.x
  local ty = target.position.y - turret.position.y
  local length = math.sqrt((tx * tx) + (ty * ty))
  if length <= 0 then
    return nil
  end

  local nx = tx / length
  local ny = ty / length
  local probe = {
    x = target.position.x + (nx * 2.5),
    y = target.position.y + (ny * 2.5)
  }

  return find_nearby_enemy(target.surface, probe, force, 2.5, target)
end

local function draw_attack_line(surface, from, to, color, width, ttl)
  if not surface or not from or not to then
    return
  end

  pcall(function()
    rendering.draw_line({
      surface = surface,
      from = from,
      to = to,
      color = color,
      width = width or 2,
      time_to_live = ttl or 20,
      forces = nil,
      draw_on_ground = false
    })
  end)
end

local function draw_effect_sprite(surface, target, sprite, scale, ttl)
  if not surface or not target or not sprite then
    return
  end

  pcall(function()
    rendering.draw_sprite({
      surface = surface,
      sprite = sprite,
      target = target,
      x_scale = scale or 0.55,
      y_scale = scale or 0.55,
      time_to_live = ttl or 30,
      render_layer = "air-object"
    })
  end)
end

local function create_short_effect(surface, name, position)
  if not surface or not name or not position then
    return
  end

  pcall(function()
    surface.create_entity({
      name = name,
      position = position
    })
  end)
end

local function get_element_effect_multiplier(state, element_id)
  local rank = get_element_rank(state, element_id)
  if rank <= 0 then
    return 0
  end

  return 1 + ((rank - 1) * 0.18)
end

local function get_element_proc_chance(state, element_id)
  local rank = get_element_rank(state, element_id)
  if rank <= 0 then
    return 0
  end

  return math.min(0.60, 0.10 + (rank * 0.02))
end

local function get_active_elements(state)
  local evolution = ensure_evolution_state(state)
  local elements = {}
  for slot = 1, 2 do
    if evolution.elements[slot] then
      elements[#elements + 1] = evolution.elements[slot]
    end
  end
  return elements
end

local function has_element_pair(state, a, b)
  local elements = get_active_elements(state)
  if #elements < 2 then
    return false
  end

  return (elements[1] == a and elements[2] == b) or (elements[1] == b and elements[2] == a)
end

local function apply_evolution_damage_effects(event, turret, state, base_damage)
  if not event.entity or not event.entity.valid or base_damage <= 0 then
    return
  end

  local evolution = ensure_evolution_state(state)
  local force = turret.force
  local target = event.entity
  local upgrade_damage = 0

  local bonus_multiplier = 0

  local longshot_rank = get_augment_rank(state, "longshot")
  if longshot_rank > 0 then
    local range = get_range_for_quality(turret, get_entity_quality_name(turret)) or 0
    local distance = get_distance(turret.position, target.position)
    if range > 0 and distance >= range * 0.75 then
      bonus_multiplier = bonus_multiplier + (longshot_rank * 0.08)
    end
  end

  local bonus_damage = (base_damage * bonus_multiplier) + (get_base_rank(state, "damage") * 0.5)
  if bonus_damage > 0 and apply_runtime_damage(target, bonus_damage, force, "physical") then
    upgrade_damage = upgrade_damage + bonus_damage
    record_damage_contribution(event, turret, bonus_damage)
  end

  local crit_chance = 0.02 + (get_base_rank(state, "crit_chance") * 0.0025)
  if chance_roll(crit_chance) then
    local crit_damage = base_damage * (0.50 + (get_base_rank(state, "crit_damage") * 0.01))
    if apply_runtime_damage(target, crit_damage, force, "physical") then
      upgrade_damage = upgrade_damage + crit_damage
      record_damage_contribution(event, turret, crit_damage)
    end
  end

  if not target.valid then
    if upgrade_damage > 0 then
      state.damage = (state.damage or 0) + upgrade_damage
      sync_turret_progression(state)
      local siphon_rate = (get_base_rank(state, "siphon") * 0.004)
      heal_turret(turret, (base_damage + upgrade_damage) * siphon_rate)
    end
    return
  end

  local bounce_rank = get_augment_rank(state, "bounce")
  local bounce_chance = bounce_rank * 0.05
  if bounce_rank > 0 and chance_roll(bounce_chance) then
    local bounce_target = find_nearby_enemy(target.surface, target.position, force, 6, target)
    if bounce_target and apply_runtime_damage(bounce_target, base_damage * 0.35, force, "physical") then
      upgrade_damage = upgrade_damage + (base_damage * 0.35)
      draw_attack_line(target.surface, target.position, bounce_target.position, { 1, 0.85, 0.25 }, 2, 18)
    end
  end

  local pierce_rank = get_augment_rank(state, "piercing")
  if pierce_rank > 0 and chance_roll(pierce_rank * 0.05) then
    local pierce_target = find_pierce_target(turret, target, force)
    if pierce_target and apply_runtime_damage(pierce_target, base_damage * 0.50, force, "physical") then
      upgrade_damage = upgrade_damage + (base_damage * 0.50)
      draw_attack_line(target.surface, target.position, pierce_target.position, { 0.78, 0.92, 1 }, 2, 18)
    end
  end

  local fire_active = false
  local electric_active = false
  local explosive_active = false

  for _, element_id in ipairs(get_active_elements(state)) do
    if not target.valid then
      break
    end

    local element_multiplier = get_element_effect_multiplier(state, element_id)
    local element_proc_chance = get_element_proc_chance(state, element_id)

    if element_id == "fire" and chance_roll(element_proc_chance) then
      fire_active = true
      local amount = base_damage * 0.20 * element_multiplier
      if apply_runtime_damage(target, amount, force, "fire") then
        upgrade_damage = upgrade_damage + amount
        record_damage_contribution(event, turret, amount)
        draw_effect_sprite(target.surface, target, "virtual-signal/signal-fire", 0.45, 24)
      end
    elseif element_id == "electric" and chance_roll(element_proc_chance) then
      electric_active = true
      local arc_target = find_nearby_enemy(target.surface, target.position, force, 7, target)
      local amount = base_damage * 0.25 * element_multiplier
      if arc_target and apply_runtime_damage(arc_target, amount, force, "electric") then
        upgrade_damage = upgrade_damage + amount
        draw_attack_line(target.surface, target.position, arc_target.position, { 0.35, 0.75, 1 }, 2, 18)
        draw_effect_sprite(target.surface, arc_target, "virtual-signal/signal-lightning", 0.45, 24)
      end
    elseif element_id == "explosive" and chance_roll(element_proc_chance) then
      explosive_active = true
      local splashed = 0
      local splash_radius = 3 + math.min(3, get_element_rank(state, "explosive") * 0.15)
      local entities = target.surface.find_entities_filtered({
        area = {
          { target.position.x - splash_radius, target.position.y - splash_radius },
          { target.position.x + splash_radius, target.position.y + splash_radius }
        }
      })
      create_short_effect(target.surface, "explosion", target.position)
      draw_effect_sprite(target.surface, target, "virtual-signal/signal-explosion", 0.45, 24)
      for _, nearby in pairs(entities) do
        if splashed >= 4 then
          break
        end
        if nearby.valid and nearby ~= target and safe_read(nearby, "health") and nearby.force ~= force then
          local amount = base_damage * 0.20 * element_multiplier
          if apply_runtime_damage(nearby, amount, force, "explosion") then
            upgrade_damage = upgrade_damage + amount
            splashed = splashed + 1
          end
        end
      end
    end
  end

  if not target.valid then
    fire_active = false
    electric_active = false
    explosive_active = false
  end

  if fire_active and electric_active and has_element_pair(state, "fire", "electric") then
    local stormfire = base_damage * 0.15
    if apply_runtime_damage(target, stormfire, force, "fire") then
      upgrade_damage = upgrade_damage + stormfire
      record_damage_contribution(event, turret, stormfire)
      draw_effect_sprite(target.surface, target, "virtual-signal/signal-fire", 0.55, 30)
    end
  elseif fire_active and explosive_active and has_element_pair(state, "fire", "explosive") then
    local incendiary = base_damage * 0.20
    if apply_runtime_damage(target, incendiary, force, "fire") then
      upgrade_damage = upgrade_damage + incendiary
      record_damage_contribution(event, turret, incendiary)
      draw_effect_sprite(target.surface, target, "virtual-signal/signal-fire", 0.55, 30)
    end
  elseif electric_active and explosive_active and has_element_pair(state, "electric", "explosive") then
    local shockburst_target = find_nearby_enemy(target.surface, target.position, force, 8, target)
    if shockburst_target and apply_runtime_damage(shockburst_target, base_damage * 0.25, force, "electric") then
      upgrade_damage = upgrade_damage + (base_damage * 0.25)
      draw_attack_line(target.surface, target.position, shockburst_target.position, { 0.35, 0.75, 1 }, 2, 18)
    end
  end

  local siphon_rate = (get_base_rank(state, "siphon") * 0.004)
  if siphon_rate > 0 then
    heal_turret(turret, (base_damage + upgrade_damage) * siphon_rate)
  end

  if upgrade_damage > 0 then
    state.damage = (state.damage or 0) + upgrade_damage
    sync_turret_progression(state)
  end
end

local function make_gui_frame(player)
  local ok, frame = pcall(function()
    return player.gui.relative.add({
      type = "frame",
      name = GUI.panel,
      direction = "vertical",
      caption = { "turret-xp.panel-title" },
      anchor = {
        gui = defines.relative_gui_type.turret_gui,
        position = defines.relative_gui_position.right
      }
    })
  end)

  if ok and frame then
    return frame
  end

  return player.gui.left.add({
    type = "frame",
    name = GUI.panel,
    direction = "vertical",
    caption = { "turret-xp.panel-title" }
  })
end

build_turret_gui = function(player, entity)
  destroy_gui(player)

  if not is_gun_turret(entity) then
    forget_open_turret(player)
    return
  end

  remember_open_turret(player, entity)

  local frame = make_gui_frame(player)
  set_style(frame, "minimal_width", 390)
  set_style(frame, "maximal_width", 440)

  local body = frame.add({
    type = "frame",
    direction = "vertical"
  })
  set_element_style(body, "inside_shallow_frame_with_padding")
  set_style(body, "horizontally_stretchable", true)

  add_core_panel(body)
  add_xp_panel(body)
  add_dev_controls_panel(body)

  local current = make_stats_table(body)
  set_style(current, "top_margin", 8)
  add_stat_row(current, { "turret-xp.hp" }, GUI.hp)
  add_stat_row(current, { "turret-xp.shooting-speed" }, GUI.shooting_speed, {
    info_tooltip = { "turret-xp.shooting-speed-tooltip" }
  })
  add_stat_row(current, { "turret-xp.range" }, GUI.range, {
    info_tooltip = { "turret-xp.range-tooltip" }
  })
  add_stat_row(current, { "turret-xp.damage" }, GUI.damage, {
    info_tooltip = { "turret-xp.damage-tooltip" }
  })
  add_stat_row(current, { "turret-xp.dps" }, GUI.dps, {
    info_tooltip = { "turret-xp.dps-tooltip" }
  })
  add_stat_row(current, { "turret-xp.kills" }, GUI.kills)
  add_stat_row(current, { "turret-xp.damage-dealt" }, GUI.damage_dealt)

  add_evolution_panel(frame)

  update_turret_gui(player, entity)
end

local function refresh_player_gui(player)
  local entity = get_remembered_turret(player)
  if not entity then
    destroy_gui(player)
    forget_open_turret(player)
    return
  end

  if player.opened ~= entity then
    destroy_gui(player)
    forget_open_turret(player)
    return
  end

  local state = get_turret_state(entity)
  if state then
    auto_feed_open_turret(state)
    local new_entity = ensure_specialized_turret_body(entity, state)
    if new_entity and new_entity ~= entity then
      player.opened = new_entity
      remember_open_turret(player, new_entity)
      build_turret_gui(player, new_entity)
      return
    end
  end

  if not update_turret_gui(player, entity) then
    build_turret_gui(player, entity)
  end
end

local function on_gui_opened(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  if is_gun_turret(event.entity) then
    build_turret_gui(player, event.entity)
  else
    destroy_gui(player)
    forget_open_turret(player)
  end
end

local function on_gui_closed(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  destroy_gui(player)
  forget_open_turret(player)
end

local function on_gui_click(event)
  local element = event.element
  if not element or not element.valid then
    return
  end

  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  local tags = element.tags or {}
  local action = tags.turret_xp_action
  if action == "install-core" then
    install_core(player)
  elseif action == "extract-core" then
    extract_core(player)
  elseif action == "dev-create-core" then
    dev_create_core(player)
  elseif action == "allocate-base" then
    allocate_base_upgrade(player, tags.upgrade)
  elseif action == "choose-specialization" then
    choose_specialization(player, tags.specialization)
  elseif action == "allocate-augment" then
    allocate_augment(player, tags.augment)
  elseif action == "start-element" then
    start_element_project(player, tags.slot, tags.element)
  elseif action == "dev-complete-project" then
    dev_complete_project(player)
  elseif action == "dev-level" then
    add_dev_levels(player, tags.levels)
  end
end

local function on_gui_checked_state_changed(event)
  local element = event.element
  if not element or not element.valid then
    return
  end

  local tags = element.tags or {}
  if tags.turret_xp_action ~= "toggle-core-label" then
    return
  end

  local player = game.get_player(event.player_index)
  if player then
    set_core_label_visibility(player, element.state == true)
  end
end

local function on_gui_text_changed(event)
  local element = event.element
  if not element or not element.valid then
    return
  end

  local player = game.get_player(event.player_index)
  if player then
    update_core_name_from_textfield(player, element)
  end
end

local function on_runtime_mod_setting_changed(event)
  if not event.setting or string.sub(event.setting, 1, #MOD_PREFIX) ~= MOD_PREFIX then
    return
  end

  ensure_storage()

  for _, state in pairs(storage.turret_xp.chips) do
    ensure_evolution_state(state)
    sync_turret_progression(state)
  end

  for _, player in pairs(game.players) do
    if player and player.valid and player.connected then
      refresh_player_gui(player)
    end
  end
end

local function on_entity_damaged(event)
  local cause = event.cause
  local damage = event.final_damage_amount or 0
  if damage <= 0 or not event.entity or not event.entity.valid then
    return
  end

  local damage_force = event.force or (cause and cause.valid and cause.force)
  if damage_force and event.entity.force == damage_force then
    return
  end

  record_damage_contribution(event, cause, damage)

  if is_gun_turret(event.entity) then
    get_turret_host(event.entity, false)
  end

  if is_gun_turret(cause) then
    local state = get_turret_state(cause)
    if state then
      state.damage = state.damage + damage
      apply_evolution_damage_effects(event, cause, state, damage)
      sync_turret_progression(state)
      update_name_render(cause, state)
    end
  end
end

local function on_entity_died(event)
  if is_gun_turret(event.entity) then
    local profile = get_turret_state(event.entity)
    destroy_name_render(profile)
    feeder.destroy(profile, event.entity.position, true)
    remove_turret_state(event.entity, true)
  elseif event.entity and event.entity.valid and event.entity.name == FEEDER_NAME then
    ensure_storage()
    local chip_id = event.entity.unit_number and storage.turret_xp.feeders[event.entity.unit_number] or nil
    if chip_id and storage.turret_xp.chips[chip_id] then
      storage.turret_xp.chips[chip_id].feeder = nil
    end
    if event.entity.unit_number then
      storage.turret_xp.feeders[event.entity.unit_number] = nil
    end
  end

  local cause = event.cause
  local damage_force = event.force or (cause and cause.valid and cause.force)
  if damage_force and event.entity and event.entity.valid and event.entity.force == damage_force then
    return
  end

  if is_gun_turret(cause) then
    local state = get_turret_state(cause)
    if state then
      state.kills = state.kills + 1
      sync_turret_progression(state)
      update_name_render(cause, state)
    end
  end

  award_kill_credit(event.entity, cause)
end

local function on_turret_removed(event)
  local entity = event.entity
  if not is_gun_turret(entity) then
    return
  end

  local player = event.player_index and game.get_player(event.player_index) or nil
  local profile = detach_profile_from_turret(entity)
  if profile then
    local returned = player and insert_chip_item(player, profile)
    if not returned then
      spill_chip_item(entity, profile)
    end
  end

  remove_turret_state(entity, false)
end

local function on_refresh_tick()
  ensure_storage()
  cleanup_target_damage()
  apply_passive_evolution_effects()

  for player_index in pairs(storage.turret_xp.players) do
    local player = game.get_player(player_index)
    if player and player.valid and player.connected then
      refresh_player_gui(player)
    else
      storage.turret_xp.players[player_index] = nil
    end
  end
end

script.on_init(function()
  ensure_storage()
  unlock_core_recipes_for_existing_tech()
end)
script.on_configuration_changed(function()
  ensure_storage()
  unlock_core_recipes_for_existing_tech()
  storage.turret_xp.targets = {}
  for _, state in pairs(storage.turret_xp.chips) do
    ensure_evolution_state(state)
    sync_turret_progression(state)
    destroy_name_render(state)
    if is_gun_turret(state.entity) then
      update_name_render(state.entity, state)
    end
  end
  for _, player in pairs(game.players) do
    destroy_gui(player)
    forget_open_turret(player)
  end
end)

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
script.on_event(defines.events.on_entity_damaged, on_entity_damaged)
script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.on_pre_player_mined_item, on_turret_removed)
script.on_event(defines.events.on_robot_pre_mined, on_turret_removed)
script.on_nth_tick(REFRESH_TICKS, on_refresh_tick)

commands.add_command("turret-xp", { "turret-xp.command-help" }, function(command)
  local player = command.player_index and game.get_player(command.player_index)
  if not player then
    return
  end

  if not is_gun_turret(player.selected) then
    player.print({ "turret-xp.select-gun-turret" })
    return
  end

  player.opened = player.selected
  build_turret_gui(player, player.selected)
end)
