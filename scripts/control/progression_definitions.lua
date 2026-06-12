local domain = require("scripts.domain")

local definitions = {}

definitions.gates = domain.gates
definitions.shield_per_rank = domain.shield_per_rank
definitions.shield_recharge_delay_ticks = 60 * 5
definitions.shield_recharge_ticks = 5
definitions.shield_recharge_fraction_per_second = 0.15
definitions.resistance_per_rank = 0.0025
definitions.resistance_max = 0.60
definitions.resistance_max_rank = math.floor(definitions.resistance_max / definitions.resistance_per_rank)
definitions.ammo_productivity_per_rank = 0.01
definitions.repair_max_health_fraction_per_rank = 0.01
definitions.shield_on_hit_fraction_per_rank = 0.04
definitions.element_free_rank = domain.element_free_rank

definitions.base_upgrades = {
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
    max_rank = definitions.resistance_max_rank,
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

definitions.base_upgrade_by_id = {}
for _, upgrade in ipairs(definitions.base_upgrades) do
  definitions.base_upgrade_by_id[upgrade.id] = upgrade
end

definitions.elements = domain.elements
definitions.element_by_id = domain.element_by_id
definitions.specializations = domain.specializations
definitions.specialization_by_id = domain.specialization_by_id
definitions.sub_specializations = domain.sub_specializations
definitions.sub_specialization_by_id = domain.sub_specialization_by_id
definitions.sub_specializations_by_parent = domain.sub_specializations_by_parent

definitions.augments = {
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

definitions.augment_by_id = {}
for _, augment in ipairs(definitions.augments) do
  definitions.augment_by_id[augment.id] = augment
end

definitions.settings = {
  xp_per_damage = domain.names.mod_prefix .. "xp-per-damage",
  xp_per_kill_credit = domain.names.mod_prefix .. "xp-per-kill-credit",
  level_base_xp = domain.names.mod_prefix .. "level-base-xp",
  level_growth = domain.names.mod_prefix .. "level-growth",
}

definitions.defaults = {
  xp_per_damage = 0.02,
  xp_per_kill_credit = 25,
  level_base_xp = 100,
  level_growth = 1.65,
}

return definitions
