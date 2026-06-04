local MOD_PREFIX = "turret-xp-"
local GUI = {
  panel = MOD_PREFIX .. "panel",
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
  skill_points = MOD_PREFIX .. "skill-points"
}

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

local SKILLS = {
  {
    id = "ballistics",
    sprite = "item/firearm-magazine",
    max_rank = 3,
    short_name = { "turret-xp.skill-ballistics-short" },
    name = { "turret-xp.skill-ballistics" },
    description = { "turret-xp.skill-ballistics-description" },
    effect = { "turret-xp.skill-ballistics-effect" }
  },
  {
    id = "kill_chain",
    sprite = "item/piercing-rounds-magazine",
    max_rank = 3,
    short_name = { "turret-xp.skill-kill-chain-short" },
    name = { "turret-xp.skill-kill-chain" },
    description = { "turret-xp.skill-kill-chain-description" },
    effect = { "turret-xp.skill-kill-chain-effect" }
  },
  {
    id = "field_repairs",
    sprite = "item/repair-pack",
    max_rank = 3,
    short_name = { "turret-xp.skill-field-repairs-short" },
    name = { "turret-xp.skill-field-repairs" },
    description = { "turret-xp.skill-field-repairs-description" },
    effect = { "turret-xp.skill-field-repairs-effect" }
  },
  {
    id = "targeting_data",
    sprite = "entity/radar",
    max_rank = 2,
    short_name = { "turret-xp.skill-targeting-data-short" },
    name = { "turret-xp.skill-targeting-data" },
    description = { "turret-xp.skill-targeting-data-description" },
    effect = { "turret-xp.skill-targeting-data-effect" }
  }
}

local SKILL_BY_ID = {}
for _, skill in ipairs(SKILLS) do
  SKILL_BY_ID[skill.id] = skill
end

local COLOR = {
  caption = { 0.62, 0.62, 0.62 },
  muted = { 0.74, 0.74, 0.74 },
  bonus = { 0.58, 0.82, 0.38 }
}

local REFRESH_TICKS = 60
local TARGET_DAMAGE_TTL = 60 * 60 * 5

local function ensure_storage()
  storage.turret_xp = storage.turret_xp or {}
  storage.turret_xp.turrets = storage.turret_xp.turrets or {}
  storage.turret_xp.players = storage.turret_xp.players or {}
  storage.turret_xp.targets = storage.turret_xp.targets or {}
end

local function is_gun_turret(entity)
  return entity and entity.valid and entity.name == "gun-turret"
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

local function ensure_skill_state(state)
  state.skills = state.skills or {}

  for _, skill in ipairs(SKILLS) do
    local rank = state.skills[skill.id]
    if type(rank) ~= "number" then
      rank = 0
    end
    state.skills[skill.id] = math.max(0, math.min(skill.max_rank, math.floor(rank)))
  end
end

local function get_skill_rank(state, skill_id)
  if not state then
    return 0
  end

  ensure_skill_state(state)
  return state.skills[skill_id] or 0
end

local function get_spent_skill_points(state)
  if not state then
    return 0
  end

  ensure_skill_state(state)
  local spent = 0
  for _, skill in ipairs(SKILLS) do
    spent = spent + (state.skills[skill.id] or 0)
  end

  return spent
end

local function get_available_skill_points(state)
  if not state then
    return 0
  end

  return math.max(0, (state.level or 1) - 1 - get_spent_skill_points(state))
end

local function xp_required(level)
  local xp_settings = get_xp_settings()
  return math.max(1, math.floor((xp_settings.level_base_xp * (xp_settings.level_growth ^ (level - 1))) + 0.5))
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
  ensure_skill_state(state)

  local xp_settings = get_xp_settings()
  local damage_multiplier = 1 + (get_skill_rank(state, "ballistics") * 0.10)
  local kill_credit_multiplier = 1 + (get_skill_rank(state, "kill_chain") * 0.10)
  local global_multiplier = 1 + (get_skill_rank(state, "targeting_data") * 0.05)
  local total_xp = (((state.damage or 0) * xp_settings.xp_per_damage * damage_multiplier)
    + ((state.kill_credit or 0) * xp_settings.xp_per_kill_credit * kill_credit_multiplier))
    * global_multiplier
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

