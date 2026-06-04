local MOD_PREFIX = "turret-xp-"
local GUI = {
  panel = MOD_PREFIX .. "panel",
  status = MOD_PREFIX .. "status",
  level = MOD_PREFIX .. "level",
  quality = MOD_PREFIX .. "quality",
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
  kill_credit = MOD_PREFIX .. "kill-credit",
  damage_dealt = MOD_PREFIX .. "damage-dealt",
  damage_xp = MOD_PREFIX .. "damage-xp",
  kill_credit_xp = MOD_PREFIX .. "kill-credit-xp",
  total_xp = MOD_PREFIX .. "total-xp"
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

  local xp_settings = get_xp_settings()
  local total_xp = ((state.damage or 0) * xp_settings.xp_per_damage)
    + ((state.kill_credit or 0) * xp_settings.xp_per_kill_credit)
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
      damage = 0
    }
    storage.turret_xp.turrets[key] = state
  end

  state.xp = state.xp or 0
  state.total_xp = state.total_xp or 0
  state.level = math.max(1, state.level or 1)
  state.kills = state.kills or 0
  state.kill_credit = state.kill_credit or state.kills or 0
  state.damage = state.damage or 0
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
    if quality and quality.valid then
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

local function add_empty_cell(parent, width)
  local ok, element = pcall(function()
    return parent.add({
      type = "empty-widget"
    })
  end)

  if not ok or not element then
    element = parent.add({
      type = "label",
      caption = ""
    })
  end

  set_style(element, "width", width or 18)
  return element
end

local function add_rich_info_label(parent, tooltip)
  if not tooltip then
    return add_empty_cell(parent, 18)
  end

  local label = parent.add({
    type = "label",
    caption = "[img=info]",
    tooltip = tooltip,
    style = "caption_label"
  })
  set_style(label, "left_margin", 6)
  set_style(label, "right_margin", 2)
  return label
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

local function add_ammo_row(parent)
  local label_element = parent.add({
    type = "label",
    caption = with_info_marker({ "turret-xp.ammo" }, { "turret-xp.ammo-tooltip" }),
    tooltip = { "turret-xp.ammo-tooltip" },
    style = "caption_label"
  })
  set_style(label_element, "font_color", COLOR.caption)

  local value_flow = parent.add({
    type = "flow",
    name = GUI.ammo,
    direction = "horizontal"
  })
  set_style(value_flow, "horizontal_align", "right")
  set_style(value_flow, "horizontally_stretchable", true)
end

local function add_section_header(parent, caption, tooltip)
  local subheader = parent.add({
    type = "frame",
    direction = "horizontal",
    style = "subheader_frame"
  })
  set_style(subheader, "top_margin", 8)
  set_style(subheader, "horizontally_stretchable", true)
  set_style(subheader, "vertical_align", "center")

  local label = subheader.add({
    type = "label",
    caption = with_info_marker(caption, tooltip),
    tooltip = tooltip,
    style = "subheader_caption_label"
  })
  subheader.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })
  return label
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

local function add_status_flow(parent)
  local flow = parent.add({
    type = "flow",
    name = GUI.status,
    direction = "horizontal",
    style = "flib_indicator_flow"
  })
  set_style(flow, "top_margin", 2)
  return flow
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
  set_style(bar, "height", 18)
  set_style(bar, "top_margin", 4)
  set_style(bar, "bottom_margin", 4)

  local bottom = xp_panel.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(bottom, "horizontally_stretchable", true)

  local percent = bottom.add({
    type = "label",
    name = GUI.xp_percent,
    caption = { "turret-xp.progress-percent", 0 },
    style = "caption_label"
  })
  set_style(percent, "font_color", COLOR.muted)

  bottom.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })

  bottom.add({
    type = "label",
    caption = with_info_marker({ "turret-xp.next-unlock" }, { "turret-xp.next-unlock-tooltip" }),
    tooltip = { "turret-xp.next-unlock-tooltip" },
    style = "caption_label"
  })
end

local function update_status(panel, ammo_count)
  local flow = find_gui_element(panel, GUI.status)
  if not flow then
    return
  end

  flow.clear()
  local has_ammo = ammo_count and ammo_count > 0
  flow.add({
    type = "sprite",
    sprite = has_ammo and "flib_indicator_green" or "flib_indicator_yellow",
    style = "flib_indicator"
  })
  local label = flow.add({
    type = "label",
    caption = has_ammo and { "turret-xp.status-loaded" } or { "turret-xp.status-no-ammo" },
    style = "caption_label"
  })
  set_style(label, "font_color", COLOR.muted)
end

