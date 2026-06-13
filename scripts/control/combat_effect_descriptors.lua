local combat_effect_descriptors = {}

local function copy_array(values)
  local result = {}
  for index, value in ipairs(values or {}) do
    result[index] = value
  end
  return result
end

function combat_effect_descriptors.new(combat_constants)
  combat_constants = combat_constants or {}
  local trail = combat_constants.trail or {}
  local vfx = combat_constants.vfx or {}
  local sfx = combat_constants.sfx or {}

  local elements = {
    fire = {
      trail = trail.fire,
      color = { 1, 0.28, 0.05 },
      trail_width = 1,
      trail_ttl = 10,
      direct_damage_multiplier = 0.10,
      status_damage_multiplier = 0.25,
      status_damage_type = "fire",
      status_duration = 4 * 60,
      status_interval = 60,
      status_sprite = "virtual-signal/signal-fire",
      visual_entity = vfx.fire_flash,
      fallback_sprite = "virtual-signal/signal-fire",
      fallback_sprite_scale = 0.45,
      fallback_sprite_ttl = 24,
      sound = sfx.fire,
      sound_key = "fire",
      sound_cooldown = 28,
      sound_volume = 0.75,
      budget = { "visual_entities", "render_sprites", "sounds", "status_effect_ticks" },
    },
    electric = {
      trail = trail.electric_faint,
      color = { 0.35, 0.75, 1 },
      trail_width = 1,
      trail_ttl = 10,
      arc_trail = trail.electric,
      arc_damage_multiplier = 0.25,
      arc_damage_type = "electric",
      arc_radius = 7,
      arc_visual_entity = vfx.electric_arc,
      sound = sfx.electric,
      sound_key = "electric",
      sound_cooldown = 20,
      sound_volume = 0.7,
      budget = { "visual_entities", "render_lines", "sounds" },
      target_limits = { arc_radius = 7, arc_count_source = "electric_rank_capped_at_5" },
    },
    explosive = {
      trail = trail.explosive,
      color = { 1, 0.58, 0.15 },
      trail_width = 1,
      trail_ttl = 10,
      splash_damage_multiplier = 0.20,
      splash_damage_type = "explosion",
      splash_radius = 3,
      splash_rank_radius = 0.15,
      splash_radius_bonus_cap = 3,
      splash_targets = 4,
      short_effect = "explosion",
      budget = { "short_effects" },
      target_limits = { splash_targets = 4, splash_radius = 3, splash_radius_bonus_cap = 3 },
    },
    toxic = {
      trail = trail.toxic,
      color = { 0.42, 0.92, 0.28 },
      trail_width = 1,
      trail_ttl = 10,
      status_damage_multiplier = 0.08,
      status_damage_type = "poison",
      status_duration = 8 * 60,
      status_interval = 60,
      status_sprite = "virtual-signal/signal-skull",
      visual_entity = vfx.toxic_puff,
      visual_duration = 90,
      fallback_sprite = "virtual-signal/signal-skull",
      fallback_sprite_scale = 0.38,
      fallback_sprite_ttl = 30,
      budget = { "visual_entities", "render_sprites", "status_effect_ticks" },
    },
  }

  local combos = {
    stormfire = {
      elements = { "fire", "electric" },
      flags = { "fire", "electric" },
      damage_multiplier = 0.15,
      damage_type = "fire",
      visual_entity = vfx.fire_flash,
      fallback_sprite = "virtual-signal/signal-fire",
      fallback_sprite_scale = 0.55,
      fallback_sprite_ttl = 30,
      sound = sfx.fire,
      sound_key = "combo-fire",
      sound_cooldown = 36,
      sound_volume = 0.65,
      budget = { "visual_entities", "render_sprites", "sounds" },
    },
    incendiary = {
      elements = { "fire", "explosive" },
      flags = { "fire", "explosive" },
      damage_multiplier = 0.20,
      damage_type = "fire",
      visual_entity = vfx.fire_flash,
      fallback_sprite = "virtual-signal/signal-fire",
      fallback_sprite_scale = 0.55,
      fallback_sprite_ttl = 30,
      short_effect = "explosion-gunshot",
      sound = sfx.fire,
      sound_key = "combo-fire",
      sound_cooldown = 36,
      sound_volume = 0.65,
      budget = { "visual_entities", "render_sprites", "short_effects", "sounds" },
    },
    shockburst = {
      elements = { "electric", "explosive" },
      flags = { "electric", "explosive" },
      damage_multiplier = 0.25,
      damage_type = "electric",
      radius = 8,
      visual_entity = vfx.electric_arc,
      trail = trail.electric,
      color = { 0.35, 0.75, 1 },
      short_effect = "explosion-gunshot",
      sound = sfx.electric,
      sound_key = "combo-electric",
      sound_cooldown = 28,
      sound_volume = 0.7,
      budget = { "visual_entities", "render_lines", "short_effects", "sounds" },
      target_limits = { radius = 8, targets = 1 },
    },
    choking = {
      elements = { "fire", "toxic" },
      flags = { "fire", "toxic" },
      status_damage_multiplier = 0.18,
      status_damage_type = "poison",
      status_duration = 5 * 60,
      status_interval = 60,
      status_sprite = "virtual-signal/signal-skull",
      color = { 0.42, 0.92, 0.28 },
      visual_entity = vfx.toxic_puff,
      visual_duration = 90,
      budget = { "visual_entities", "status_effect_ticks" },
    },
    static_toxin = {
      elements = { "electric", "toxic" },
      flags = { "electric", "toxic" },
    },
    dirty_blast = {
      elements = { "explosive", "toxic" },
      flags = { "explosive", "toxic" },
      status_damage_multiplier = 0.06,
      status_damage_type = "poison",
      status_duration = 8 * 60,
      status_interval = 60,
      status_sprite = "virtual-signal/signal-skull",
      color = { 0.42, 0.92, 0.28 },
      radius = 3,
      spread_targets = 3,
      budget = { "status_effect_ticks" },
      target_limits = { radius = 3, spread_targets = 3 },
    },
  }

  local service = {
    elements = elements,
    combos = combos,
    combo_order = {
      "stormfire",
      "incendiary",
      "shockburst",
      "choking",
      "static_toxin",
      "dirty_blast",
    },
  }

  function service.snapshot()
    local element_snapshot = {}
    for id, descriptor in pairs(elements) do
      element_snapshot[id] = {
        trail = descriptor.trail,
        direct_damage_multiplier = descriptor.direct_damage_multiplier,
        status_damage_multiplier = descriptor.status_damage_multiplier,
        arc_damage_multiplier = descriptor.arc_damage_multiplier,
        splash_damage_multiplier = descriptor.splash_damage_multiplier,
        budget = copy_array(descriptor.budget),
        target_limits = descriptor.target_limits,
      }
    end

    local combo_snapshot = {}
    for id, descriptor in pairs(combos) do
      combo_snapshot[id] = {
        elements = copy_array(descriptor.elements),
        damage_multiplier = descriptor.damage_multiplier,
        status_damage_multiplier = descriptor.status_damage_multiplier,
        budget = copy_array(descriptor.budget),
        target_limits = descriptor.target_limits,
      }
    end

    return {
      elements = element_snapshot,
      combos = combo_snapshot,
    }
  end

  return service
end

return combat_effect_descriptors
