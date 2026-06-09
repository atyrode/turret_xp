return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

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

commands.add_command("turret-xp-dev", { "turret-xp.dev-command-help" }, function(command)
  local player = command.player_index and game.get_player(command.player_index)
  if not player then
    return
  end

  local player_settings = ensure_player_settings(player)
  player_settings.dev_controls = player_settings.dev_controls ~= true
  player.print(player_settings.dev_controls and { "turret-xp.dev-enabled" } or { "turret-xp.dev-disabled" })

  local entity = get_remembered_turret(player)
  if entity and player.opened == entity then
    build_turret_gui(player, entity)
  end
end)

end