local function get_turret_state(entity)
  ensure_storage()
  local key = turret_key(entity)
  local state = storage.turret_xp.turrets[key]

  if not state then
    state = {
      xp = 0,
      total_xp = 0,
      level = 1,
      kills = 0,
      kill_credit = 0,
      damage = 0,
      skills = {}
    }
    storage.turret_xp.turrets[key] = state
  end

  state.entity = entity
  state.xp = state.xp or 0
  state.total_xp = state.total_xp or 0
  state.level = math.max(1, state.level or 1)
  state.kills = state.kills or 0
  state.kill_credit = state.kill_credit or state.kills or 0
  state.damage = state.damage or 0
  ensure_skill_state(state)
  sync_turret_progression(state)
  return state
end

local function remove_turret_state(entity)
  if not is_gun_turret(entity) then
    return
  end

  ensure_storage()
  storage.turret_xp.turrets[turret_key(entity)] = nil
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
  ensure_storage()
  storage.turret_xp.players[player.index] = {
    entity = entity,
    unit_number = entity.unit_number
  }
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

local function safe_read(object, property)
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
  local create = is_gun_turret(turret)
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
      entity = turret
    }
    entry.turrets[key] = contributor
  end

  contributor.damage = (contributor.damage or 0) + damage
  contributor.entity = turret
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

        if is_gun_turret(turret) then
          state = get_turret_state(turret)
        else
          state = storage.turret_xp.turrets[contributor_key]
        end

        if state then
          state.kill_credit = (state.kill_credit or state.kills or 0) + credit
          sync_turret_progression(state)
        end
      end
    end

    storage.turret_xp.targets[target_key] = nil
    return
  end

  if is_gun_turret(killing_turret) then
    local state = get_turret_state(killing_turret)
    state.kill_credit = (state.kill_credit or state.kills or 0) + 1
    sync_turret_progression(state)
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

local function add_entity_icon(parent, entity)
  local quality_name = get_entity_quality_name(entity)

  local ok, icon = pcall(function()
    return parent.add({
      type = "sprite-button",
      sprite = "entity/" .. entity.name,
      quality = quality_name,
      elem_tooltip = {
        type = "entity-with-quality",
        name = entity.name,
        quality = quality_name
      }
    })
  end)

  if not ok or not icon then
    ok, icon = pcall(function()
      return parent.add({
        type = "sprite-button",
        sprite = "entity/" .. entity.name,
        quality = quality_name,
        tooltip = { "turret-xp.entity-tooltip" }
      })
    end)
  end

  if not ok or not icon then
    icon = parent.add({
      type = "sprite-button",
      sprite = "entity/" .. entity.name,
      tooltip = { "turret-xp.entity-tooltip" }
    })
  end

  set_element_style(icon, "slot_button")
  set_style(icon, "size", 40)
  return icon
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
    value = 0
  })
  set_style(bar, "horizontally_stretchable", true)
  set_style(bar, "height", 20)
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

local function skill_button_name(skill_id)
  return MOD_PREFIX .. "skill-button-" .. skill_id
end

local function skill_rank_name(skill_id)
  return MOD_PREFIX .. "skill-rank-" .. skill_id
end

local function make_skill_tooltip(skill, state)
  local rank = get_skill_rank(state, skill.id)
  local available = get_available_skill_points(state)
  local footer = { "turret-xp.skill-click-unavailable" }

  if rank >= skill.max_rank then
    footer = { "turret-xp.skill-maxed" }
  elseif available > 0 then
    footer = { "turret-xp.skill-click-available" }
  end

  return {
    "",
    skill.name,
    "\n",
    skill.description,
    "\n",
    skill.effect,
    "\n",
    { "turret-xp.skill-rank", rank, skill.max_rank },
    "\n",
    footer
  }
end

