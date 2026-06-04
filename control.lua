local MOD_PREFIX = "turret-xp-"
local GUI = {
  panel = MOD_PREFIX .. "panel"
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

local function sum_trigger_deliveries(deliveries)
  local total = 0

  for _, delivery in pairs(as_array(deliveries)) do
    total = total + sum_damage_effects(delivery.target_effects)
  end

  return total
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

local function get_attack_parameters(entity)
  return safe_read(safe_read(entity, "prototype"), "attack_parameters") or {}
end

local function get_loaded_ammo(entity)
  local inventory = entity.get_inventory(defines.inventory.turret_ammo)
  if not inventory or not inventory.valid then
    return nil, 0
  end

  local ammo_name = nil
  local count = 0

  for i = 1, #inventory do
    local stack = inventory[i]
    if stack and stack.valid_for_read then
      ammo_name = ammo_name or stack.name
      if stack.name == ammo_name then
        count = count + stack.count
      end
    end
  end

  return ammo_name, count
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

local function estimate_ammo_damage(entity, ammo_name)
  if not ammo_name then
    return nil
  end

  local ammo_type = get_ammo_type(ammo_name)
  if not ammo_type then
    return nil
  end

  local damage = sum_trigger_items(ammo_type.action)
  local attack_parameters = get_attack_parameters(entity)
  damage = damage * (attack_parameters.damage_modifier or 1)
  return damage
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

local function format_shots_per_second(entity, ammo_name)
  local attack_parameters = get_attack_parameters(entity)
  if not attack_parameters.cooldown or attack_parameters.cooldown <= 0 then
    return "-"
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

  if force and attack_parameters.ammo_category then
    local ok, modifier = pcall(function()
      return force.get_gun_speed_modifier(attack_parameters.ammo_category)
    end)

    if ok and modifier then
      speed_modifier = modifier
    end
  end

  local bonus_speed = base_speed * speed_modifier
  local total_speed = base_speed + bonus_speed

  if math.abs(bonus_speed) >= 0.005 then
    return string.format("%.2f/s (%.2f + %.2f)", total_speed, base_speed, bonus_speed)
  end

  return string.format("%.2f/s", total_speed)
end

local function format_range(entity, ammo_name)
  local attack_parameters = get_attack_parameters(entity)
  local range = safe_read(safe_read(entity, "prototype"), "turret_range") or attack_parameters.range

  return format_number(range, 1)
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

local function add_stat_row(parent, label, value, tooltip)
  local label_element = parent.add({
    type = "label",
    caption = label,
    tooltip = tooltip
  })
  set_style(label_element, "font_color", { 0.62, 0.62, 0.62 })

  local value_element = parent.add({
    type = "label",
    caption = value,
    tooltip = tooltip
  })
  set_style(value_element, "horizontal_align", "right")
  set_style(value_element, "single_line", false)
  set_style(value_element, "maximal_width", 210)

  return label_element, value_element
end

local function add_section_label(parent, caption)
  local line = parent.add({
    type = "line",
    direction = "horizontal"
  })
  set_style(line, "top_margin", 8)
  set_style(line, "bottom_margin", 6)

  local label = parent.add({
    type = "label",
    caption = caption
  })
  set_style(label, "font", "heading-3")
  set_style(label, "bottom_margin", 2)
  return label
end

local function add_entity_icon(parent, entity)
  local quality = safe_read(entity, "quality")
  local quality_name = quality and quality.name or "normal"

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

  local state = get_turret_state(entity)
  local progression = sync_turret_progression(state)
  local required = progression.required
  local progress = 0
  if required > 0 then
    progress = math.min(1, progression.xp / required)
  end

  local ammo_name, ammo_count = get_loaded_ammo(entity)
  local ammo_damage = estimate_ammo_damage(entity, ammo_name)
  local frame = make_gui_frame(player)
  set_style(frame, "minimal_width", 340)
  set_style(frame, "maximal_width", 420)

  local header = frame.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(header, "bottom_margin", 6)
  add_entity_icon(header, entity)

  local title_flow = header.add({
    type = "flow",
    direction = "vertical"
  })
  set_style(title_flow, "left_margin", 8)
  set_style(title_flow, "horizontally_stretchable", true)

  local title = title_flow.add({
    type = "label",
    caption = { "entity-name." .. entity.name }
  })
  set_style(title, "font", "heading-2")

  title_flow.add({
    type = "label",
    caption = { "turret-xp.level", progression.level }
  })

  local xp_flow = frame.add({
    type = "flow",
    direction = "horizontal"
  })
  set_style(xp_flow, "horizontally_stretchable", true)

  xp_flow.add({
    type = "label",
    caption = { "turret-xp.next-level" }
  })
  local xp_label = xp_flow.add({
    type = "label",
    caption = { "turret-xp.xp-progress", format_number(progression.xp, 0), format_number(required, 0) }
  })
  set_style(xp_label, "horizontal_align", "right")
  set_style(xp_label, "horizontally_stretchable", true)

  local bar = frame.add({
    type = "progressbar",
    value = progress
  })
  set_style(bar, "horizontally_stretchable", true)
  set_style(bar, "height", 18)

  local max_health = safe_read(entity, "max_health")
  local health = safe_read(entity, "health") or max_health

  add_section_label(frame, { "turret-xp.current-turret" })
  local current = frame.add({
    type = "table",
    column_count = 2,
    draw_horizontal_lines = true
  })
  set_style(current, "horizontally_stretchable", true)

  add_stat_row(current, { "turret-xp.hp" }, string.format("%s / %s", format_number(health, 0), format_number(max_health, 0)))
  add_stat_row(current, { "turret-xp.shooting-speed" }, format_shots_per_second(entity, ammo_name), { "turret-xp.shooting-speed-tooltip" })
  add_stat_row(current, { "turret-xp.range" }, format_range(entity, ammo_name), { "turret-xp.range-tooltip" })

  if ammo_name then
    add_stat_row(current, { "turret-xp.ammo" }, string.format("[item=%s] x%d", ammo_name, ammo_count))
  else
    add_stat_row(current, { "turret-xp.ammo" }, { "turret-xp.no-ammo" })
  end

  if ammo_damage then
    add_stat_row(current, { "turret-xp.damage" }, { "turret-xp.damage-value", format_number(ammo_damage, 1) })
  else
    add_stat_row(current, { "turret-xp.damage" }, { "turret-xp.damage-unknown" })
  end

  add_section_label(frame, { "turret-xp.progression-stats" })
  local progression_stats = frame.add({
    type = "table",
    column_count = 2,
    draw_horizontal_lines = true
  })
  set_style(progression_stats, "horizontally_stretchable", true)

  add_stat_row(progression_stats, { "turret-xp.killing-blows" }, format_number(state.kills, 0))
  add_stat_row(progression_stats, { "turret-xp.kill-credit" }, format_number(state.kill_credit, 1), { "turret-xp.kill-credit-tooltip" })
  add_stat_row(progression_stats, { "turret-xp.damage-dealt" }, format_number(state.damage, 0))
  add_stat_row(progression_stats, { "turret-xp.total-xp" }, format_number(state.total_xp, 0), { "turret-xp.total-xp-tooltip" })

  local note = frame.add({
    type = "label",
    caption = { "turret-xp.prototype-note" }
  })
  set_style(note, "single_line", false)
  set_style(note, "top_margin", 8)
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

  build_turret_gui(player, entity)
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
