local profile_tags = {}

function profile_tags.new(deps)
  local service = {}

  function service.read_profile_from_chip_stack(stack)
    if not stack or not stack.valid_for_read or stack.name ~= deps.chip_name then
      return nil
    end

    local data = deps.compat.try("read core profile tag", function()
      return stack.get_tag(deps.profile_tag)
    end)

    local profile = deps.deserialize_profile(data)
    profile.chip_quality = deps.quality_name(stack, profile.chip_quality or "normal", "core stack quality")
    return deps.normalize_profile(profile)
  end

  function service.profile_format_rank(rank)
    return tostring(math.max(0, math.floor(tonumber(rank) or 0)))
  end

  function service.profile_join(parts)
    if #parts == 0 then
      return nil
    end

    return table.concat(parts, ", ")
  end

  function service.profile_rank_list(definitions, ranks)
    local parts = {}
    ranks = type(ranks) == "table" and ranks or {}
    for _, definition in ipairs(definitions or {}) do
      local rank = math.max(0, math.floor(tonumber(ranks[definition.id]) or 0))
      if rank > 0 then
        parts[#parts + 1] = definition.name .. " r" .. service.profile_format_rank(rank)
      end
    end

    return service.profile_join(parts)
  end

  function service.profile_element_rank_caption(profile, evolution, element_id)
    local element = deps.element_by_id[element_id]
    if not element then
      return nil
    end

    local mastery = evolution.element_mastery and evolution.element_mastery[element_id] or nil
    local rank = mastery and math.max(0, math.floor(tonumber(mastery.rank) or 0)) or 0
    local caption = element.name .. " r" .. service.profile_format_rank(rank)
    local delivered, required, requirement = deps.get_element_progress(profile, element_id)
    if requirement and required > 0 then
      caption = caption
        .. " ("
        .. service.profile_format_rank(delivered)
        .. "/"
        .. service.profile_format_rank(required)
        .. " [item="
        .. requirement.name
        .. "])"
    end
    return caption
  end

  function service.profile_elements_summary(profile, evolution)
    local parts = {}
    for slot = 1, 2 do
      local caption = service.profile_element_rank_caption(profile, evolution, evolution.elements and evolution.elements[slot] or nil)
      if caption then
        parts[#parts + 1] = caption
      end
    end

    return #parts > 0 and table.concat(parts, " + ") or nil
  end

  function service.profile_specialization_summary(evolution)
    local specialization = evolution.specialization and deps.specialization_by_id[evolution.specialization] or nil
    if not specialization then
      return nil
    end

    local sub_specialization = evolution.sub_specialization and deps.sub_specialization_by_id[evolution.sub_specialization] or nil
    if sub_specialization and sub_specialization.parent == specialization.id then
      return specialization.name .. " / " .. sub_specialization.name
    end

    return specialization.name
  end

  function service.profile_build_lines(profile)
    profile = deps.normalize_profile(profile)
    local evolution = deps.ensure_evolution_state(profile)
    local lines = {}

    local specialization = service.profile_specialization_summary(evolution)
    if specialization then
      lines[#lines + 1] = { "", "[color=1,0.86,0.46]Spec:[/color] ", specialization }
    end

    local elements = service.profile_elements_summary(profile, evolution)
    if elements then
      lines[#lines + 1] = { "", "[color=0.35,0.75,1]Elements:[/color] ", elements }
    end

    local core = service.profile_rank_list(deps.base_upgrades, evolution.base)
    if core then
      lines[#lines + 1] = { "", "[color=0.58,0.82,0.38]Core:[/color] ", core }
    end

    local augments = service.profile_rank_list(deps.augments, evolution.augments)
    if augments then
      lines[#lines + 1] = { "", "[color=0.35,0.75,1]Aug:[/color] ", augments }
    end

    return lines
  end

  function service.profile_description_with_build(base_description, profile)
    local lines = service.profile_build_lines(profile)
    if #lines == 0 then
      return base_description
    end

    local description = { "", base_description, "\n" }
    for index, line in ipairs(lines) do
      if index > 1 then
        description[#description + 1] = "\n"
      end
      description[#description + 1] = line
    end

    return description
  end

  function service.profile_description(profile)
    profile = deps.normalize_profile(profile)
    local name = profile.custom_name or ""
    local base_description
    if name ~= "" then
      base_description = { "item-description.turret-xp-veteran-core-profile-named", name, profile.level or 0 }
    else
      base_description = { "item-description.turret-xp-veteran-core-profile", profile.level or 0 }
    end

    return service.profile_description_with_build(base_description, profile)
  end

  function service.make_chip_item_stack(profile)
    local serialized = deps.serialize_profile(profile)
    return {
      name = deps.chip_name,
      count = 1,
      quality = serialized.chip_quality or "normal",
      tags = {
        [deps.profile_tag] = serialized,
      },
      custom_description = service.profile_description(serialized),
    }
  end

  return service
end

return profile_tags
