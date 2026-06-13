local formatters = {}

function formatters.new(deps)
  local COLOR = deps.COLOR
  local ELEMENT_BY_ID = deps.ELEMENT_BY_ID
  local apply_luck_to_chance = deps.apply_luck_to_chance
  local ensure_evolution_state = deps.ensure_evolution_state
  local format_number = deps.format_number
  local format_percent = deps.format_percent
  local rich_color = deps.rich_color
  local color_to_rich_string = deps.color_to_rich_string

  local effect_labels = {
    ammo_productivity = { "turret-xp.effect-ammo-productivity" },
    attack_speed = { "turret-xp.effect-attack-speed" },
    crit_chance = { "turret-xp.effect-crit-chance" },
    crit_damage = { "turret-xp.effect-crit-damage" },
    damage = { "turret-xp.effect-damage" },
    double_shot = { "turret-xp.effect-double-shot" },
    hp = { "turret-xp.effect-hp" },
    lifesteal = { "turret-xp.effect-lifesteal" },
    range = { "turret-xp.effect-range" },
    regeneration = { "turret-xp.effect-regeneration" },
    resistance = { "turret-xp.effect-resistance" },
  }

  local function effect_label(key)
    return effect_labels[key] or key
  end

  local function element_name(element_id)
    local element = ELEMENT_BY_ID[element_id]
    return element and element.name or { "turret-xp.evolution-summary-none" }
  end

  local function element_name_lower(element_id)
    local element = ELEMENT_BY_ID[element_id]
    if element and element.name_lower then
      return element.name_lower
    end

    local name = element_name(element_id)
    return type(name) == "string" and string.lower(name) or name
  end

  local function get_combo_caption_for_pair(first, second)
    if not first or not second then
      return { "turret-xp.combo-none" }
    end

    if first == second then
      return { "turret-xp.combo-pure", element_name(first), element_name_lower(first) }
    end

    local key = first < second and (first .. "+" .. second) or (second .. "+" .. first)
    local combos = {
      ["electric+fire"] = { "turret-xp.combo-stormfire" },
      ["electric+explosive"] = { "turret-xp.combo-shockburst" },
      ["explosive+fire"] = { "turret-xp.combo-incendiary" },
      ["fire+toxic"] = { "turret-xp.combo-choking" },
      ["electric+toxic"] = { "turret-xp.combo-neuroshock" },
      ["explosive+toxic"] = { "turret-xp.combo-contaminated" },
    }

    return combos[key] or { "turret-xp.combo-generic", element_name(first), element_name(second) }
  end

  local function get_combo_caption(state)
    local evolution = ensure_evolution_state(state)
    return get_combo_caption_for_pair(evolution.elements[1], evolution.elements[2])
  end

  local function get_element_proc_chance_for_rank(state, rank)
    rank = math.max(0, math.floor(tonumber(rank) or 0))
    if rank <= 0 then
      return 0
    end
    return apply_luck_to_chance(state, math.min(0.60, 0.10 + (rank * 0.02)))
  end

  local function get_element_multiplier_for_rank(rank)
    rank = math.max(0, math.floor(tonumber(rank) or 0))
    if rank <= 0 then
      return 0
    end
    return 1 + ((rank - 1) * 0.18)
  end

  local function get_element_arc_count_for_rank(rank)
    rank = math.max(0, math.floor(tonumber(rank) or 0))
    if rank <= 0 then
      return 0
    end
    return math.min(5, rank)
  end

  local function get_element_effect_summary_for_rank(state, element_id, rank, rich, color_terms)
    rank = math.max(0, math.floor(tonumber(rank) or 0))
    if rank <= 0 then
      return nil
    end

    local chance = format_percent(get_element_proc_chance_for_rank(state, rank), 1)
    local multiplier = get_element_multiplier_for_rank(rank)
    local value_color = "0.58,0.82,0.38"
    local fire_color = "1,0.42,0.16"
    local electric_color = "0.35,0.75,1"
    local explosive_color = "1,0.68,0.22"
    local toxic_color = "0.42,0.92,0.28"
    local function value(text, color)
      return rich and rich_color(color or value_color, text) or tostring(text)
    end

    if element_id == "fire" then
      return {
        "turret-xp.element-effect-fire",
        value(chance),
        value(format_number(10 * multiplier, 1) .. "%", fire_color),
        value(format_number(25 * multiplier, 1) .. "%", fire_color),
      }
    end

    if element_id == "electric" then
      local arcs = get_element_arc_count_for_rank(rank)
      return {
        arcs == 1 and "turret-xp.element-effect-electric-one" or "turret-xp.element-effect-electric-many",
        value(chance),
        value(arcs),
        value(format_number(25 * multiplier, 1) .. "%", electric_color),
      }
    end

    if element_id == "explosive" then
      local splash_radius = 3 + math.min(3, rank * 0.15)
      return {
        "turret-xp.element-effect-explosive",
        value(chance),
        value(format_number(20 * multiplier, 1) .. "%", explosive_color),
        value(format_number(splash_radius, 1)),
      }
    end

    if element_id == "toxic" then
      return {
        "turret-xp.element-effect-toxic",
        value(chance),
        value(format_number(8 * multiplier, 1) .. "%", toxic_color),
      }
    end

    return { "turret-xp.element-effect-generic", value(chance) }
  end

  local function format_effect_percent(value, decimals)
    if not value or math.abs(value) < 0.005 then
      return nil
    end

    local color = value < 0 and COLOR.penalty or COLOR.bonus
    return rich_color(color_to_rich_string(color), (value < 0 and "-" or "+") .. format_number(math.abs(value), decimals or 0) .. "%")
  end

  local function format_multiplier_effect_percent(multiplier)
    if not multiplier or math.abs(multiplier - 1) < 0.005 then
      return nil
    end

    return format_effect_percent((multiplier - 1) * 100, 0)
  end

  local function effect_percent_for_entry(entry)
    if entry.kind == "percent" then
      return entry.value * 100
    end

    return (entry.value - 1) * 100
  end

  local function build_specialization_effect_entries(entries)
    local display_entries = {}
    for index, entry in ipairs(entries) do
      local value = tonumber(entry.value)
      local include
      if entry.special then
        include = value ~= nil and value > 0
      elseif entry.kind == "percent" then
        include = value ~= nil and math.abs(value) >= 0.0001
      else
        include = value ~= nil and math.abs(value - 1) >= 0.005
      end

      if include then
        local copy = {
          value = value,
          label = entry.label or effect_label(entry.label_key),
          label_sort = entry.label_sort or entry.label_key or "",
          kind = entry.kind,
          lifesteal = entry.lifesteal == true,
          special = entry.special == true,
          order = entry.order or index,
        }
        copy.effect_percent = effect_percent_for_entry(copy)
        display_entries[#display_entries + 1] = copy
      end
    end

    table.sort(display_entries, function(a, b)
      if a.special ~= b.special then
        return a.special
      end
      if a.special then
        return a.order < b.order
      end

      local a_positive = a.effect_percent > 0
      local b_positive = b.effect_percent > 0
      if a_positive ~= b_positive then
        return a_positive
      end
      if math.abs(a.effect_percent - b.effect_percent) >= 0.005 then
        if a_positive then
          return a.effect_percent > b.effect_percent
        end
        return a.effect_percent < b.effect_percent
      end
      return a.label_sort < b.label_sort
    end)

    return display_entries
  end

  local function specialization_effect_entries(specialization, entity, state, ammo_name)
    if not specialization then
      return {}
    end

    local fire_rate_multiplier = 1 / (specialization.cooldown_multiplier or 1)

    return build_specialization_effect_entries({
      {
        value = specialization.lifesteal_fraction,
        label_key = "lifesteal",
        kind = "percent",
        lifesteal = true,
        special = true,
        order = 1,
      },
      { value = specialization.range_multiplier, label_key = "range", kind = "multiplier" },
      { value = specialization.damage_multiplier, label_key = "damage", kind = "multiplier" },
      { value = specialization.crit_damage_multiplier, label_key = "crit_damage", kind = "multiplier" },
      { value = fire_rate_multiplier, label_key = "attack_speed", kind = "multiplier" },
      { value = specialization.health_multiplier, label_key = "hp", kind = "multiplier" },
      { value = specialization.repair_multiplier, label_key = "regeneration", kind = "multiplier" },
      { value = specialization.ammo_recovery_multiplier, label_key = "ammo_productivity", kind = "multiplier" },
    })
  end

  local function sub_specialization_effect_entries(sub_specialization, entity, state, ammo_name)
    if not sub_specialization then
      return {}
    end

    local fire_rate_multiplier = sub_specialization.cooldown_multiplier and (1 / sub_specialization.cooldown_multiplier) or nil

    return build_specialization_effect_entries({
      { value = sub_specialization.range_multiplier, label_key = "range", kind = "multiplier" },
      { value = sub_specialization.damage_multiplier, label_key = "damage", kind = "multiplier" },
      { value = sub_specialization.crit_chance_flat, label_key = "crit_chance", kind = "percent" },
      { value = sub_specialization.crit_damage_multiplier, label_key = "crit_damage", kind = "multiplier" },
      { value = sub_specialization.double_shot_chance_flat, label_key = "double_shot", kind = "percent" },
      { value = fire_rate_multiplier, label_key = "attack_speed", kind = "multiplier" },
      { value = sub_specialization.health_multiplier, label_key = "hp", kind = "multiplier" },
      { value = sub_specialization.resistance_flat, label_key = "resistance", kind = "percent" },
      { value = sub_specialization.repair_multiplier, label_key = "regeneration", kind = "multiplier" },
      { value = sub_specialization.ammo_recovery_multiplier, label_key = "ammo_productivity", kind = "multiplier" },
    })
  end

  local function specialization_effect_value_caption(entry)
    if entry.lifesteal then
      return format_number(entry.value * 100, 0) .. "%"
    end
    if entry.kind == "percent" then
      return format_effect_percent(entry.value * 100, 1)
    end

    return format_multiplier_effect_percent(entry.value)
  end

  return {
    build_specialization_effect_entries = build_specialization_effect_entries,
    effect_percent_for_entry = effect_percent_for_entry,
    element_name = element_name,
    element_name_lower = element_name_lower,
    format_effect_percent = format_effect_percent,
    format_multiplier_effect_percent = format_multiplier_effect_percent,
    get_combo_caption = get_combo_caption,
    get_combo_caption_for_pair = get_combo_caption_for_pair,
    get_element_arc_count_for_rank = get_element_arc_count_for_rank,
    get_element_effect_summary_for_rank = get_element_effect_summary_for_rank,
    get_element_multiplier_for_rank = get_element_multiplier_for_rank,
    get_element_proc_chance_for_rank = get_element_proc_chance_for_rank,
    specialization_effect_entries = specialization_effect_entries,
    specialization_effect_value_caption = specialization_effect_value_caption,
    sub_specialization_effect_entries = sub_specialization_effect_entries,
  }
end

return formatters
