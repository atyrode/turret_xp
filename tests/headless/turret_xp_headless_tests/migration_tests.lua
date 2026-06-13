local support = require("support")

local assert_eq = support.assert_eq
local call = support.call

local tests = {}
function tests.run_legacy_migration_test()
  local skills = call("normalize_profile_snapshot", {
    skills = {
      ballistics = 2,
      kill_chain = 3,
      targeting_data = 4,
      field_repairs = 1,
    },
    evolution = {},
  })
  assert_eq(skills.evolution.base.damage, 2, "legacy Ballistics skill did not migrate into Damage")
  assert_eq(skills.evolution.base.xp, nil, "legacy XP skills left a dead base XP rank")
  assert_eq(skills.evolution.augments.veteran_training, 7, "legacy XP skills did not migrate into Veteran Training")
  assert_eq(skills.evolution.augments.repair, 1, "legacy Field Repairs skill did not migrate into Regeneration")
  assert_eq(skills.evolution.migrated_legacy_skills, true, "legacy skill migration was not marked complete")

  local skills_again = call("normalize_profile_snapshot", {
    skills = {
      ballistics = 2,
      kill_chain = 3,
      targeting_data = 4,
      field_repairs = 1,
    },
    evolution = {
      base = skills.evolution.base,
      augments = skills.evolution.augments,
      migrated_legacy_skills = true,
    },
  })
  assert_eq(skills_again.evolution.base.damage, 2, "legacy skill migration was not idempotent for Damage")
  assert_eq(skills_again.evolution.base.xp, nil, "legacy XP base rank persisted after idempotent migration")
  assert_eq(skills_again.evolution.augments.veteran_training, 7, "legacy skill migration was not idempotent for Veteran Training")
  assert_eq(skills_again.evolution.augments.repair, 1, "legacy skill migration was not idempotent for Regeneration")

  local legacy_base_xp = call("normalize_profile_snapshot", {
    evolution = {
      base = {
        xp = 4,
      },
      augments = {
        veteran_training = 2,
      },
    },
  })
  assert_eq(legacy_base_xp.evolution.base.xp, nil, "legacy base XP rank was not removed")
  assert_eq(legacy_base_xp.evolution.augments.veteran_training, 6, "legacy base XP rank was not moved to Veteran Training")

  local moved_base = call("normalize_profile_snapshot", {
    evolution = {
      base = {
        repair = 11,
        siphon = 12,
      },
    },
  })
  assert_eq(moved_base.evolution.base.repair, nil, "retired base Regeneration rank was not removed")
  assert_eq(moved_base.evolution.base.siphon, nil, "retired base Lifesteal rank was not removed")
  assert_eq(moved_base.evolution.augments.repair, 2, "retired base Regeneration did not migrate to augment ranks")
  assert_eq(moved_base.evolution.augments.siphon, 2, "retired base Lifesteal did not migrate to Shield on Hit augment ranks")

  local tagged = call("deserialize_profile_snapshot", {
    schema = 1,
    level = 50,
    evolution = {
      augments = {
        piercing = 4,
        longshot = 3,
        range = 2,
        max_health = 5,
      },
      elements = {
        first = "fire",
        second = "explosive",
      },
      element_mastery = {
        fire = {
          rank = 2,
          delivered = 12,
          fuel = 99,
          burn_remaining = 30,
        },
        explosive = {
          rank = 1,
          delivered = 8,
          fuel = 4,
        },
      },
    },
  })
  assert_eq(tagged.evolution.elements[1], "fire", "legacy first element tag did not migrate to slot 1")
  assert_eq(tagged.evolution.elements[2], "explosive", "legacy second element tag did not migrate to slot 2")
  assert_eq(tagged.evolution.augments.range, nil, "retired Range augment was not removed")
  assert_eq(tagged.evolution.augments.max_health, nil, "retired Max HP augment was not removed")
  assert_eq(tagged.evolution.augments.piercing, nil, "retired Piercing augment was not removed")
  assert_eq(tagged.evolution.augments.longshot, nil, "retired Longshot augment was not removed")
  assert_eq(tagged.evolution.element_mastery.fire.rank, 2, "legacy Fire mastery rank was not preserved")
  assert_eq(tagged.evolution.element_mastery.fire.delivered, 12, "legacy Fire delivered material was not preserved")
  assert_eq(tagged.evolution.element_mastery.fire.fuel, nil, "legacy Fire fuel buffer was not removed")
  assert_eq(tagged.evolution.element_mastery.fire.burn_remaining, nil, "legacy Fire burn state was not removed")

  local free_pick = call("normalize_profile_snapshot", {
    evolution = {
      element_project = {
        slot = 1,
        element = "fire",
        target_rank = 1,
        delivered = {},
        requirements = {},
      },
    },
  })
  assert_eq(free_pick.evolution.elements[1], "fire", "legacy free element project did not assign the element")
  assert_eq(free_pick.evolution.element_mastery.fire.rank, 1, "legacy free element project did not grant free rank")
  assert_eq(free_pick.evolution.element_project, nil, "legacy free element project was not removed")

  local renamed_materials = call("normalize_profile_snapshot", {
    evolution = {
      elements = { "electric" },
      element_mastery = {
        electric = {
          rank = 1,
          delivered = 4,
        },
      },
      element_project = {
        slot = 1,
        element = "electric",
        target_rank = 2,
        requirements = {
          { name = "copper-cable", count = 100 },
          { name = "iron-plate", count = 100 },
        },
        delivered = {
          ["copper-cable"] = 7,
          ["iron-plate"] = 5,
        },
      },
    },
  })
  assert_eq(renamed_materials.evolution.element_project, nil, "legacy renamed-resource project was not removed")
  assert_eq(renamed_materials.evolution.element_mastery.electric.rank, 1, "partial legacy project unexpectedly ranked Electric")
  assert_eq(
    renamed_materials.evolution.element_mastery.electric.delivered,
    16,
    "legacy renamed resources did not migrate into delivered progress"
  )

  local completed_project = call("normalize_profile_snapshot", {
    evolution = {
      elements = { "explosive" },
      element_mastery = {
        explosive = {
          rank = 1,
          delivered = 0,
        },
      },
      element_project = {
        slot = 1,
        element = "explosive",
        target_rank = 2,
        requirements = {
          { name = "grenade", count = 500 },
        },
        delivered = {
          grenade = 500,
        },
      },
    },
  })
  assert_eq(completed_project.evolution.element_project, nil, "completed legacy project was not removed")
  assert_eq(completed_project.evolution.element_mastery.explosive.rank, 2, "completed legacy project did not advance rank")
  assert_eq(
    completed_project.evolution.element_mastery.explosive.delivered,
    0,
    "completed legacy project did not consume delivered materials"
  )

  local invalid_project = call("normalize_profile_snapshot", {
    evolution = {
      element_project = true,
    },
  })
  assert_eq(invalid_project.evolution.element_project, nil, "invalid legacy project value was not removed")

  local serialized = call("serialize_profile_snapshot", {
    skills = {
      kill_chain = 2,
      targeting_data = 1,
    },
    evolution = {
      base = {
        xp = 4,
      },
      element_project = {
        slot = 1,
        element = "fire",
        target_rank = 1,
        delivered = {},
        requirements = {},
      },
    },
  })
  assert_eq(serialized.skills, nil, "serialized current profile should not include legacy skills")
  assert_eq(serialized.evolution.base.xp, nil, "serialized current profile should not include legacy base XP")
  assert_eq(serialized.evolution.augments.veteran_training, 7, "serialized profile lost legacy XP conversion")
  assert_eq(serialized.evolution.element_project, nil, "serialized current profile should not include legacy element project")
end

return tests