local function add_skill_panel(parent)
  local skill_panel = parent.add({
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  })
  set_style(skill_panel, "top_margin", 6)
  set_style(skill_panel, "horizontally_stretchable", true)

  local header = skill_panel.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(header, "horizontally_stretchable", true)
  set_style(header, "vertical_align", "center")

  local title = header.add({
    type = "label",
    caption = { "turret-xp.skill-tree" },
    style = "heading_2_label"
  })
  set_style(title, "font", "default-bold")

  header.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })

  local points = header.add({
    type = "label",
    name = GUI.skill_points,
    caption = { "turret-xp.skill-points", 0 },
    style = "caption_label"
  })
  set_style(points, "font_color", COLOR.muted)

  local table_element = skill_panel.add({
    type = "table",
    column_count = #SKILLS
  })
  set_style(table_element, "top_margin", 8)
  set_style(table_element, "horizontally_stretchable", true)
  set_style(table_element, "horizontal_spacing", 10)

  for _, skill in ipairs(SKILLS) do
    local node = table_element.add({
      type = "flow",
      direction = "vertical"
    })
    set_style(node, "horizontal_align", "center")
    set_style(node, "width", 82)

    local button = node.add({
      type = "sprite-button",
      name = skill_button_name(skill.id),
      sprite = skill.sprite,
      style = "flib_slot_button_blue",
      tags = {
        turret_xp_action = "allocate-skill",
        skill = skill.id
      },
      tooltip = skill.description
    })
    set_style(button, "size", 42)

    local label = node.add({
      type = "label",
      caption = skill.short_name,
      style = "caption_label"
    })
    set_style(label, "top_margin", 3)
    set_style(label, "horizontal_align", "center")
    set_style(label, "single_line", true)

    local rank = node.add({
      type = "label",
      name = skill_rank_name(skill.id),
      caption = "0/" .. tostring(skill.max_rank),
      style = "caption_label"
    })
    set_style(rank, "font_color", COLOR.muted)
    set_style(rank, "horizontal_align", "center")
  end
end

local function update_skill_panel(panel, state)
  if not panel then
    return
  end

  local available = get_available_skill_points(state)
  set_gui_caption(panel, GUI.skill_points, { "turret-xp.skill-points", available })

  for _, skill in ipairs(SKILLS) do
    local rank = get_skill_rank(state, skill.id)
    local button = find_gui_element(panel, skill_button_name(skill.id))
    if button then
      button.tooltip = make_skill_tooltip(skill, state)
      button.enabled = rank < skill.max_rank

      if rank >= skill.max_rank then
        set_element_style(button, "flib_selected_slot_button_green")
      elseif rank > 0 then
        set_element_style(button, "flib_selected_slot_button_blue")
      elseif available > 0 then
        set_element_style(button, "flib_slot_button_blue")
      else
        set_element_style(button, "flib_slot_button_grey")
      end
    end

    set_gui_caption(panel, skill_rank_name(skill.id), tostring(rank) .. "/" .. tostring(skill.max_rank))
  end
end

local function update_turret_gui(player, entity)
  local panel = get_gui_panel(player)
  if not panel then
    return false
  end

  local state = get_turret_state(entity)
  local progression = sync_turret_progression(state)
  local required = progression.required
  local progress = required > 0 and math.min(1, progression.xp / required) or 0
  local ammo_name, ammo_count, ammo_quality = get_loaded_ammo(entity)
  local quality_name = get_entity_quality_name(entity)
  local max_health = safe_read(entity, "max_health") or get_max_health_for_quality(entity, quality_name)
  local health = safe_read(entity, "health") or max_health

  set_gui_caption(panel, GUI.level, { "turret-xp.level", progression.level })
  set_gui_caption(panel, GUI.xp, { "turret-xp.xp-progress", format_number(progression.xp, 0), format_number(required, 0) })
  set_gui_progress(panel, GUI.xp_bar, progress)
  set_gui_caption(panel, GUI.xp_percent, { "turret-xp.progress-percent", format_number(progress * 100, 0) })

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

  set_gui_caption(panel, GUI.kills, format_number(state.kills, 0))
  set_gui_caption(panel, GUI.damage_dealt, format_number(state.damage, 0))
  update_skill_panel(panel, state)

  return true
