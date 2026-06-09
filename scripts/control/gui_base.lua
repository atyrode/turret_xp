return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

function destroy_gui(player)
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

function remember_open_turret(player, entity)
  local player_state = ensure_player_state(player)
  player_state.entity = entity
  player_state.unit_number = entity.unit_number
end

function forget_open_turret(player)
  ensure_storage()
  storage.turret_xp.players[player.index] = nil
end

function get_remembered_turret(player)
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

function set_style(element, property, value)
  if element and element.valid and element.style then
    pcall(function()
      element.style[property] = value
    end)
  end
end

function set_element_style(element, style)
  if element and element.valid then
    pcall(function()
      element.style = style
    end)
  end
end

function find_gui_element(parent, name)
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

function get_gui_panel(player)
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

function set_gui_caption(panel, name, caption, tooltip)
  local element = find_gui_element(panel, name)
  if element then
    element.caption = caption
    element.tooltip = tooltip
  end
end

function set_gui_progress(panel, name, value)
  local element = find_gui_element(panel, name)
  if element then
    element.value = value
  end
end

function evolution_anchor_name(kind, id, slot)
  if not kind or not id then
    return nil
  end

  local key = tostring(id):gsub("[^%w_-]", "-")
  if slot then
    key = tostring(slot) .. "-" .. key
  end
  return GUI.evolution .. "-anchor-" .. tostring(kind) .. "-" .. key
end

function scroll_evolution_to_anchor(panel, anchor_name)
  if not anchor_name then
    return
  end

  local evolution_panel = find_gui_element(panel, GUI.evolution)
  local anchor = evolution_panel and find_gui_element(evolution_panel, anchor_name) or nil
  if evolution_panel and anchor then
    pcall(function()
      evolution_panel.scroll_to_element(anchor)
    end)
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

end
