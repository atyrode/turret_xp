local constants = {}

constants.refresh_ticks = 60
constants.target_damage_ttl = 60 * 60 * 5
constants.feeder_inserter_radius = 8
constants.feeder_input_buffer_slots = 100
constants.feeder_consume_limit = 100

constants.combat = {
  space_xp_multiplier = 0.1,
  asteroid_xp_multiplier = 0.2,
  trail = {
    bullet = "bullet-beam-yellow",
    bullet_faint = "bullet-beam-yellow-faint",
    fire = "bullet-beam-red-faint",
    electric = "bullet-beam-cyan",
    electric_faint = "bullet-beam-cyan-faint",
    explosive = "bullet-beam-orange",
    toxic = "bullet-beam-green-faint",
  },
  vfx = {
    electric_arc = "turret-xp-electric-arc",
    fire_flash = "turret-xp-fire-flash",
    toxic_puff = "turret-xp-toxic-puff",
  },
  sfx = {
    electric = "turret-xp-electric-proc",
    fire = "turret-xp-fire-proc",
  },
  effect_budget = {
    render_lines_per_surface_tick = 24,
    render_sprites_per_surface_tick = 16,
    visual_entities_per_surface_tick = 12,
    short_effects_per_surface_tick = 12,
    sounds_per_surface_tick = 8,
    status_effect_ticks_per_tick = 256,
    pending_visuals_active = 512,
    visual_entities_active = 512,
  },
}

return constants