end

local function allocate_skill(player, skill_id)
  local skill = SKILL_BY_ID[skill_id]
  if not skill then
    return
  end

  local entity = get_remembered_turret(player)
  if not entity or player.opened ~= entity then
    return
  end

  local state = get_turret_state(entity)
  if get_available_skill_points(state) <= 0 then
    update_turret_gui(player, entity)
    return
  end

  local rank = get_skill_rank(state, skill_id)
  if rank >= skill.max_rank then
    update_turret_gui(player, entity)
    return
  end

  state.skills[skill_id] = rank + 1
  sync_turret_progression(state)
  update_turret_gui(player, entity)
end

local function apply_passive_skill_effects()
  ensure_storage()

  for _, state in pairs(storage.turret_xp.turrets) do
    ensure_skill_state(state)
    local entity = state.entity
    if is_gun_turret(entity) then
      local repair_rank = get_skill_rank(state, "field_repairs")
      if repair_rank > 0 then
        local max_health = safe_read(entity, "max_health")
        local health = safe_read(entity, "health")
        if max_health and health and health > 0 and health < max_health then
          entity.health = math.min(max_health, health + (0.25 * repair_rank * (REFRESH_TICKS / 60)))
        end
      end
    elseif entity and not entity.valid then
      state.entity = nil
    end
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

local function build_turret_gui(player, entity)
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

  local header = body.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(header, "bottom_margin", 8)
  set_style(header, "vertical_align", "center")

  local title = header.add({
    type = "label",
    caption = { "entity-name." .. entity.name },
    style = "heading_2_label"
  })
  set_style(title, "font", "default-bold")

  header.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })

  local ammo_flow = header.add({
    type = "flow",
    name = GUI.ammo,
    direction = "horizontal"
  })
  set_style(ammo_flow, "right_margin", 6)
  set_style(ammo_flow, "vertical_align", "center")

  add_entity_icon(header, entity)

  add_xp_panel(body)

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

  add_skill_panel(frame)

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

  local tags = element.tags or {}
  if tags.turret_xp_action ~= "allocate-skill" then
    return
  end

  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  allocate_skill(player, tags.skill)
end

local function on_runtime_mod_setting_changed(event)
  if not event.setting or string.sub(event.setting, 1, #MOD_PREFIX) ~= MOD_PREFIX then
    return
  end

  ensure_storage()

  for _, state in pairs(storage.turret_xp.turrets) do
    ensure_skill_state(state)
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
    get_turret_state(event.entity)
  end

  if is_gun_turret(cause) then
    local state = get_turret_state(cause)
    state.damage = state.damage + damage
    sync_turret_progression(state)
  end
end

local function on_entity_died(event)
  if is_gun_turret(event.entity) then
    remove_turret_state(event.entity)
  end

  local cause = event.cause
  local damage_force = event.force or (cause and cause.valid and cause.force)
  if damage_force and event.entity and event.entity.valid and event.entity.force == damage_force then
    return
  end

  if is_gun_turret(cause) then
    local state = get_turret_state(cause)
    state.kills = state.kills + 1
    sync_turret_progression(state)
  end

  award_kill_credit(event.entity, cause)
end

local function on_turret_removed(event)
  remove_turret_state(event.entity)
end

local function on_refresh_tick()
  ensure_storage()
  cleanup_target_damage()
  apply_passive_skill_effects()

  for player_index in pairs(storage.turret_xp.players) do
    local player = game.get_player(player_index)
    if player and player.valid and player.connected then
      refresh_player_gui(player)
    else
      storage.turret_xp.players[player_index] = nil
    end
  end
end

script.on_init(ensure_storage)
script.on_configuration_changed(function()
  ensure_storage()
  storage.turret_xp.targets = {}
  for _, state in pairs(storage.turret_xp.turrets) do
    ensure_skill_state(state)
    sync_turret_progression(state)
  end
  for _, player in pairs(game.players) do
    destroy_gui(player)
    forget_open_turret(player)
  end
end)

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(defines.events.on_gui_click, on_gui_click)
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
