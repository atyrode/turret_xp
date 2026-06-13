local domain = require("scripts.domain")
local gui_constants = require("scripts.control.gui_constants")
local progression_definitions = require("scripts.control.progression_definitions")
local runtime_constants = require("scripts.control.runtime_constants")

return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  DOMAIN = domain

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

  GUI = gui_constants.gui
  COLOR = gui_constants.color
  LAYOUT = gui_constants.layout

  GATES = progression_definitions.gates
  SHIELD_PER_RANK = progression_definitions.shield_per_rank
  SHIELD_RECHARGE_DELAY_TICKS = progression_definitions.shield_recharge_delay_ticks
  SHIELD_RECHARGE_TICKS = progression_definitions.shield_recharge_ticks
  SHIELD_RECHARGE_FRACTION_PER_SECOND = progression_definitions.shield_recharge_fraction_per_second
  RESISTANCE_PER_RANK = progression_definitions.resistance_per_rank
  RESISTANCE_MAX = progression_definitions.resistance_max
  RESISTANCE_MAX_RANK = progression_definitions.resistance_max_rank
  AMMO_PRODUCTIVITY_PER_RANK = progression_definitions.ammo_productivity_per_rank
  REPAIR_MAX_HEALTH_FRACTION_PER_RANK = progression_definitions.repair_max_health_fraction_per_rank
  SHIELD_ON_HIT_FRACTION_PER_RANK = progression_definitions.shield_on_hit_fraction_per_rank
  ELEMENT_FREE_RANK = progression_definitions.element_free_rank
  BASE_UPGRADES = progression_definitions.base_upgrades
  BASE_UPGRADE_BY_ID = progression_definitions.base_upgrade_by_id
  ELEMENTS = progression_definitions.elements
  ELEMENT_BY_ID = progression_definitions.element_by_id
  SPECIALIZATIONS = progression_definitions.specializations
  SPECIALIZATION_BY_ID = progression_definitions.specialization_by_id
  SUB_SPECIALIZATIONS = progression_definitions.sub_specializations
  SUB_SPECIALIZATION_BY_ID = progression_definitions.sub_specialization_by_id
  SUB_SPECIALIZATIONS_BY_PARENT = progression_definitions.sub_specializations_by_parent
  AUGMENTS = progression_definitions.augments
  AUGMENT_BY_ID = progression_definitions.augment_by_id
  SETTINGS = progression_definitions.settings
  DEFAULTS = progression_definitions.defaults

  REFRESH_TICKS = runtime_constants.refresh_ticks
  TARGET_DAMAGE_TTL = runtime_constants.target_damage_ttl
  FEEDER_INSERTER_RADIUS = runtime_constants.feeder_inserter_radius
  FEEDER_INPUT_BUFFER_SLOTS = runtime_constants.feeder_input_buffer_slots
  FEEDER_CONSUME_LIMIT = runtime_constants.feeder_consume_limit
  COMBAT_CONSTANTS = runtime_constants.combat

  combat = {}
end
