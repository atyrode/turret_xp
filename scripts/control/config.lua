return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

MOD_PREFIX = "turret-xp-"
CHIP_NAME = "turret-xp-veteran-core"
BOUND_TURRET_NAME = "turret-xp-bound-gun-turret"
BOUND_TURRET_PLACEHOLDER_NAME = "turret-xp-bound-gun-turret-placeholder"
BOUND_TURRET_VARIANT_PREFIX = BOUND_TURRET_NAME .. "-"
BOUND_TURRET_PLACEHOLDER_VARIANT_PREFIX = BOUND_TURRET_PLACEHOLDER_NAME .. "-"
FEEDER_NAME = "turret-xp-veteran-feeder"
LABEL_PANEL_PREFIX = "turret-xp-label-panel-"
PROFILE_TAG = "turret_xp_profile"
BOUND_TURRET_TAG = "turret_xp_bound_turret"
BASE_TURRET_NAME = "gun-turret"
SPECIALIZED_TURRET_PREFIX = "turret-xp-gun-turret-"

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
  element_project = MOD_PREFIX .. "element-project",
  element_project_bar = MOD_PREFIX .. "element-project-bar"
}

GATES = {
  specialization = 10,
  first_element = 20,
  augments = 30,
  sub_specialization = 40,
  second_element = 50
}

RANGE_AUGMENT_MAX = 20
MAX_HEALTH_AUGMENT_MAX = 20
MAX_HEALTH_PER_RANK = 50
RESISTANCE_PER_RANK = 0.0025
RESISTANCE_MAX = 0.60
RESISTANCE_MAX_RANK = math.floor(RESISTANCE_MAX / RESISTANCE_PER_RANK)
AMMO_REGEN_TICKS_PER_ROUND = 60 * 60
REPAIR_MAX_HEALTH_FRACTION_PER_RANK = 0.001
ELEMENT_FREE_RANK = 1
FEEDER_INSERTER_RADIUS = 8
FEEDER_INPUT_BUFFER_SLOTS = 100
LABEL_CUSTOM_COLOR_STEPS = 5

BASE_UPGRADES = {
  {
    id = "damage",
    sprite = "item/firearm-magazine",
    name = "Damage",
    description = "+0.5 damage per shot per rank.",
    value = "+0.5 / shot",
    effect = "damage"
  },
  {
    id = "repair",
    sprite = "item/repair-pack",
    name = "Regeneration",
    description = "+0.1% of max HP per second as passive repair per rank.",
    value = "+0.1% max HP/s",
    effect = "repair"
  },
  {
    id = "resistance",
    sprite = "item/heavy-armor",
    name = "Resistance",
    description = "-0.25% final damage taken per rank, up to 60%. Lethal hits are not refunded.",
    value = "-0.25% taken",
    effect = "resistance",
    max_rank = RESISTANCE_MAX_RANK
  },
  {
    id = "ammo_regen",
    sprite = "item/piercing-rounds-magazine",
    name = "Ammo recovery",
    description = "Recovers 1 loaded or remembered ammo item per minute per rank.",
    value = "+1 / min",
    effect = "ammo_regen"
  },
  {
    id = "siphon",
    sprite = "item/steel-plate",
    name = "Lifesteal",
    description = "Heals for 0.4% of gun-turret damage dealt per rank.",
    value = "+0.4%",
    effect = "siphon"
  },
  {
    id = "crit_chance",
    sprite = "item/submachine-gun",
    name = "Crit chance",
    description = "+0.25% critical hit chance per rank.",
    value = "+0.25%",
    effect = "crit_chance"
  },
  {
    id = "crit_damage",
    sprite = "item/electronic-circuit",
    name = "Crit damage",
    description = "+1% critical hit damage per rank.",
    value = "+1%",
    effect = "crit_damage"
  }
}

BASE_UPGRADE_BY_ID = {}
for _, upgrade in ipairs(BASE_UPGRADES) do
  BASE_UPGRADE_BY_ID[upgrade.id] = upgrade
end

ELEMENTS = {
  {
    id = "explosive",
    sprite = "virtual-signal/signal-explosion",
    name = "Explosive",
    description = "Shots can splash explosion damage around the target.",
    resource = "grenade",
    base_requirement = 500
  },
  {
    id = "fire",
    sprite = "virtual-signal/signal-fire",
    name = "Fire",
    description = "Shots can add fire damage and power incendiary combos.",
    resource = "sulfur",
    base_requirement = 2500
  },
  {
    id = "electric",
    sprite = "virtual-signal/signal-lightning",
    name = "Electric",
    description = "Shots can arc electric damage to a nearby enemy.",
    resource = "battery",
    base_requirement = 750
  },
  {
    id = "toxic",
    sprite = "item/poison-capsule",
    name = "Toxic",
    description = "Shots can stack poison damage over time and slow targets.",
    resource = "poison-capsule",
    base_requirement = 150
  }
}

ELEMENT_BY_ID = {}
for _, element in ipairs(ELEMENTS) do
  ELEMENT_BY_ID[element.id] = element
end

