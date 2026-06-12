return function()
  local electric_arc_base = data.raw["beam"] and data.raw["beam"]["electric-beam-no-sound"]
  if electric_arc_base then
    local electric_arc = table.deepcopy(electric_arc_base)
    electric_arc.name = "turret-xp-electric-arc"
    electric_arc.localised_name = { "entity-name.turret-xp-electric-arc" }
    electric_arc.hidden = true
    electric_arc.hidden_in_factoriopedia = true
    electric_arc.action = nil
    electric_arc.working_sound = nil
    electric_arc.damage_interval = 60
    electric_arc.random_target_offset = false
    data:extend({ electric_arc })
  end

  local fire_flash_base = data.raw["fire"] and data.raw["fire"]["fire-flame"]
  if fire_flash_base then
    local fire_flash = table.deepcopy(fire_flash_base)
    fire_flash.name = "turret-xp-fire-flash"
    fire_flash.localised_name = { "entity-name.turret-xp-fire-flash" }
    fire_flash.hidden = true
    fire_flash.hidden_in_factoriopedia = true
    fire_flash.damage_per_tick = { amount = 0, type = "fire" }
    fire_flash.maximum_damage_multiplier = 1
    fire_flash.damage_multiplier_increase_per_added_fuel = 0
    fire_flash.damage_multiplier_decrease_per_tick = 1
    fire_flash.spawn_entity = nil
    fire_flash.spread_delay = 60 * 60 * 60
    fire_flash.spread_delay_deviation = 0
    fire_flash.maximum_spread_count = 0
    fire_flash.emissions_per_second = nil
    fire_flash.initial_lifetime = 24
    fire_flash.lifetime_increase_by = 0
    fire_flash.lifetime_increase_cooldown = 60
    fire_flash.maximum_lifetime = 24
    fire_flash.delay_between_initial_flames = 60
    fire_flash.working_sound = nil
    data:extend({ fire_flash })
  end

  local toxic_puff_base = data.raw["smoke-with-trigger"] and data.raw["smoke-with-trigger"]["poison-cloud-visual-dummy"]
  if toxic_puff_base then
    local toxic_puff = table.deepcopy(toxic_puff_base)
    toxic_puff.name = "turret-xp-toxic-puff"
    toxic_puff.localised_name = { "entity-name.turret-xp-toxic-puff" }
    toxic_puff.hidden = true
    toxic_puff.hidden_in_factoriopedia = true
    toxic_puff.duration = 90
    toxic_puff.fade_away_duration = 45
    toxic_puff.spread_duration = 45
    toxic_puff.working_sound = nil
    data:extend({ toxic_puff })
  end

  data:extend({
    {
      type = "sound",
      name = "turret-xp-electric-proc",
      category = "weapon",
      filename = "__base__/sound/fight/electric-beam.ogg",
      volume = 0.28,
      audible_distance_modifier = 0.45,
    },
    {
      type = "sound",
      name = "turret-xp-fire-proc",
      category = "weapon",
      filename = "__base__/sound/fire-1.ogg",
      volume = 0.22,
      audible_distance_modifier = 0.35,
    },
  })
end