local function update_ammo_row(panel, ammo_name, ammo_count, ammo_quality)
  local flow = find_gui_element(panel, GUI.ammo)
  if not flow then
    return
  end

  flow.clear()
  if not ammo_name then
    local label = flow.add({
      type = "label",
      caption = { "turret-xp.no-ammo" },
      style = "caption_label"
    })
    set_style(label, "font_color", COLOR.muted)
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
  local xp_settings = get_xp_settings()
  local damage_xp = (state.damage or 0) * xp_settings.xp_per_damage
  local kill_credit_xp = (state.kill_credit or 0) * xp_settings.xp_per_kill_credit

  set_gui_caption(panel, GUI.level, { "turret-xp.level", progression.level })
  set_gui_caption(panel, GUI.quality, { "", "[quality=", quality_name, "] ", { "quality-name." .. quality_name } })
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
  update_status(panel, ammo_count)

  if ammo_name then
    set_gui_caption(panel, GUI.damage, { "turret-xp.damage-value", format_damage_per_shot(entity, ammo_name) }, { "turret-xp.damage-tooltip" })
    set_gui_caption(panel, GUI.dps, format_estimated_dps(entity, ammo_name), { "turret-xp.dps-tooltip" })
  else
    set_gui_caption(panel, GUI.damage, { "turret-xp.damage-unknown" }, nil)
    set_gui_caption(panel, GUI.dps, "-", nil)
  end

  set_gui_caption(panel, GUI.kills, format_number(state.kills, 0))
  set_gui_caption(panel, GUI.kill_credit, format_number(state.kill_credit, 1), { "turret-xp.kill-credit-tooltip" })
  set_gui_caption(panel, GUI.damage_dealt, format_number(state.damage, 0))
  set_gui_caption(panel, GUI.damage_xp, format_number(damage_xp, 1), { "turret-xp.damage-xp-tooltip" })
  set_gui_caption(panel, GUI.kill_credit_xp, format_number(kill_credit_xp, 1), { "turret-xp.kill-credit-xp-tooltip" })
  set_gui_caption(panel, GUI.total_xp, format_number(state.total_xp, 0), { "turret-xp.total-xp-tooltip" })

  return true
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
  add_entity_icon(header, entity)

  local title_flow = header.add({
    type = "flow",
    direction = "vertical"
  })
  set_style(title_flow, "left_margin", 8)
  set_style(title_flow, "horizontally_stretchable", true)

  local title = title_flow.add({
    type = "label",
    caption = { "entity-name." .. entity.name },
    style = "heading_2_label"
  })
  set_style(title, "font", "default-bold")

  title_flow.add({
    type = "label",
    name = GUI.quality,
    caption = "",
    style = "caption_label"
  })

  add_status_flow(title_flow)
  header.add({
    type = "empty-widget",
    style = "flib_horizontal_pusher"
  })
  add_rich_info_label(header, { "turret-xp.prototype-note" })

  add_xp_panel(body)

  add_section_header(body, { "turret-xp.current-turret" })
  local current = make_stats_table(body)
  add_stat_row(current, { "turret-xp.hp" }, GUI.hp)
  add_stat_row(current, { "turret-xp.shooting-speed" }, GUI.shooting_speed, {
    info_tooltip = { "turret-xp.shooting-speed-tooltip" }
  })
  add_stat_row(current, { "turret-xp.range" }, GUI.range, {
    info_tooltip = { "turret-xp.range-tooltip" }
  })
  add_ammo_row(current)
  add_stat_row(current, { "turret-xp.damage" }, GUI.damage, {
    info_tooltip = { "turret-xp.damage-tooltip" }
  })
  add_stat_row(current, { "turret-xp.dps" }, GUI.dps, {
    info_tooltip = { "turret-xp.dps-tooltip" }
  })

  add_section_header(body, { "turret-xp.progression-stats" }, { "turret-xp.progression-tooltip" })
  local progression_stats = make_stats_table(body)
  add_stat_row(progression_stats, { "turret-xp.killing-blows" }, GUI.kills)
  add_stat_row(progression_stats, { "turret-xp.kill-credit" }, GUI.kill_credit, {
    info_tooltip = { "turret-xp.kill-credit-tooltip" }
  })
  add_stat_row(progression_stats, { "turret-xp.damage-dealt" }, GUI.damage_dealt)
  add_stat_row(progression_stats, { "turret-xp.damage-xp" }, GUI.damage_xp, {
    info_tooltip = { "turret-xp.damage-xp-tooltip" }
  })
  add_stat_row(progression_stats, { "turret-xp.kill-credit-xp" }, GUI.kill_credit_xp, {
    info_tooltip = { "turret-xp.kill-credit-xp-tooltip" }
  })
  add_stat_row(progression_stats, { "turret-xp.total-xp" }, GUI.total_xp, {
    info_tooltip = { "turret-xp.total-xp-tooltip" }
  })

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

local function on_runtime_mod_setting_changed(event)
  if not event.setting or string.sub(event.setting, 1, #MOD_PREFIX) ~= MOD_PREFIX then
    return
  end

  ensure_storage()

  for _, state in pairs(storage.turret_xp.turrets) do
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
    sync_turret_progression(state)
  end
  for _, player in pairs(game.players) do
    destroy_gui(player)
    forget_open_turret(player)
  end
end)

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
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
