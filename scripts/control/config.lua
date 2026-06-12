local label_colors = require("scripts.control.label_colors")

return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  DOMAIN = require("scripts.domain")

  MOD_PREFIX = DOMAIN.names.mod_prefix
  CHIP_NAME = DOMAIN.names.chip
  BOUND_TURRET_NAME = DOMAIN.names.bound_turret
  BOUND_TURRET_PLACEHOLDER_NAME = DOMAIN.names.bound_turret_placeholder
  BOUND_TURRET_VARIANT_PREFIX = DOMAIN.names.bound_turret_variant_prefix
  BOUND_TURRET_PLACEHOLDER_VARIANT_PREFIX = DOMAIN.names.bound_turret_placeholder_variant_prefix
  FEEDER_NAME = DOMAIN.names.feeder
  PROFILE_TAG = DOMAIN.names.profile_tag
  BOUND_TURRET_TAG = DOMAIN.names.bound_turret_tag
  BASE_TURRET_NAME = DOMAIN.names.base_turret
  SPECIALIZED_TURRET_PREFIX = DOMAIN.names.specialized_turret_prefix

  GUI = {
    panel = MOD_PREFIX .. "panel",
    core = MOD_PREFIX .. "core",
    core_slot = MOD_PREFIX .. "core-slot",
    core_status = MOD_PREFIX .. "core-status",
    core_actions = MOD_PREFIX .. "core-actions",
    core_name = MOD_PREFIX .. "core-name",
    core_name_visible = MOD_PREFIX .. "core-name-visible",
    core_name_level_visible = MOD_PREFIX .. "core-name-level-visible",
    core_color_preview = MOD_PREFIX .. "core-color-preview",
    core_color_r = MOD_PREFIX .. "core-color-r",
    core_color_g = MOD_PREFIX .. "core-color-g",
    core_color_b = MOD_PREFIX .. "core-color-b",
    core_color_r_value = MOD_PREFIX .. "core-color-r-value",
    core_color_g_value = MOD_PREFIX .. "core-color-g-value",
    core_color_b_value = MOD_PREFIX .. "core-color-b-value",
    platform_cores = MOD_PREFIX .. "platform-cores",
    level = MOD_PREFIX .. "level",
    xp = MOD_PREFIX .. "xp",
    xp_bar = MOD_PREFIX .. "xp-bar",
    xp_percent = MOD_PREFIX .. "xp-percent",
    hp = MOD_PREFIX .. "hp",
    shooting_speed = MOD_PREFIX .. "shooting-speed",
    range = MOD_PREFIX .. "range",
    ammo = MOD_PREFIX .. "ammo",
    magazine = MOD_PREFIX .. "magazine",
    ammo_productivity = MOD_PREFIX .. "ammo-productivity",
    ammo_productivity_bar = MOD_PREFIX .. "ammo-productivity-bar",
    ammo_productivity_label = MOD_PREFIX .. "ammo-productivity-label",
    damage = MOD_PREFIX .. "damage",
    dps = MOD_PREFIX .. "dps",
    kills = MOD_PREFIX .. "kills",
    damage_dealt = MOD_PREFIX .. "damage-dealt",
    stats = MOD_PREFIX .. "stats",
    stats_scroll = MOD_PREFIX .. "stats-scroll",
    dev = MOD_PREFIX .. "dev",
    skill_points = MOD_PREFIX .. "skill-points",
    evolution_summary = MOD_PREFIX .. "evolution-summary",
    evolution = MOD_PREFIX .. "evolution",
    active_elements = MOD_PREFIX .. "active-elements",
    active_specialization = MOD_PREFIX .. "active-specialization",
    active_sub_specialization = MOD_PREFIX .. "active-sub-specialization",
    active_combo = MOD_PREFIX .. "active-combo",
    element_progress_bar = MOD_PREFIX .. "element-progress-bar",
  }

  GATES = DOMAIN.gates

  SHIELD_PER_RANK = DOMAIN.shield_per_rank
  SHIELD_RECHARGE_DELAY_TICKS = 60 * 5
  SHIELD_RECHARGE_TICKS = 5
  SHIELD_RECHARGE_FRACTION_PER_SECOND = 0.15
  RESISTANCE_PER_RANK = 0.0025
  RESISTANCE_MAX = 0.60
  RESISTANCE_MAX_RANK = math.floor(RESISTANCE_MAX / RESISTANCE_PER_RANK)
  AMMO_PRODUCTIVITY_PER_RANK = 0.01
  REPAIR_MAX_HEALTH_FRACTION_PER_RANK = 0.01
  SHIELD_ON_HIT_FRACTION_PER_RANK = 0.04
  ELEMENT_FREE_RANK = DOMAIN.element_free_rank
  FEEDER_INSERTER_RADIUS = 8
  FEEDER_INPUT_BUFFER_SLOTS = 100

  BASE_UPGRADES = {
    {
      id = "damage",
      sprite = "item/firearm-magazine",
      name = "Damage",
      description = "+0.5 damage per shot per rank.",
      value = "+0.5 / shot",
      effect = "damage",
    },
    {
      id = "resistance",
      sprite = "item/heavy-armor",
      name = "Resistance",
      description = "-0.25% final damage taken per rank, up to 60%. Lethal hits are not refunded.",
      value = "-0.25% taken",
      effect = "resistance",
      max_rank = RESISTANCE_MAX_RANK,
    },
    {
      id = "shield",
      sprite = "item/energy-shield-equipment",
      name = "Shield",
      description = "+10 shield per rank. Shield absorbs damage before HP and recharges smoothly after a short delay without incoming damage.",
      value = "+10 shield",
      effect = "shield",
    },
    {
      id = "ammo_regen",
      sprite = "item/piercing-rounds-magazine",
      name = "Ammo productivity",
      description = "+1% raw magazine productivity per rank. Raw productivity has diminishing returns for refill progress, so it can keep scaling without reaching free ammo.",
      value = "+1%",
      effect = "ammo_regen",
    },
    {
      id = "crit_chance",
      sprite = "item/submachine-gun",
      name = "Crit chance",
      description = "+0.25% critical hit chance per rank.",
      value = "+0.25%",
      effect = "crit_chance",
    },
    {
      id = "crit_damage",
      sprite = "item/electronic-circuit",
      name = "Crit damage",
      description = "+1% critical hit damage per rank.",
      value = "+1%",
      effect = "crit_damage",
    },
  }

  BASE_UPGRADE_BY_ID = {}
  for _, upgrade in ipairs(BASE_UPGRADES) do
    BASE_UPGRADE_BY_ID[upgrade.id] = upgrade
  end

  ELEMENTS = DOMAIN.elements
  ELEMENT_BY_ID = DOMAIN.element_by_id
  SPECIALIZATIONS = DOMAIN.specializations
  SPECIALIZATION_BY_ID = DOMAIN.specialization_by_id
  SUB_SPECIALIZATIONS = DOMAIN.sub_specializations
  SUB_SPECIALIZATION_BY_ID = DOMAIN.sub_specialization_by_id
  SUB_SPECIALIZATIONS_BY_PARENT = DOMAIN.sub_specializations_by_parent

  AUGMENTS = {
    {
      id = "repair",
      sprite = "item/repair-pack",
      name = "Regeneration",
      value = "+1% max HP/s",
      description = "+1% of max HP per second as passive repair per rank.",
    },
    {
      id = "bounce",
      sprite = "item/piercing-rounds-magazine",
      name = "Bullet bounce",
      value = "+5% bounce chance",
      description = "+5% chance per rank for a shot to bounce to a nearby enemy.",
    },
    {
      id = "double_shot",
      sprite = "item/firearm-magazine",
      name = "Double shot",
      value = "+4% double-shot chance",
      description = "+4% chance per rank to fire a second shot at the same target.",
    },
    {
      id = "siphon",
      sprite = "item/energy-shield-equipment",
      name = "Shield on hit",
      value = "+4% damage as shield",
      description = "+4% of gun-turret damage dealt per rank as shield, up to current Shield capacity.",
    },
    {
      id = "luck",
      sprite = "virtual-signal/signal-anything",
      name = "Luck",
      value = "+5% proc odds",
      description = "+5% relative chance per rank for crits, bounce, double shot, and element procs.",
    },
    {
      id = "veteran_training",
      sprite = "item/automation-science-pack",
      name = "Veteran training",
      value = "+5% combat XP",
      description = "+5% combat XP gained per rank.",
    },
  }

  AUGMENT_BY_ID = {}
  for _, augment in ipairs(AUGMENTS) do
    AUGMENT_BY_ID[augment.id] = augment
  end

  SETTINGS = {
    xp_per_damage = MOD_PREFIX .. "xp-per-damage",
    xp_per_kill_credit = MOD_PREFIX .. "xp-per-kill-credit",
    level_base_xp = MOD_PREFIX .. "level-base-xp",
    level_growth = MOD_PREFIX .. "level-growth",
  }

  DEFAULTS = {
    xp_per_damage = 0.02,
    xp_per_kill_credit = 25,
    level_base_xp = 100,
    level_growth = 1.65,
  }

  COLOR = {
    caption = { 0.62, 0.62, 0.62 },
    muted = { 0.74, 0.74, 0.74 },
    bonus = { 0.55, 0.82, 0.55 },
    penalty = { 0.95, 0.50, 0.48 },
    label_presets = label_colors.presets,
  }

  REFRESH_TICKS = 60
  TARGET_DAMAGE_TTL = 60 * 60 * 5
  FEEDER_CONSUME_LIMIT = 100
  COMBAT_CONSTANTS = {
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
  LAYOUT = {
    column_spacing = 8,
    left_column_width = 380,
    evolution_column_width = 430,
    evolution_outer_height = 760,
    evolution_header_height = 36,
    stats_height = 360,
    stats_value_width = 190,
  }
  LAYOUT.panel_width = LAYOUT.left_column_width + LAYOUT.evolution_column_width + LAYOUT.column_spacing
  LAYOUT.panel_max_width = LAYOUT.panel_width + 24
  LAYOUT.stats_scroll_width = LAYOUT.left_column_width - 16
  LAYOUT.stats_content_width = LAYOUT.stats_scroll_width - 30
  LAYOUT.evolution_scroll_width = LAYOUT.evolution_column_width
  LAYOUT.evolution_scroll_height = LAYOUT.evolution_outer_height - LAYOUT.evolution_header_height
  LAYOUT.evolution_content_width = LAYOUT.evolution_scroll_width - 28
  LAYOUT.evolution_section_margin = 6
  LAYOUT.evolution_section_width = LAYOUT.evolution_content_width - (LAYOUT.evolution_section_margin * 2)
  LAYOUT.evolution_inner_width = LAYOUT.evolution_section_width - 16
  LAYOUT.evolution_card_inner_width = LAYOUT.evolution_inner_width - 28
  LAYOUT.evolution_detail_width = LAYOUT.evolution_inner_width - 96
  LAYOUT.evolution_effect_width = LAYOUT.evolution_inner_width - 64
  LAYOUT.element_mastery_icon_width = 36
  LAYOUT.element_mastery_action_width = 96
  LAYOUT.element_mastery_label_width = LAYOUT.evolution_inner_width
    - LAYOUT.element_mastery_icon_width
    - LAYOUT.element_mastery_action_width
    - 40
  compat = nil
  safe_read = nil
  build_turret_gui = nil
  destroy_name_render = nil
  destroy_shield_bar_render = nil
  shield_bar_visible_for_damage = nil
  update_shield_bar_render = nil
  get_element_effect_summary = nil
  get_combo_caption = nil
  get_unique_active_element_ids = nil
  element_name = nil
  get_platform_hub_inventory = nil
  feeder = {}
  combat = {}
end
