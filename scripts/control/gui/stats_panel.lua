local stats_panel = {}

function stats_panel.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local LAYOUT = deps.LAYOUT
  local add_stat_row = deps.add_stat_row
  local add_stats_section_header = deps.add_stats_section_header
  local make_stats_table = deps.make_stats_table
  local add_content_pane = deps.add_content_pane
  local set_style = deps.set_style
  local set_element_style = deps.set_element_style
  local find_gui_element = deps.find_gui_element
  local format_number = deps.format_number
  local format_percent = deps.format_percent
  local rich_number = deps.rich_number
  local rich_color = deps.rich_color
  local color_to_rich_string = deps.color_to_rich_string
  local rich_specialization_caption = deps.rich_specialization_caption
  local format_colored_multiplier = deps.format_colored_multiplier
  local format_stat_formula = deps.format_stat_formula
  local get_base_rank = deps.get_base_rank
  local get_ammo_productivity_fraction = deps.get_ammo_productivity_fraction
  local get_effective_ammo_productivity_fraction = deps.get_effective_ammo_productivity_fraction
  local get_sub_specialization_flat_bonus = deps.get_sub_specialization_flat_bonus
  local get_luck_multiplier = deps.get_luck_multiplier
  local get_crit_chance_fraction = deps.get_crit_chance_fraction
  local get_crit_damage_formula_values = deps.get_crit_damage_formula_values
  local get_augment_rank = deps.get_augment_rank
  local get_shield_on_hit_fraction = deps.get_shield_on_hit_fraction
  local get_lifesteal_rate = deps.get_lifesteal_rate
  local apply_luck_to_chance = deps.apply_luck_to_chance
  local get_double_shot_chance = deps.get_double_shot_chance
  local get_unique_active_element_ids = deps.get_unique_active_element_ids
  local get_element_rank = deps.get_element_rank
  local get_element_effect_summary_for_rank = deps.get_element_effect_summary_for_rank
  local element_name = deps.element_name
  local ensure_evolution_state = deps.ensure_evolution_state
  local get_combo_caption = deps.get_combo_caption
  local get_specialization = deps.get_specialization
  local get_sub_specialization = deps.get_sub_specialization
  local make_quality_tooltip = deps.make_quality_tooltip
  local get_max_health_for_quality = deps.get_max_health_for_quality
  local get_health_formula_values = deps.get_health_formula_values
  local get_repair_per_second = deps.get_repair_per_second
  local get_repair_base_per_second = deps.get_repair_base_per_second
  local get_specialization_multiplier = deps.get_specialization_multiplier
  local normalize_shield_state = deps.normalize_shield_state
  local get_shield_recharge_per_second = deps.get_shield_recharge_per_second
  local get_damage_resistance_fraction = deps.get_damage_resistance_fraction
  local get_shooting_speed_formula_values = deps.get_shooting_speed_formula_values
  local format_shots_per_second = deps.format_shots_per_second
  local format_range_for_quality = deps.format_range_for_quality
  local get_range_formula_values = deps.get_range_formula_values
  local format_range = deps.format_range
  local get_damage_formula_values = deps.get_damage_formula_values
  local format_damage_per_shot = deps.format_damage_per_shot
  local get_estimated_dps_values = deps.get_estimated_dps_values
  local format_estimated_dps_formula = deps.format_estimated_dps_formula

  local function render_ammo_productivity(parent, state)
    parent.clear()
    if not state or get_base_rank(state, "ammo_regen") <= 0 then
      return
    end

    local progress = math.max(0, tonumber(state.ammo_productivity_progress or state.ammo_regen_progress) or 0)
    progress = progress >= 1 and 1 or (progress - math.floor(progress))
    local raw_productivity = get_ammo_productivity_fraction(state)
    local effective_productivity = get_effective_ammo_productivity_fraction(state)
    local caption = "+" .. format_percent(raw_productivity, 0)
    local tooltip = {
      "turret-xp.ammo-productivity-tooltip",
      caption,
      format_percent(effective_productivity, 1),
      format_percent(progress, 0),
    }

    local row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(row, "top_margin", 3)
    set_style(row, "horizontal_spacing", 5)
    set_style(row, "vertical_align", "center")
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "horizontal_align", "right")

    local bar = row.add({
      type = "progressbar",
      name = GUI.ammo_productivity_bar,
      style = "turret_xp_ammo_productivity_progressbar",
      value = progress,
      tooltip = tooltip,
    })
    set_style(bar, "height", 10)
    set_style(bar, "width", 130)
    set_style(bar, "minimal_width", 130)
    set_style(bar, "maximal_width", 130)

    local label = row.add({
      type = "label",
      name = GUI.ammo_productivity_label,
      caption = rich_number(caption, { 0.72, 0.33, 0.95 }),
      tooltip = tooltip,
      style = "caption_label",
    })
    set_style(label, "single_line", true)
    set_style(label, "font_color", COLOR.muted)
  end

  local function render_magazine_stack_flow(flow, ammo_name, ammo_count, ammo_quality)
    flow.clear()
    local slot_row = flow.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(slot_row, "horizontal_align", "right")
    set_style(slot_row, "horizontally_stretchable", true)
    set_style(slot_row, "horizontal_spacing", 6)
    set_style(slot_row, "vertical_align", "center")

    if not ammo_name then
      slot_row.add({
        type = "sprite",
        sprite = "flib_indicator_yellow",
        style = "flib_indicator",
        tooltip = { "turret-xp.no-ammo" },
      })
      return
    end

    local magazine_tooltip = {
      "turret-xp.magazine-stack-tooltip",
      format_number(ammo_count or 0, 0),
    }
    local ok, button = pcall(function()
      return slot_row.add({
        type = "sprite-button",
        sprite = "item/" .. ammo_name,
        quality = ammo_quality or "normal",
        number = ammo_count,
        tooltip = magazine_tooltip,
        elem_tooltip = {
          type = "item-with-quality",
          name = ammo_name,
          quality = ammo_quality or "normal",
        },
      })
    end)

    if ok and button then
      set_element_style(button, "flib_slot_button_green")
      set_style(button, "size", 36)
    end

    if ok and button then
      return
    end

    slot_row.add({
      type = "label",
      caption = string.format("[item=%s] x%d", ammo_name, ammo_count),
    })
  end

  local function render_current_ammo_flow(flow, ammo_in_magazine, ammo_magazine_size)
    flow.clear()
    local row = flow.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(row, "horizontal_align", "right")
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "vertical_align", "center")

    if ammo_in_magazine == nil or not ammo_magazine_size or ammo_magazine_size <= 0 then
      local label = row.add({
        type = "label",
        caption = "-",
        style = "caption_label",
      })
      set_style(label, "font_color", COLOR.muted)
      set_style(label, "single_line", true)
      return
    end

    local label = row.add({
      type = "label",
      caption = format_number(ammo_in_magazine, 0) .. " / " .. format_number(ammo_magazine_size, 0),
      style = "label",
    })
    set_style(label, "single_line", true)
  end

  local function update_ammo_row(panel, ammo_name, ammo_count, ammo_quality, ammo_in_magazine, ammo_magazine_size, state)
    local magazine_flow = find_gui_element(panel, GUI.magazine)
    local ammo_flow = find_gui_element(panel, GUI.ammo)
    if not ammo_flow and not magazine_flow then
      return
    end

    local current_tags = (magazine_flow and magazine_flow.tags) or (ammo_flow and ammo_flow.tags) or {}
    local productivity_progress = state and (state.ammo_productivity_progress or state.ammo_regen_progress) or 0
    local productivity_fraction = state and get_ammo_productivity_fraction(state) or 0
    local effective_productivity_fraction = state and get_effective_ammo_productivity_fraction(state) or 0
    if
      current_tags.ammo_name == (ammo_name or "")
      and current_tags.ammo_count == (ammo_count or 0)
      and current_tags.ammo_quality == (ammo_quality or "")
      and current_tags.ammo_in_magazine == (ammo_in_magazine or -1)
      and current_tags.ammo_magazine_size == (ammo_magazine_size or -1)
      and current_tags.ammo_productivity_progress == productivity_progress
      and current_tags.ammo_productivity_fraction == productivity_fraction
      and current_tags.effective_ammo_productivity_fraction == effective_productivity_fraction
    then
      return
    end

    local tags = {
      ammo_name = ammo_name or "",
      ammo_count = ammo_count or 0,
      ammo_quality = ammo_quality or "",
      ammo_in_magazine = ammo_in_magazine or -1,
      ammo_magazine_size = ammo_magazine_size or -1,
      ammo_productivity_progress = productivity_progress,
      ammo_productivity_fraction = productivity_fraction,
      effective_ammo_productivity_fraction = effective_productivity_fraction,
    }

    if magazine_flow then
      magazine_flow.tags = tags
      render_magazine_stack_flow(magazine_flow, ammo_name, ammo_count, ammo_quality)
    end
    if ammo_flow then
      ammo_flow.tags = tags
      render_current_ammo_flow(ammo_flow, ammo_in_magazine, ammo_magazine_size)
    end

    local productivity_flow = find_gui_element(panel, GUI.ammo_productivity)
    if productivity_flow then
      render_ammo_productivity(productivity_flow, state)
    end
  end

  local function add_stats_panel(parent)
    local _, _, scroll = add_content_pane(parent, {
      top_margin = 8,
      width = LAYOUT.stats_scroll_width,
      header_name = GUI.stats_header,
      header_height = LAYOUT.stats_header_height,
      title = { "turret-xp.stats-title" },
      scroll_name = GUI.stats_scroll,
      scroll_direction = "vertical",
      scroll_width = LAYOUT.stats_scroll_width,
      scroll_height = LAYOUT.stats_height,
      scroll_padding = { 6, 6, 6, 6 },
    })

    return make_stats_table(scroll, GUI.stats)
  end

  local function add_stats_section(stats, caption)
    add_stats_section_header(stats, caption)
    return {
      no_delimiter = true,
    }
  end

  local function add_stat_value(stats, label, value, tooltip, options)
    local _, value_element = add_stat_row(stats, label, nil, {
      info_tooltip = tooltip,
      maximal_width = LAYOUT.stats_value_width,
      no_delimiter = options and options.no_delimiter == true,
    })
    value_element.caption = value
    return value_element
  end

  local function add_custom_stat(stats, label, value, tooltip, options)
    if value == nil or value == "" then
      return
    end

    local _, value_element = add_stat_row(stats, label, nil, {
      info_tooltip = tooltip,
      maximal_width = LAYOUT.stats_value_width,
      value_style = "label",
      no_delimiter = options and options.no_delimiter == true,
    })
    value_element.caption = value
  end

  local function stat_formula_tooltip(description, formula)
    if not formula then
      return description
    end

    return { "", description, "\n", { "turret-xp.stat-formula-tooltip", formula } }
  end

  local function add_stat_value_with_quality_marker(stats, label, value, info_tooltip, quality_tooltip, options)
    local _, value_flow = add_stat_row(stats, label, nil, {
      info_tooltip = info_tooltip,
      flow_only = true,
      no_delimiter = options and options.no_delimiter == true,
    })

    local value_label = value_flow.add({
      type = "label",
      caption = value,
      style = "label",
    })
    set_style(value_label, "single_line", false)
    set_style(value_label, "horizontal_align", "right")
    set_style(value_label, "maximal_width", LAYOUT.stats_value_width - 24)

    if quality_tooltip then
      local marker = value_flow.add({
        type = "label",
        caption = "[img=quality_info]",
        tooltip = quality_tooltip,
        style = "caption_label",
      })
      set_style(marker, "left_margin", 0)
      set_style(marker, "single_line", true)
    end

    return value_label
  end

  local function format_final_stat_value(total, base, suffix, decimals)
    local text = format_number(total, decimals) .. (suffix or "")
    if base and math.abs((total or 0) - base) >= 0.005 then
      local color = total > base and COLOR.bonus or COLOR.penalty
      return rich_color(color_to_rich_string(color), text)
    end

    return text
  end

  local function formula_total_caption(values, suffix, decimals)
    if not values then
      return nil
    end

    return format_final_stat_value(values.total, values.base, suffix, decimals)
  end

  local function add_base_crit_stats(stats, state)
    local crit_chance_rank = get_base_rank(state, "crit_chance")
    local raw_chance = ((crit_chance_rank * 0.0025) + get_sub_specialization_flat_bonus(state, "crit_chance_flat")) * 100
    local luck_multiplier = get_luck_multiplier(state)
    local crit_chance_formula = format_stat_formula(0, raw_chance, luck_multiplier, get_crit_chance_fraction(state) * 100, "% / shot", 2)
    add_stat_value(
      stats,
      { "turret-xp.stat-crit-chance" },
      format_final_stat_value(get_crit_chance_fraction(state) * 100, 0, "%", 2),
      stat_formula_tooltip({ "turret-xp.crit-chance-tooltip" }, crit_chance_formula)
    )

    local crit_damage_values = get_crit_damage_formula_values(state)
    local crit_damage_formula = format_stat_formula(
      crit_damage_values.base,
      crit_damage_values.additive,
      crit_damage_values.multiplier,
      crit_damage_values.total,
      "% on crit",
      1
    )
    add_stat_value(
      stats,
      { "turret-xp.stat-crit-damage" },
      format_final_stat_value(crit_damage_values.total, crit_damage_values.base, "%", 1),
      stat_formula_tooltip({ "turret-xp.crit-damage-tooltip" }, crit_damage_formula)
    )
  end

  local function format_bonus_value_with_multiplier(value, multiplier, suffix, decimals, numeric_suffix)
    suffix = suffix or ""
    multiplier = multiplier or 1
    local value_text = "+" .. format_number(value, decimals) .. (numeric_suffix or "")
    if math.abs(multiplier - 1) < 0.005 then
      return rich_number(value_text) .. suffix
    end

    return {
      "",
      rich_number(value_text),
      " ",
      format_colored_multiplier(multiplier),
      " = ",
      rich_number(format_number(value * multiplier, decimals) .. (numeric_suffix or "")),
      suffix,
    }
  end

  local function add_active_custom_stats(stats, state, entity, first_row_options)
    if not state then
      return
    end

    local function add_effect_stat(label, value, tooltip)
      add_custom_stat(stats, label, value, tooltip, first_row_options)
      first_row_options = nil
    end

    local damage_rank = get_base_rank(state, "damage")
    if damage_rank > 0 then
      add_effect_stat({ "turret-xp.stat-core-damage" }, {
        "turret-xp.stat-core-damage-value",
        rich_number("+" .. format_number(damage_rank * 0.5, 1)),
      })
    end

    local shield_on_hit_rank = get_augment_rank(state, "siphon")
    if shield_on_hit_rank > 0 then
      local shield_value = format_bonus_value_with_multiplier(get_shield_on_hit_fraction(state) * 100, 1, "", 1, "%")
      add_effect_stat({ "turret-xp.stat-shield-on-hit" }, { "turret-xp.stat-shield-on-hit-value", shield_value })
    end

    local lifesteal_rate = get_lifesteal_rate(state)
    if lifesteal_rate > 0 then
      add_effect_stat(
        { "turret-xp.stat-lifesteal" },
        format_percent(lifesteal_rate, 0),
        { "turret-xp.lifesteal-tooltip", format_percent(lifesteal_rate, 0) }
      )
    end

    local bounce_rank = get_augment_rank(state, "bounce")
    if bounce_rank > 0 then
      add_effect_stat(
        { "turret-xp.stat-bounce-chance" },
        format_percent(apply_luck_to_chance(state, bounce_rank * 0.05), 1),
        { "turret-xp.bounce-chance-tooltip" }
      )
      add_effect_stat({ "turret-xp.stat-bounce-damage" }, "35%", { "turret-xp.bounce-damage-tooltip" })
    end

    local double_shot_chance = get_double_shot_chance(state)
    if double_shot_chance > 0 then
      add_effect_stat({ "turret-xp.stat-double-shot" }, {
        "turret-xp.stat-double-shot-value",
        rich_number(format_percent(double_shot_chance, 1)),
      })
    end

    local luck_rank = get_augment_rank(state, "luck")
    if luck_rank > 0 then
      add_effect_stat({ "turret-xp.stat-luck" }, {
        "turret-xp.stat-luck-value",
        format_colored_multiplier(get_luck_multiplier(state)),
      })
    end

    local training_rank = get_augment_rank(state, "veteran_training")
    if training_rank > 0 then
      add_effect_stat({ "turret-xp.stat-xp-gain" }, {
        "turret-xp.stat-xp-gain-value",
        rich_number("+" .. format_number(training_rank * 5, 0) .. "%"),
      })
    end

    for _, element_id in ipairs(get_unique_active_element_ids(state)) do
      local rank = get_element_rank(state, element_id)
      local summary = get_element_effect_summary_for_rank(state, element_id, rank, true, false)
      if summary then
        add_effect_stat(element_name(element_id), summary)
      end
    end

    local evolution = ensure_evolution_state(state)
    local combo = get_combo_caption(state)
    if combo and evolution.elements[1] and evolution.elements[2] then
      add_effect_stat({ "turret-xp.stat-element-combo" }, combo)
    end
  end

  local function has_active_custom_stats(state)
    if not state then
      return false
    end

    if get_base_rank(state, "damage") > 0 then
      return true
    end
    if get_augment_rank(state, "siphon") > 0 then
      return true
    end
    if get_lifesteal_rate(state) > 0 then
      return true
    end
    if get_augment_rank(state, "bounce") > 0 then
      return true
    end
    if get_double_shot_chance(state) > 0 then
      return true
    end
    if get_augment_rank(state, "luck") > 0 then
      return true
    end
    if get_augment_rank(state, "veteran_training") > 0 then
      return true
    end

    for _, element_id in ipairs(get_unique_active_element_ids(state)) do
      local rank = get_element_rank(state, element_id)
      if get_element_effect_summary_for_rank(state, element_id, rank, true, false) then
        return true
      end
    end

    local evolution = ensure_evolution_state(state)
    return get_combo_caption(state) ~= nil and evolution.elements[1] ~= nil and evolution.elements[2] ~= nil
  end

  local function update_stats_panel(
    panel,
    entity,
    state,
    ammo_name,
    ammo_count,
    ammo_quality,
    ammo_in_magazine,
    ammo_magazine_size,
    quality_name,
    max_health,
    health
  )
    local stats = find_gui_element(panel, GUI.stats)
    if not stats then
      return
    end

    stats.clear()

    if state then
      local identity_section = add_stats_section(stats, { "turret-xp.stats-section-identity" })
      local specialization = get_specialization(state)
      local sub_specialization = get_sub_specialization(state)
      local specialization_caption = specialization and rich_specialization_caption(specialization.id, specialization.name) or "-"
      if specialization and sub_specialization then
        specialization_caption = {
          "",
          rich_specialization_caption(specialization.id, specialization.name),
          " / ",
          rich_specialization_caption(specialization.id, sub_specialization.name),
        }
      end
      add_custom_stat(stats, { "turret-xp.stat-specialization" }, specialization_caption, nil, identity_section)
    end

    local defense_section = add_stats_section(stats, { "turret-xp.stats-section-defense" })
    local health_tooltip = make_quality_tooltip(function(quality)
      return format_number(get_max_health_for_quality(entity, quality.name, state), 0)
    end)
    local health_values = get_health_formula_values(entity, state, quality_name, max_health)
    local health_formula = health_values
        and format_stat_formula(health_values.base, health_values.additive, health_values.multiplier, health_values.total, "", 0)
      or nil
    local health_caption = health_values
        and {
          "",
          format_number(health, 0),
          " / ",
          format_final_stat_value(health_values.total, health_values.base, "", 0),
        }
      or string.format("%s / %s", format_number(health, 0), format_number(max_health, 0))
    add_stat_value_with_quality_marker(
      stats,
      { "turret-xp.hp" },
      health_caption,
      stat_formula_tooltip({ "turret-xp.hp-tooltip" }, health_formula),
      health_tooltip,
      defense_section
    )

    if state then
      local repair_per_second = get_repair_per_second(state, entity)
      if repair_per_second > 0 then
        local repair_base = get_repair_base_per_second(state, entity)
        local repair_multiplier = get_specialization_multiplier(state, "repair_multiplier")
        local repair_formula = format_stat_formula(repair_base, 0, repair_multiplier, repair_per_second, " HP/s", 1)
        add_stat_value(
          stats,
          { "turret-xp.stat-regeneration" },
          { "turret-xp.stat-regeneration-value", rich_number("+" .. format_number(repair_per_second, 1)) },
          stat_formula_tooltip({ "turret-xp.regeneration-tooltip" }, repair_formula)
        )
      end
    end

    if state then
      local shield, shield_capacity = normalize_shield_state(state, true)
      if shield_capacity > 0 then
        add_stat_value(stats, { "turret-xp.shield" }, {
          "",
          format_number(shield, 0),
          " / ",
          format_number(shield_capacity, 0),
        }, { "turret-xp.shield-tooltip" })
        add_stat_value(
          stats,
          { "turret-xp.stat-shield-regeneration" },
          { "turret-xp.stat-shield-regeneration-value", rich_number("+" .. format_number(get_shield_recharge_per_second(state), 1)) },
          nil
        )
      end
    end

    if state then
      local resistance = get_damage_resistance_fraction(state)
      if resistance > 0 then
        add_custom_stat(
          stats,
          { "turret-xp.stat-resistance" },
          { "turret-xp.stat-resistance-value", rich_number("-" .. format_number(resistance * 100, 2) .. "%") }
        )
      end
    end

    local offense_section = add_stats_section(stats, { "turret-xp.stats-section-offense" })
    local speed_values = get_shooting_speed_formula_values(entity, state, ammo_name)
    local speed_formula = speed_values
        and format_stat_formula(speed_values.base, speed_values.additive, speed_values.multiplier, speed_values.total, "/s", 2)
      or nil
    add_stat_value(
      stats,
      { "turret-xp.shooting-speed" },
      speed_values and formula_total_caption(speed_values, "/s", 2) or format_shots_per_second(entity, ammo_name, state),
      stat_formula_tooltip({ "turret-xp.shooting-speed-tooltip" }, speed_formula),
      offense_section
    )

    local range_tooltip = make_quality_tooltip(function(quality)
      return format_range_for_quality(entity, quality.name, state)
    end)
    local range_values = get_range_formula_values(entity, state, quality_name)
    local range_formula = range_values
        and format_stat_formula(range_values.base, range_values.additive, range_values.multiplier, range_values.total, "", 1)
      or nil
    add_stat_value_with_quality_marker(
      stats,
      { "turret-xp.range" },
      range_values and formula_total_caption(range_values, "", 1) or format_range(entity, state),
      stat_formula_tooltip({ "turret-xp.range-tooltip" }, range_formula),
      range_tooltip
    )

    if ammo_name then
      local damage_values = get_damage_formula_values(entity, state, ammo_name)
      local damage_formula = damage_values
          and format_stat_formula(damage_values.base, damage_values.additive, damage_values.multiplier, damage_values.total, "", 1)
        or nil
      local damage_caption = damage_values
          and {
            "turret-xp.damage-value",
            {
              "turret-xp.damage-value-with-type",
              format_final_stat_value(damage_values.total, damage_values.base, "", 1),
              { "damage-type-name." .. damage_values.damage_type },
            },
          }
        or { "turret-xp.damage-value", format_damage_per_shot(entity, ammo_name) }
      add_stat_value(stats, { "turret-xp.damage" }, damage_caption, stat_formula_tooltip({ "turret-xp.damage-tooltip" }, damage_formula))
      local dps_values = get_estimated_dps_values(entity, ammo_name, state)
      local dps_formula = dps_values and format_estimated_dps_formula(dps_values) or nil
      add_stat_value(
        stats,
        { "turret-xp.dps" },
        dps_values and { "turret-xp.stat-dps-value", format_number(dps_values.total, 1) } or "-",
        stat_formula_tooltip({ "turret-xp.dps-tooltip" }, dps_formula)
      )
    else
      add_stat_value(stats, { "turret-xp.damage" }, { "turret-xp.damage-no-ammo" }, nil)
      add_stat_value(stats, { "turret-xp.dps" }, "-", nil)
    end

    if state then
      add_base_crit_stats(stats, state)
    end

    local ammo_section = add_stats_section(stats, { "turret-xp.stats-section-ammo" })
    local _, magazine_flow = add_stat_row(stats, { "turret-xp.magazine" }, nil, {
      info_tooltip = { "turret-xp.magazine-tooltip" },
      flow_name = GUI.magazine,
      flow_only = true,
      no_delimiter = ammo_section.no_delimiter,
    })
    render_magazine_stack_flow(magazine_flow, ammo_name, ammo_count, ammo_quality)

    local ammo_tooltip = {
      "turret-xp.ammo-tooltip",
      ammo_in_magazine and format_number(ammo_in_magazine, 0) or "-",
      ammo_magazine_size and ammo_magazine_size > 0 and format_number(ammo_magazine_size, 0) or "-",
    }
    local _, ammo_flow = add_stat_row(stats, { "turret-xp.ammo" }, nil, {
      info_tooltip = ammo_tooltip,
      flow_name = GUI.ammo,
      flow_only = true,
    })
    render_current_ammo_flow(ammo_flow, ammo_in_magazine, ammo_magazine_size)

    if state and get_base_rank(state, "ammo_regen") > 0 then
      local productivity_progress = math.min(1, math.max(0, tonumber(state.ammo_productivity_progress or state.ammo_regen_progress) or 0))
      local _, ammo_productivity_flow = add_stat_row(stats, { "turret-xp.stat-ammo-productivity" }, nil, {
        info_tooltip = {
          "turret-xp.ammo-productivity-tooltip",
          "+" .. format_percent(get_ammo_productivity_fraction(state), 0),
          format_percent(get_effective_ammo_productivity_fraction(state), 1),
          format_percent(productivity_progress, 0),
        },
        flow_name = GUI.ammo_productivity,
        flow_only = true,
      })
      render_ammo_productivity(ammo_productivity_flow, state)
    end

    local history_section = add_stats_section(stats, { "turret-xp.stats-section-history" })
    add_stat_value(stats, { "turret-xp.kills" }, state and format_number(state.kills, 0) or "-", nil, history_section)
    add_stat_value(stats, { "turret-xp.damage-dealt" }, state and format_number(state.damage, 0) or "-")
    if state and has_active_custom_stats(state) then
      local effects_section = add_stats_section(stats, { "turret-xp.stats-section-effects" })
      add_active_custom_stats(stats, state, entity, effects_section)
    end
  end

  return {
    render_ammo_productivity = render_ammo_productivity,
    render_magazine_stack_flow = render_magazine_stack_flow,
    render_current_ammo_flow = render_current_ammo_flow,
    update_ammo_row = update_ammo_row,
    add_stats_panel = add_stats_panel,
    add_stat_value = add_stat_value,
    add_custom_stat = add_custom_stat,
    stat_formula_tooltip = stat_formula_tooltip,
    add_stat_value_with_quality_marker = add_stat_value_with_quality_marker,
    format_final_stat_value = format_final_stat_value,
    formula_total_caption = formula_total_caption,
    add_base_crit_stats = add_base_crit_stats,
    format_bonus_value_with_multiplier = format_bonus_value_with_multiplier,
    add_active_custom_stats = add_active_custom_stats,
    update_stats_panel = update_stats_panel,
  }
end

return stats_panel
