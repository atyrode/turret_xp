local MOD_PREFIX = "turret-xp-"
local GUI = {
  panel = MOD_PREFIX .. "panel"
}

local BASE_XP_REQUIRED = 100
local XP_REQUIRED_STEP = 50
local XP_PER_DAMAGE = 1
local XP_PER_KILL = 20
local REFRESH_TICKS = 60

local function ensure_storage()
  storage.turret_xp = storage.turret_xp or {}
  storage.turret_xp.turrets = storage.turret_xp.turrets or {}
  storage.turret_xp.players = storage.turret_xp.players or {}
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

local function xp_required(level)
  return BASE_XP_REQUIRED + ((level - 1) * XP_REQUIRED_STEP)
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
      damage = 0
    }
    storage.turret_xp.turrets[key] = state
  end

  state.xp = state.xp or 0
  state.total_xp = state.total_xp or 0
  state.level = math.max(1, state.level or 1)
  state.kills = state.kills or 0
  state.damage = state.damage or 0
  return state
end

local function remove_turret_state(entity)
  if not is_gun_turret(entity) then
    return
  end

  ensure_storage()
  storage.turret_xp.turrets[turret_key(entity)] = nil
end

local function add_turret_xp(entity, amount)
  if not is_gun_turret(entity) or amount <= 0 then
    return
  end

  local state = get_turret_state(entity)
  local rounded_amount = math.floor(amount + 0.5)
  state.xp = state.xp + rounded_amount
  state.total_xp = state.total_xp + rounded_amount

  while state.xp >= xp_required(state.level) do
    state.xp = state.xp - xp_required(state.level)
    state.level = state.level + 1
  end
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
  if entity.prototype and entity.prototype.attack_parameters then
    return entity.prototype.attack_parameters
  end

  return {}
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

local function estimate_ammo_damage(entity, ammo_name)
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

  if not ok or not ammo_type then
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
    local ammo = prototypes.item[ammo_name]
    local ok, ammo_type = pcall(function()
      return ammo and ammo.get_ammo_type("turret")
    end)
    if ok and ammo_type and ammo_type.cooldown_modifier then
      cooldown = cooldown * ammo_type.cooldown_modifier
    end
  end

  return string.format("%.2f/s", 60 / cooldown)
end

local function format_range(entity, ammo_name)
  local attack_parameters = get_attack_parameters(entity)
  local range = entity.prototype.turret_range or attack_parameters.range

  if ammo_name then
    local ammo = prototypes.item[ammo_name]
    local ok, ammo_type = pcall(function()
      return ammo and ammo.get_ammo_type("turret")
    end)
    if ok and ammo_type and ammo_type.range_modifier then
      range = (range or 0) + ammo_type.range_modifier
    end
  end

  return format_number(range, 1)
end

local function add_stat_row(parent, label, value)
  parent.add({
    type = "label",
    caption = label
  })
  parent.add({
    type = "label",
    caption = value
  })
end

local function add_section_label(parent, caption)
  local label = parent.add({
    type = "label",
    caption = caption
  })
  set_style(label, "font", "heading-3")
  set_style(label, "top_margin", 8)
  return label
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
  local required = xp_required(state.level)
  local progress = 0
  if required > 0 then
    progress = math.min(1, state.xp / required)
  end

  local ammo_name, ammo_count = get_loaded_ammo(entity)
  local ammo_damage = estimate_ammo_damage(entity, ammo_name)
  local frame = make_gui_frame(player)
  set_style(frame, "minimal_width", 320)
  set_style(frame, "maximal_width", 380)

  local level_flow = frame.add({
    type = "flow",
    direction = "horizontal"
  })
  level_flow.add({
    type = "label",
    caption = { "turret-xp.level", state.level }
  })
  local xp_label = level_flow.add({
    type = "label",
    caption = { "turret-xp.xp-progress", state.xp, required }
  })
  set_style(xp_label, "left_margin", 12)

  local bar = frame.add({
    type = "progressbar",
    value = progress
  })
  set_style(bar, "horizontally_stretchable", true)
  set_style(bar, "height", 18)

  add_section_label(frame, { "turret-xp.combat-stats" })
  local stats = frame.add({
    type = "table",
    column_count = 2,
    draw_horizontal_lines = true
  })
  set_style(stats, "horizontally_stretchable", true)

  local max_health = entity.prototype.max_health or 0
  local health = entity.health or max_health

  add_stat_row(stats, { "turret-xp.hp" }, string.format("%s / %s", format_number(health, 0), format_number(max_health, 0)))
  add_stat_row(stats, { "turret-xp.attack-speed" }, format_shots_per_second(entity, ammo_name))
  add_stat_row(stats, { "turret-xp.range" }, format_range(entity, ammo_name))

  if ammo_name then
    add_stat_row(stats, { "turret-xp.ammo" }, string.format("[item=%s] x%d", ammo_name, ammo_count))
  else
    add_stat_row(stats, { "turret-xp.ammo" }, { "turret-xp.no-ammo" })
  end

  if ammo_damage then
    add_stat_row(stats, { "turret-xp.damage" }, { "turret-xp.damage-value", format_number(ammo_damage, 1) })
  else
    add_stat_row(stats, { "turret-xp.damage" }, { "turret-xp.damage-unknown" })
  end

  add_section_label(frame, { "turret-xp.progression-stats" })
  local progression = frame.add({
    type = "table",
    column_count = 2,
    draw_horizontal_lines = true
  })
  set_style(progression, "horizontally_stretchable", true)

  add_stat_row(progression, { "turret-xp.kills" }, format_number(state.kills, 0))
  add_stat_row(progression, { "turret-xp.damage-dealt" }, format_number(state.damage, 0))
  add_stat_row(progression, { "turret-xp.total-xp" }, format_number(state.total_xp, 0))

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

local function on_entity_damaged(event)
  local cause = event.cause
  if not is_gun_turret(cause) then
    return
  end

  if event.entity and event.entity.valid and event.entity.force == cause.force then
    return
  end

  local damage = event.final_damage_amount or 0
  local state = get_turret_state(cause)
  state.damage = state.damage + damage
  add_turret_xp(cause, damage * XP_PER_DAMAGE)
end

local function on_entity_died(event)
  if is_gun_turret(event.entity) then
    remove_turret_state(event.entity)
  end

  local cause = event.cause
  if not is_gun_turret(cause) then
    return
  end

  if event.entity and event.entity.valid and event.entity.force == cause.force then
    return
  end

  local state = get_turret_state(cause)
  state.kills = state.kills + 1
  add_turret_xp(cause, XP_PER_KILL)
end

local function on_turret_removed(event)
  remove_turret_state(event.entity)
end

local function on_refresh_tick()
  ensure_storage()

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
  for _, player in pairs(game.players) do
    destroy_gui(player)
    forget_open_turret(player)
  end
end)

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
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
