local migrations = {}

local function unsigned_int(value)
  return math.max(0, math.floor(tonumber(value) or 0))
end

function migrations.new(deps)
  deps = deps or {}

  local service = {}

  function service.normalize_legacy_element_slots(evolution)
    local elements = evolution and evolution.elements or nil
    if type(elements) ~= "table" or not (elements.first or elements.second) then
      return
    end

    evolution.elements = {
      elements[1] or elements.first,
      elements[2] or elements.second,
    }
  end

  function service.remove_retired_augments(evolution)
    if not evolution or type(evolution.augments) ~= "table" then
      return
    end

    evolution.augments.piercing = nil
    evolution.augments.longshot = nil
    evolution.augments.range = nil
    evolution.augments.max_health = nil
  end

  function service.migrate_moved_base_upgrades(evolution)
    if not evolution or type(evolution.base) ~= "table" then
      return
    end

    evolution.augments = type(evolution.augments) == "table" and evolution.augments or {}

    local function move_scaled(base_id, augment_id, old_ranks_per_new_rank)
      local old_rank = unsigned_int(evolution.base[base_id])
      if old_rank > 0 then
        local migrated_rank = math.max(1, math.ceil(old_rank / old_ranks_per_new_rank))
        evolution.augments[augment_id] = math.max(unsigned_int(evolution.augments[augment_id]), migrated_rank)
      end
      evolution.base[base_id] = nil
    end

    move_scaled("repair", "repair", 10)
    move_scaled("siphon", "siphon", 10)
  end

  function service.migrate_legacy_base_xp_upgrade(evolution)
    if not evolution or type(evolution.base) ~= "table" then
      return
    end

    local legacy_rank = unsigned_int(evolution.base.xp)
    evolution.base.xp = nil
    if legacy_rank <= 0 then
      return
    end

    evolution.augments = type(evolution.augments) == "table" and evolution.augments or {}
    evolution.augments.veteran_training = unsigned_int(evolution.augments.veteran_training) + legacy_rank
  end

  function service.normalize_legacy_element_mastery(mastery)
    if type(mastery) ~= "table" then
      return
    end

    mastery.fuel = nil
    mastery.burn_remaining = nil
  end

  function service.migrate_legacy_element_project(state, evolution)
    if not state or not evolution then
      return
    end

    if evolution.element_project ~= nil and type(evolution.element_project) ~= "table" then
      evolution.element_project = nil
      return
    end

    local project = evolution.element_project
    if not project then
      return
    end

    local element = deps.element_by_id and deps.element_by_id[project.element] or nil
    if not element or (project.slot ~= 1 and project.slot ~= 2) then
      evolution.element_project = nil
      return
    end

    project.delivered = type(project.delivered) == "table" and project.delivered or {}
    if project.requirements and project.requirements[1] and project.requirements[1].name ~= element.resource then
      local old_delivered = 0
      for _, requirement in ipairs(project.requirements) do
        old_delivered = old_delivered + unsigned_int(project.delivered[requirement.name])
      end
      project.delivered = {
        [element.resource] = old_delivered,
      }
    end

    local mastery = evolution.element_mastery and evolution.element_mastery[project.element] or nil
    if not project.target_rank then
      local current_rank = mastery and (mastery.rank or 0) or 0
      project.target_rank = current_rank > 0 and (current_rank + 1) or deps.element_free_rank
    end
    project.target_rank = math.max(deps.element_free_rank or 1, math.floor(tonumber(project.target_rank) or (deps.element_free_rank or 1)))
    project.requirements = deps.get_element_requirements(element, project.target_rank)
    for _, requirement in ipairs(project.requirements) do
      project.delivered[requirement.name] = unsigned_int(project.delivered[requirement.name])
    end

    if mastery then
      local delivered = project.delivered[element.resource] or 0
      if (mastery.rank or 0) <= 0 and project.target_rank <= (deps.element_free_rank or 1) then
        evolution.elements[project.slot] = project.element
        mastery.rank = deps.element_free_rank or 1
      elseif delivered > 0 then
        mastery.delivered = unsigned_int(mastery.delivered) + delivered
      end
    end

    local migrated_element = project.element
    evolution.element_project = nil
    deps.advance_element_mastery_if_ready(state, migrated_element)
  end

  function service.migrate_legacy_skills(state, evolution)
    if not state or not evolution or type(state.skills) ~= "table" then
      return
    end

    if evolution.migrated_legacy_skills then
      state.skills = nil
      return
    end

    evolution.base = type(evolution.base) == "table" and evolution.base or {}
    evolution.augments = type(evolution.augments) == "table" and evolution.augments or {}
    evolution.base.damage = unsigned_int(evolution.base.damage) + unsigned_int(state.skills.ballistics)
    evolution.augments.veteran_training = unsigned_int(evolution.augments.veteran_training)
      + unsigned_int(state.skills.kill_chain)
      + unsigned_int(state.skills.targeting_data)
    evolution.augments.repair = unsigned_int(evolution.augments.repair) + unsigned_int(state.skills.field_repairs)
    evolution.migrated_legacy_skills = true
    state.skills = nil
  end

  return service
end

return migrations