SPECIALIZATIONS = {
  {
    id = "sniper",
    sprite = "entity/radar",
    name = "Sniper",
    range_multiplier = 1.8889,
    cooldown_multiplier = 4.0,
    damage_multiplier = 2.8,
    health_multiplier = 0.875,
    crit_damage_multiplier = 1.8,
    value = "x1.89 range, x2.8 damage, x0.25 fire rate, x1.8 crit damage, x0.88 HP",
    description = "Very high range and shot damage, stronger critical hits, extremely slow fire rate, lower durability."
  },
  {
    id = "machine_gun",
    sprite = "item/submachine-gun",
    name = "Machine gun",
    range_multiplier = 0.8889,
    cooldown_multiplier = 0.5,
    damage_multiplier = 0.58,
    health_multiplier = 0.9,
    ammo_recovery_multiplier = 2.0,
    value = "x2 fire rate, x2 ammo recovery, x0.58 damage, x0.89 range, x0.9 HP",
    description = "Much faster fire rate and ammo recovery, slightly shorter range, lower shot damage."
  },
  {
    id = "bulwark",
    sprite = "item/stone-wall",
    name = "Bulwark",
    range_multiplier = 0.9445,
    cooldown_multiplier = 1.3334,
    damage_multiplier = 0.65,
    health_multiplier = 3.0,
    repair_multiplier = 2.5,
    value = "x3 HP, x2.5 regeneration, x0.65 damage, x0.75 fire rate",
    description = "Triple durability and stronger regeneration, lower shot damage, slightly shorter range."
  },
  {
    id = "brawler",
    sprite = "item/shotgun",
    name = "Brawler",
    range_multiplier = 0.3889,
    cooldown_multiplier = 2.0,
    damage_multiplier = 3.0,
    health_multiplier = 1.625,
    lifesteal_multiplier = 2.5,
    value = "x3 damage, x2.5 lifesteal, x0.5 fire rate, x0.39 range, x1.63 HP",
    description = "Very short range, high shot damage, stronger lifesteal and durability, slower fire rate."
  }
}

SPECIALIZATION_BY_ID = {}
for _, specialization in ipairs(SPECIALIZATIONS) do
  SPECIALIZATION_BY_ID[specialization.id] = specialization
end

SUB_SPECIALIZATIONS = {
  {
    id = "sniper_deadeye",
    parent = "sniper",
    sprite = "item/piercing-rounds-magazine",
    name = "Deadeye",
    crit_chance_flat = 0.08,
    crit_damage_multiplier = 1.25,
    damage_multiplier = 1.08,
    value = "+8% crit chance, x1.25 crit damage, x1.08 damage",
    description = "Turns Sniper into a precision killer that leans harder into critical shots."
  },
  {
    id = "sniper_overwatch",
    parent = "sniper",
    sprite = "entity/radar",
    name = "Overwatch",
    range_multiplier = 1.18,
    cooldown_multiplier = 1.15,
    damage_multiplier = 1.08,
    value = "x1.18 range, x1.08 damage, x0.87 fire rate",
    description = "Pushes Sniper further into extreme range at the cost of an even slower firing rhythm."
  },
  {
    id = "machine_shredder",
    parent = "machine_gun",
    sprite = "item/firearm-magazine",
    name = "Shredder",
    double_shot_chance_flat = 0.12,
    damage_multiplier = 0.92,
    value = "+12% double-shot chance, x0.92 damage",
    description = "Trades some shot weight for more frequent burst fire."
  },
  {
    id = "machine_sustained",
    parent = "machine_gun",
    sprite = "item/piercing-rounds-magazine",
    name = "Sustained fire",
    cooldown_multiplier = 0.85,
    ammo_recovery_multiplier = 1.75,
    value = "x1.18 fire rate, x1.75 ammo recovery",
    description = "Improves sustained uptime by firing faster and recovering ammunition more aggressively."
  },
  {
    id = "bulwark_bastion",
    parent = "bulwark",
    sprite = "item/concrete",
    name = "Bastion",
    health_multiplier = 1.35,
    resistance_flat = 0.05,
    cooldown_multiplier = 1.10,
    value = "x1.35 HP, +5% resistance, x0.91 fire rate",
    description = "Commits Bulwark to holding ground through raw durability and extra mitigation."
  },
  {
    id = "bulwark_guardian",
    parent = "bulwark",
    sprite = "item/repair-pack",
    name = "Guardian",
    repair_multiplier = 1.80,
    range_multiplier = 1.08,
    value = "x1.8 regeneration, x1.08 range",
    description = "Turns Bulwark into a steadier protector with stronger self-repair and a little more reach."
  },
  {
    id = "brawler_executioner",
    parent = "brawler",
    sprite = "item/shotgun",
    name = "Executioner",
    damage_multiplier = 1.35,
    crit_damage_multiplier = 1.35,
    lifesteal_multiplier = 0.80,
    value = "x1.35 damage, x1.35 crit damage, x0.8 lifesteal",
    description = "Makes Brawler more lethal at close range while softening its sustain."
  },
  {
    id = "brawler_vampire",
    parent = "brawler",
    sprite = "item/steel-plate",
    name = "Vampire",
    lifesteal_multiplier = 1.80,
    health_multiplier = 1.18,
    damage_multiplier = 0.90,
    value = "x1.8 lifesteal, x1.18 HP, x0.9 damage",
    description = "Turns Brawler into a self-sustaining close-range anchor."
  }
}

SUB_SPECIALIZATION_BY_ID = {}
SUB_SPECIALIZATIONS_BY_PARENT = {}
for _, sub_specialization in ipairs(SUB_SPECIALIZATIONS) do
  SUB_SPECIALIZATION_BY_ID[sub_specialization.id] = sub_specialization
  SUB_SPECIALIZATIONS_BY_PARENT[sub_specialization.parent] = SUB_SPECIALIZATIONS_BY_PARENT[sub_specialization.parent] or {}
  table.insert(SUB_SPECIALIZATIONS_BY_PARENT[sub_specialization.parent], sub_specialization)
end

AUGMENTS = {
  {
    id = "bounce",
    sprite = "item/piercing-rounds-magazine",
    name = "Bullet bounce",
    value = "+5% bounce chance",
    description = "+5% chance per rank for a shot to bounce to a nearby enemy."
  },
  {
    id = "double_shot",
    sprite = "item/firearm-magazine",
    name = "Double shot",
    value = "+4% double-shot chance",
    description = "+4% chance per rank to fire a second shot at the same target."
  },
  {
    id = "luck",
    sprite = "virtual-signal/signal-anything",
    name = "Luck",
    value = "+5% proc odds",
    description = "+5% relative chance per rank for crits, bounce, double shot, and element procs."
  },
  {
    id = "veteran_training",
    sprite = "item/automation-science-pack",
    name = "Veteran training",
    value = "+5% combat XP",
    description = "+5% combat XP gained per rank."
  },
  {
    id = "range",
    sprite = "entity/radar",
    name = "Range",
    value = "+1 attack range",
    description = "+1 tile attack range per rank. Max rank 20.",
    max_rank = RANGE_AUGMENT_MAX
  },
  {
    id = "max_health",
    sprite = "item/stone-wall",
    name = "Max HP",
    value = "+50 HP",
    description = "+50 maximum HP per rank. Max rank 20.",
    max_rank = MAX_HEALTH_AUGMENT_MAX
  }
}

AUGMENT_BY_ID = {}
for _, augment in ipairs(AUGMENTS) do
  AUGMENT_BY_ID[augment.id] = augment
end

SETTINGS = {
  xp_per_damage = MOD_PREFIX .. "xp-per-damage",
  xp_per_kill_credit = MOD_PREFIX .. "xp-per-kill-credit",
  level_base_xp = MOD_PREFIX .. "level-base-xp",
  level_growth = MOD_PREFIX .. "level-growth"
}

DEFAULTS = {
  xp_per_damage = 0.02,
  xp_per_kill_credit = 25,
  level_base_xp = 100,
  level_growth = 1.65
}

COLOR = {
  caption = { 0.62, 0.62, 0.62 },
  muted = { 0.74, 0.74, 0.74 },
  bonus = { 0.58, 0.82, 0.38 },
  penalty = { 1.0, 0.36, 0.30 },
  label_presets = {
    { id = "gold", name = "Gold", color = { 1, 0.86, 0.46 } },
    { id = "white", name = "White", color = { 1, 1, 1 } },
    { id = "green", name = "Green", color = { 0.45, 1, 0.45 } },
    { id = "blue", name = "Blue", color = { 0.45, 0.78, 1 } },
    { id = "red", name = "Red", color = { 1, 0.36, 0.30 } },
    { id = "purple", name = "Purple", color = { 0.86, 0.48, 1 } }
  }
}

function label_color_matches(color, preset_color)
  color = color or {}
  return math.abs((color[1] or 0) - preset_color[1]) < 0.01
    and math.abs((color[2] or 0) - preset_color[2]) < 0.01
    and math.abs((color[3] or 0) - preset_color[3]) < 0.01
end

function label_color_preset_by_id(id)
  for _, preset in ipairs(COLOR.label_presets) do
    if preset.id == id then
      return preset
    end
  end

  return nil
end

function label_color_preset_from_color(color)
  for _, preset in ipairs(COLOR.label_presets) do
    if label_color_matches(color, preset.color) then
      return preset
    end
  end

  return nil
end

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
    toxic = "bullet-beam-green-faint"
  },
  vfx = {
    electric_arc = "turret-xp-electric-arc",
    fire_flash = "turret-xp-fire-flash",
    toxic_puff = "turret-xp-toxic-puff"
  },
  sfx = {
    electric = "turret-xp-electric-proc",
    fire = "turret-xp-fire-proc"
  }
}
LAYOUT = {
  column_spacing = 8,
  left_column_width = 380,
  evolution_column_width = 430,
  evolution_outer_height = 760,
  evolution_header_height = 36,
  stats_height = 360,
  stats_value_width = 190
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
safe_read = nil
build_turret_gui = nil
destroy_name_render = nil
get_element_effect_summary = nil
get_combo_caption = nil
get_unique_active_element_ids = nil
element_name = nil
get_platform_hub_inventory = nil
feeder = {}
combat = {}

end
