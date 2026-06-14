local evolution_panel_module = {}

function evolution_panel_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local LAYOUT = deps.LAYOUT
  local GATES = deps.GATES
  local BASE_UPGRADES = deps.BASE_UPGRADES
  local AUGMENTS = deps.AUGMENTS
  local ELEMENTS = deps.ELEMENTS
  local ELEMENT_BY_ID = deps.ELEMENT_BY_ID
  local SPECIALIZATIONS = deps.SPECIALIZATIONS
  local SPECIALIZATION_BY_ID = deps.SPECIALIZATION_BY_ID
  local SUB_SPECIALIZATIONS_BY_PARENT = deps.SUB_SPECIALIZATIONS_BY_PARENT
  local SUB_SPECIALIZATION_BY_ID = deps.SUB_SPECIALIZATION_BY_ID
  local set_style = deps.set_style
  local set_element_style = deps.set_element_style
  local find_gui_element = deps.find_gui_element
  local scroll_evolution_to_anchor = deps.scroll_evolution_to_anchor
  local evolution_anchor_name = deps.evolution_anchor_name
  local format_number = deps.format_number
  local rich_number = deps.rich_number
  local rich_stat_text = deps.rich_stat_text
  local set_evolution_content_width = deps.set_evolution_content_width
  local set_card_text_width = deps.set_card_text_width
  local set_evolution_card_child_width = deps.set_evolution_card_child_width
  local get_gui_components_service = deps.get_gui_components_service
  local ensure_evolution_state = deps.ensure_evolution_state
  local get_sub_specialization = deps.get_sub_specialization
  local get_available_skill_points = deps.get_available_skill_points
  local get_available_augment_points = deps.get_available_augment_points
  local get_base_rank = deps.get_base_rank
  local get_augment_rank = deps.get_augment_rank
  local get_element_progress = deps.get_element_progress
  local get_element_effect_summary = deps.get_element_effect_summary
  local get_combo_caption = deps.get_combo_caption
  local get_combo_caption_for_pair = deps.get_combo_caption_for_pair
  local get_element_effect_summary_for_rank = deps.get_element_effect_summary_for_rank
  local specialization_effect_entries = deps.specialization_effect_entries
  local sub_specialization_effect_entries = deps.sub_specialization_effect_entries
  local specialization_effect_value_caption = deps.specialization_effect_value_caption

  local function add_specialization_effect_table(parent, entries)
    local table_element = parent.add({
      type = "table",
      column_count = 2,
    })
    set_style(table_element, "width", LAYOUT.evolution_card_inner_width)
    set_style(table_element, "minimal_width", LAYOUT.evolution_card_inner_width)
    set_style(table_element, "maximal_width", LAYOUT.evolution_card_inner_width)
    set_style(table_element, "horizontally_stretchable", true)
    set_style(table_element, "horizontal_spacing", 8)
    set_style(table_element, "vertical_spacing", 1)
    pcall(function()
      table_element.style.column_alignments[1] = "left"
      table_element.style.column_alignments[2] = "right"
    end)

    for _, entry in ipairs(entries) do
      local label_caption = entry.label
      local label = table_element.add({
        type = "label",
        caption = label_caption,
        style = "caption_label",
      })
      set_style(label, "font_color", entry.lifesteal and { 0.95, 0.22, 0.42 } or COLOR.muted)
      set_style(label, "single_line", true)
      set_style(label, "maximal_width", 180)

      local value = table_element.add({
        type = "label",
        caption = specialization_effect_value_caption(entry),
        style = "caption_label",
      })
      set_style(value, "single_line", false)
      set_style(value, "horizontal_align", "right")
      set_style(value, "maximal_width", 180)
    end

    if #entries == 0 then
      local empty = table_element.add({
        type = "label",
        caption = "-",
        style = "caption_label",
      })
      set_style(empty, "font_color", COLOR.muted)
    end

    return table_element
  end

  local function add_evolution_panel(parent)
    local _, _, panel = get_gui_components_service().add_content_pane(parent, {
      width = LAYOUT.evolution_column_width,
      height = LAYOUT.evolution_outer_height,
      header_name = GUI.evolution_summary,
      header_height = LAYOUT.evolution_header_height,
      scroll_name = GUI.evolution,
      scroll_width = LAYOUT.evolution_scroll_width,
      scroll_height = LAYOUT.evolution_scroll_height,
      vertically_stretchable = true,
    })
    return panel
  end

  local function has_level(state, level)
    return (state.level or 0) >= level
  end

  local function add_summary_label(parent, title, value, value_color)
    return get_gui_components_service().add_summary_label(parent, title, value, value_color)
  end

  local function update_evolution_summary(panel, state)
    local header = find_gui_element(panel, GUI.evolution_summary)
    if not header then
      return
    end

    header.clear()

    local label = header.add({
      type = "label",
      caption = { "turret-xp.evolution-title" },
      style = "heading_2_label",
    })
    set_style(label, "font", "default-bold")

    header.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    if not state then
      add_summary_label(header, { "turret-xp.evolution-summary-core" }, { "turret-xp.evolution-summary-none" }, "0.74,0.74,0.74")
      return
    end

    local evolution = ensure_evolution_state(state)
    local specialization = evolution.specialization and SPECIALIZATION_BY_ID[evolution.specialization] or nil
    local sub_specialization = get_sub_specialization(state)
    local specialization_caption = specialization and specialization.name or "-"
    if specialization and sub_specialization then
      specialization_caption = specialization.name .. "/" .. sub_specialization.name
    end
    add_summary_label(header, { "turret-xp.evolution-summary-core" }, tostring(get_available_skill_points(state)), "0.58,0.82,0.38")
    add_summary_label(header, { "turret-xp.evolution-summary-aug" }, tostring(get_available_augment_points(state)), "0.35,0.75,1")
    add_summary_label(
      header,
      { "turret-xp.evolution-summary-spec" },
      specialization_caption,
      specialization and "1,0.86,0.46" or "0.74,0.74,0.74"
    )

    local reset = header.add({
      type = "button",
      caption = { "turret-xp.evolution-reset" },
      tooltip = { "turret-xp.evolution-reset-tooltip" },
      tags = {
        turret_xp_action = "reset-evolution",
      },
    })
    set_style(reset, "left_margin", 8)
    set_style(reset, "minimal_width", 56)
  end

  local function add_section(
    parent,
    title,
    unlocked,
    gate_level,
    right_caption,
    action_caption,
    action_tags,
    action_tooltip,
    action_enabled
  )
    return get_gui_components_service().add_evolution_section(parent, {
      title = title,
      unlocked = unlocked,
      locked_caption = { "turret-xp.evolution-unlocks-at-level", gate_level },
      right_caption = right_caption,
      action_caption = action_caption,
      action_tags = action_tags,
      action_tooltip = action_tooltip,
      action_enabled = action_enabled,
    })
  end

  local function add_choice_delimiter(parent)
    return get_gui_components_service().add_choice_delimiter(parent)
  end

  local function add_row(parent, sprite, name, detail, right_caption, tags, enabled, row_name)
    return get_gui_components_service().add_choice_row(parent, sprite, name, detail, right_caption, tags, enabled, row_name)
  end

  local function add_element_choice_card(parent, element, state, slot)
    local row = parent.add({
      type = "frame",
      name = evolution_anchor_name("element", element.id, slot),
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_evolution_content_width(row, true)
    set_style(row, "top_margin", 4)

    local top = row.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_card_child_width(top)
    set_style(top, "vertical_align", "center")
    set_style(top, "horizontal_spacing", 8)

    local icon = top.add({
      type = "sprite",
      sprite = element.sprite,
    })
    set_style(icon, "size", 28)

    local title = top.add({
      type = "label",
      caption = element.name,
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "single_line", true)
    set_style(title, "maximal_width", LAYOUT.evolution_card_inner_width - 44)

    local description = row.add({
      type = "label",
      caption = element.description,
      style = "caption_label",
    })
    set_style(description, "font_color", COLOR.muted)
    set_card_text_width(description)

    local effect = row.add({
      type = "label",
      caption = { "turret-xp.element-card-effect", get_element_effect_summary_for_rank(state, element.id, 1, true) or "" },
      style = "caption_label",
    })
    set_card_text_width(effect)

    local technical_separator = row.add({
      type = "line",
      direction = "horizontal",
    })
    set_evolution_card_child_width(technical_separator)
    set_style(technical_separator, "top_margin", 2)
    set_style(technical_separator, "bottom_margin", 2)

    local cost_row = row.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_card_child_width(cost_row)
    set_style(cost_row, "vertical_align", "center")
    set_style(cost_row, "horizontal_spacing", 8)
    set_style(cost_row, "horizontal_align", "right")

    local cost = cost_row.add({
      type = "label",
      caption = { "turret-xp.element-card-unlock", { "turret-xp.element-unlock-free" } },
      style = "caption_label",
    })
    set_style(cost, "single_line", false)
    set_style(cost, "horizontally_stretchable", true)
    set_style(cost, "maximal_width", LAYOUT.evolution_card_inner_width - 80)

    local start = cost_row.add({
      type = "button",
      caption = { "turret-xp.evolution-action-pick" },
      tags = {
        turret_xp_action = "start-element",
        element = element.id,
        slot = slot,
      },
    })
    set_style(start, "width", 64)
    set_style(start, "minimal_width", 64)
    set_style(start, "maximal_width", 64)

    local evolution = ensure_evolution_state(state)
    if slot == 2 and evolution.elements[1] then
      local combo = row.add({
        type = "label",
        caption = { "turret-xp.element-card-combo", get_combo_caption_for_pair(evolution.elements[1], element.id) },
        style = "caption_label",
      })
      set_card_text_width(combo)
    end

    return row
  end

  local function add_rank_allocation_row(parent, options)
    options = options or {}
    local row_definition = {
      type = "table",
      column_count = 4,
    }
    if options.row_name then
      row_definition.name = options.row_name
    end
    local row = parent.add(row_definition)
    set_evolution_content_width(row, true)
    set_style(row, "horizontal_spacing", LAYOUT.rank_allocation_horizontal_spacing)
    set_style(row, "vertical_spacing", 2)
    pcall(function()
      row.style.column_alignments[1] = "left"
      row.style.column_alignments[2] = "left"
      row.style.column_alignments[3] = "right"
      row.style.column_alignments[4] = "right"
    end)

    local icon = row.add({
      type = "sprite",
      sprite = options.sprite,
    })
    set_style(icon, "size", LAYOUT.rank_allocation_icon_size)

    local details = row.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(details, "horizontally_stretchable", true)
    set_style(details, "width", LAYOUT.rank_allocation_detail_width)
    set_style(details, "minimal_width", LAYOUT.rank_allocation_detail_width)
    set_style(details, "maximal_width", LAYOUT.rank_allocation_detail_width)

    local title = details.add({
      type = "label",
      caption = options.name,
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "single_line", false)
    set_style(title, "maximal_width", LAYOUT.rank_allocation_detail_width)

    if options.rank_caption then
      local rank = details.add({
        type = "label",
        caption = options.rank_caption,
        style = "caption_label",
      })
      set_style(rank, "font_color", COLOR.muted)
      set_style(rank, "single_line", true)
    end

    local value = row.add({
      type = "label",
      caption = options.value_caption or "",
      style = "caption_label",
    })
    set_style(value, "horizontal_align", "right")
    set_style(value, "single_line", false)
    set_style(value, "width", LAYOUT.rank_allocation_value_width)
    set_style(value, "minimal_width", LAYOUT.rank_allocation_value_width)
    set_style(value, "maximal_width", LAYOUT.rank_allocation_value_width)

    get_gui_components_service().add_rank_stepper(row, {
      rank = options.rank or 0,
      can_decrease = options.can_decrease == true,
      can_increase = options.can_increase == true,
      decrease_tooltip = options.decrease_tooltip,
      increase_tooltip = options.increase_tooltip,
      decrease_tags = options.decrease_tags,
      increase_tags = options.increase_tags,
    })

    return row
  end

  local function add_base_allocation_row(parent, upgrade, rank, can_increase)
    add_rank_allocation_row(parent, {
      row_name = evolution_anchor_name("base", upgrade.id),
      sprite = upgrade.sprite,
      name = upgrade.name,
      rank = rank,
      value_caption = rich_stat_text(upgrade.value),
      can_decrease = rank > 0,
      can_increase = can_increase,
      decrease_tooltip = { "turret-xp.rank-remove-tooltip", upgrade.name },
      increase_tooltip = {
        "turret-xp.base-rank-add-tooltip",
        upgrade.name,
        rich_stat_text(upgrade.value),
        tostring(rank),
        tostring(rank + 1),
      },
      decrease_tags = {
        turret_xp_action = "deallocate-base",
        upgrade = upgrade.id,
      },
      increase_tags = {
        turret_xp_action = "allocate-base",
        upgrade = upgrade.id,
      },
    })
  end

  local function add_augment_allocation_row(parent, augment, rank, available, at_max)
    local rank_caption = augment.max_rank and { "turret-xp.rank-caption-with-max", rank, augment.max_rank }
      or { "turret-xp.rank-caption", rank }
    add_rank_allocation_row(parent, {
      row_name = evolution_anchor_name("augment", augment.id),
      sprite = augment.sprite,
      name = augment.name,
      rank = rank,
      rank_caption = rank_caption,
      value_caption = at_max and { "turret-xp.rank-max" } or rich_stat_text(augment.value),
      can_decrease = rank > 0,
      can_increase = available >= 1 and not at_max,
      decrease_tags = {
        turret_xp_action = "deallocate-augment",
        augment = augment.id,
      },
      increase_tags = {
        turret_xp_action = "allocate-augment",
        augment = augment.id,
      },
      decrease_tooltip = { "turret-xp.rank-remove-tooltip", augment.name },
      increase_tooltip = {
        "turret-xp.augment-rank-add-tooltip",
        augment.name,
        rich_stat_text(augment.description),
        tostring(rank),
        tostring(at_max and rank or (rank + 1)),
      },
    })
  end

  local function add_element_mastery_panel(parent, state, element_id)
    local element = ELEMENT_BY_ID[element_id]
    if not element then
      return
    end

    local evolution = ensure_evolution_state(state)
    local mastery = evolution.element_mastery[element_id]
    if not mastery or (mastery.rank or 0) <= 0 then
      return
    end

    local mastery_rank = mastery.rank or 1
    local next_rank = mastery_rank + 1
    local delivered, required, element_requirement = get_element_progress(state, element_id)
    local progress = required > 0 and math.min(1, delivered / required) or 0

    local frame = parent.add({
      type = "frame",
      name = evolution_anchor_name("element-mastery", element_id),
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_evolution_content_width(frame, true)
    set_style(frame, "top_margin", 6)

    local top = frame.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_content_width(top, true)
    set_style(top, "horizontally_stretchable", true)
    set_style(top, "vertical_align", "center")

    local slot = top.add({
      type = "sprite-button",
      sprite = "item/" .. element.resource,
      tooltip = { "item-name." .. element.resource },
    })
    set_element_style(slot, "slot_button")
    set_style(slot, "size", LAYOUT.element_mastery_icon_width)

    local labels = top.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(labels, "horizontally_stretchable", true)
    set_style(labels, "maximal_width", LAYOUT.element_mastery_label_width)

    local title = labels.add({
      type = "label",
      caption = { "turret-xp.element-rank-title", element.name, mastery_rank },
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")

    local effect = labels.add({
      type = "label",
      caption = get_element_effect_summary and get_element_effect_summary(state, element_id) or "",
      style = "caption_label",
    })
    set_style(effect, "single_line", false)
    set_style(effect, "maximal_width", LAYOUT.element_mastery_label_width)

    local control_row = frame.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(control_row, "top_margin", 4)
    set_style(control_row, "vertical_align", "center")
    set_style(control_row, "horizontal_spacing", 6)
    set_evolution_content_width(control_row, true)

    local requirement_label = control_row.add({
      type = "label",
      caption = element_requirement and {
        "turret-xp.element-rank-progress",
        element_requirement.name,
        next_rank,
        rich_number(format_number(delivered, 0)),
        rich_number(format_number(required, 0)),
      } or { "turret-xp.element-rank-no-requirement" },
      style = "caption_label",
    })
    set_style(requirement_label, "font_color", COLOR.muted)
    set_style(requirement_label, "single_line", false)
    set_style(requirement_label, "maximal_width", LAYOUT.evolution_inner_width)

    local bar = frame.add({
      type = "progressbar",
      name = GUI.element_progress_bar,
      value = progress,
    })
    set_style(bar, "horizontally_stretchable", true)
    set_style(bar, "top_margin", 4)
  end

  local function add_base_section(parent, state)
    local available = get_available_skill_points(state)
    local section = add_section(parent, { "turret-xp.section-core-upgrades" }, true, nil, nil, nil, nil, nil)

    for index, upgrade in ipairs(BASE_UPGRADES) do
      if index > 1 then
        add_choice_delimiter(section)
      end
      local rank = get_base_rank(state, upgrade.id)
      local at_max = upgrade.max_rank and rank >= upgrade.max_rank
      add_base_allocation_row(section, upgrade, rank, available >= 1 and not at_max)
    end
  end

  local function add_element_choices(section, state, slot)
    local evolution = ensure_evolution_state(state)

    if evolution.elements[slot] then
      add_element_mastery_panel(section, state, evolution.elements[slot])
      return
    end

    for index, element in ipairs(ELEMENTS) do
      if index > 1 then
        add_choice_delimiter(section)
      end
      add_element_choice_card(section, element, state, slot)
    end
  end

  local function add_first_element_section(parent, state)
    local unlocked = has_level(state, GATES.first_element)
    local evolution = ensure_evolution_state(state)
    local has_element = evolution.elements[1] ~= nil
    local section = add_section(parent, { "turret-xp.section-first-element" }, unlocked, GATES.first_element, nil, has_element and {
      "turret-xp.evolution-action-change",
    } or nil, has_element and {
      turret_xp_action = "reset-element-slot",
      slot = 1,
    } or nil, { "turret-xp.first-element-reset-tooltip" })
    if unlocked then
      add_element_choices(section, state, 1)
    end
  end

  local function add_specialization_choice_card(parent, anchor_name, sprite, name, description, effects, selected, action_tags)
    local row = parent.add({
      type = "frame",
      name = anchor_name,
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_evolution_content_width(row, true)
    set_style(row, "top_margin", 6)

    local title_row = row.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_card_child_width(title_row)
    set_style(title_row, "horizontal_spacing", 8)
    set_style(title_row, "vertical_align", "center")

    local icon = title_row.add({
      type = "sprite",
      sprite = sprite,
    })
    set_style(icon, "size", 28)

    local title = title_row.add({
      type = "label",
      caption = name,
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "single_line", true)
    set_style(title, "maximal_width", LAYOUT.evolution_card_inner_width - 36)

    local description_row = row.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_card_child_width(description_row)
    set_style(description_row, "horizontal_spacing", 8)
    set_style(description_row, "vertical_align", "center")
    set_style(description_row, "top_margin", 2)

    local description_label = description_row.add({
      type = "label",
      caption = description,
      style = "caption_label",
    })
    set_style(description_label, "font_color", COLOR.muted)
    set_style(description_label, "single_line", false)
    set_style(description_label, "horizontally_stretchable", true)
    set_style(
      description_label,
      "maximal_width",
      selected and LAYOUT.evolution_card_inner_width or (LAYOUT.evolution_card_inner_width - 72)
    )

    if not selected then
      local button = description_row.add({
        type = "button",
        caption = { "turret-xp.evolution-action-pick" },
        tags = action_tags,
      })
      set_style(button, "width", 56)
      set_style(button, "minimal_width", 56)
      set_style(button, "maximal_width", 56)
    end

    local effects_table = add_specialization_effect_table(row, effects)
    set_style(effects_table, "top_margin", 4)
  end

  local function add_specialization_option(parent, specialization, selected, entity, state, ammo_name)
    add_specialization_choice_card(
      parent,
      evolution_anchor_name("specialization", specialization.id),
      specialization.sprite,
      specialization.name,
      specialization.description,
      specialization_effect_entries(specialization, entity, state, ammo_name),
      selected,
      {
        turret_xp_action = "choose-specialization",
        specialization = specialization.id,
      }
    )
  end

  local function add_specialization_section(parent, state, entity, ammo_name)
    local unlocked = has_level(state, GATES.specialization)
    local evolution = ensure_evolution_state(state)
    local section = add_section(
      parent,
      { "turret-xp.section-specialization" },
      unlocked,
      GATES.specialization,
      nil,
      evolution.specialization and { "turret-xp.evolution-action-change" } or nil,
      evolution.specialization and {
        turret_xp_action = "reset-specialization",
      } or nil,
      { "turret-xp.specialization-reset-tooltip" }
    )
    if not unlocked then
      return
    end

    if evolution.specialization then
      local specialization = SPECIALIZATION_BY_ID[evolution.specialization]
      add_specialization_option(section, specialization, true, entity, state, ammo_name)
      return
    end

    for index, specialization in ipairs(SPECIALIZATIONS) do
      if index > 1 then
        add_choice_delimiter(section)
      end
      add_specialization_option(section, specialization, false, entity, state, ammo_name)
    end
  end

  local function add_sub_specialization_option(parent, sub_specialization, selected, entity, state, ammo_name)
    add_specialization_choice_card(
      parent,
      evolution_anchor_name("sub-specialization", sub_specialization.id),
      sub_specialization.sprite,
      sub_specialization.name,
      sub_specialization.description,
      sub_specialization_effect_entries(sub_specialization, entity, state, ammo_name),
      selected,
      {
        turret_xp_action = "choose-sub-specialization",
        sub_specialization = sub_specialization.id,
      }
    )
  end

  local function add_sub_specialization_section(parent, state, entity, ammo_name)
    local unlocked = has_level(state, GATES.sub_specialization)
    local evolution = ensure_evolution_state(state)
    local section = add_section(
      parent,
      { "turret-xp.section-sub-specialization" },
      unlocked,
      GATES.sub_specialization,
      nil,
      evolution.sub_specialization and { "turret-xp.evolution-action-change" } or nil,
      evolution.sub_specialization and {
        turret_xp_action = "reset-sub-specialization",
      } or nil,
      { "turret-xp.sub-specialization-reset-tooltip" }
    )
    if not unlocked then
      return
    end

    if not evolution.specialization then
      local label = section.add({
        type = "label",
        caption = { "turret-xp.sub-specialization-needs-specialization" },
        style = "caption_label",
      })
      set_style(label, "font_color", COLOR.muted)
      set_style(label, "single_line", false)
      set_style(label, "maximal_width", LAYOUT.evolution_inner_width)
      return
    end

    if evolution.sub_specialization then
      local sub_specialization = SUB_SPECIALIZATION_BY_ID[evolution.sub_specialization]
      if sub_specialization then
        add_sub_specialization_option(section, sub_specialization, true, entity, state, ammo_name)
      end
      return
    end

    local choices = SUB_SPECIALIZATIONS_BY_PARENT[evolution.specialization] or {}
    for index, sub_specialization in ipairs(choices) do
      if index > 1 then
        add_choice_delimiter(section)
      end
      add_sub_specialization_option(section, sub_specialization, false, entity, state, ammo_name)
    end
  end

  local function add_augments_section(parent, state)
    local unlocked = has_level(state, GATES.augments)
    local available = get_available_augment_points(state)
    local section = add_section(parent, { "turret-xp.section-augments" }, unlocked, GATES.augments, nil, nil, nil, nil)
    if not unlocked then
      return
    end

    for index, augment in ipairs(AUGMENTS) do
      if index > 1 then
        add_choice_delimiter(section)
      end
      local rank = get_augment_rank(state, augment.id)
      local at_max = augment.max_rank and rank >= augment.max_rank
      add_augment_allocation_row(section, augment, rank, available, at_max)
    end
  end

  local function add_second_element_section(parent, state)
    local unlocked = has_level(state, GATES.second_element)
    local evolution = ensure_evolution_state(state)
    local has_element = evolution.elements[2] ~= nil
    local section = add_section(parent, { "turret-xp.section-second-element" }, unlocked, GATES.second_element, nil, has_element and {
      "turret-xp.evolution-action-change",
    } or nil, has_element and {
      turret_xp_action = "reset-element-slot",
      slot = 2,
    } or nil, { "turret-xp.second-element-reset-tooltip" })
    if not unlocked then
      return
    end

    if not evolution.elements[1] then
      local label = section.add({
        type = "label",
        caption = { "turret-xp.second-element-needs-first" },
        style = "caption_label",
      })
      set_style(label, "font_color", COLOR.muted)
      set_style(label, "single_line", false)
      set_style(label, "maximal_width", LAYOUT.evolution_inner_width)
      return
    end

    add_element_choices(section, state, 2)

    local combo = section.add({
      type = "label",
      name = GUI.active_combo,
      caption = { "turret-xp.active-combo", get_combo_caption(state) },
      style = "caption_label",
    })
    set_style(combo, "font", "default-bold")
    set_style(combo, "top_margin", 4)
    set_style(combo, "single_line", false)
    set_style(combo, "maximal_width", LAYOUT.evolution_inner_width)
  end

  local function evolution_panel_key(state, ammo_name)
    if not state then
      return "empty"
    end

    local evolution = ensure_evolution_state(state)
    local parts = {
      "installed",
      tostring(state.level or 0),
      tostring(get_available_skill_points(state)),
      tostring(get_available_augment_points(state)),
      tostring(ammo_name or ""),
      tostring(evolution.specialization or ""),
      tostring(evolution.sub_specialization or ""),
      tostring(evolution.elements and evolution.elements[1] or ""),
      tostring(evolution.elements and evolution.elements[2] or ""),
    }

    for _, upgrade in ipairs(BASE_UPGRADES) do
      parts[#parts + 1] = tostring(evolution.base and evolution.base[upgrade.id] or 0)
    end
    for _, augment in ipairs(AUGMENTS) do
      parts[#parts + 1] = tostring(evolution.augments and evolution.augments[augment.id] or 0)
    end
    for _, element in ipairs(ELEMENTS) do
      local mastery = evolution.element_mastery and evolution.element_mastery[element.id] or nil
      parts[#parts + 1] = tostring(mastery and mastery.rank or 0)
      parts[#parts + 1] = tostring(mastery and math.floor(tonumber(mastery.delivered) or 0) or 0)
    end

    return table.concat(parts, ":")
  end

  local function update_evolution_panel(panel, entity, state, ammo_name, anchor_name)
    local evolution_panel = find_gui_element(panel, GUI.evolution)
    if not evolution_panel then
      return
    end

    local key = evolution_panel_key(state, ammo_name)
    if (evolution_panel.tags or {}).key == key then
      scroll_evolution_to_anchor(panel, anchor_name)
      return
    end

    evolution_panel.tags = {
      key = key,
    }
    update_evolution_summary(panel, state)
    evolution_panel.clear()

    if not state then
      local label = evolution_panel.add({
        type = "label",
        caption = { "turret-xp.evolution-needs-core" },
        style = "caption_label",
      })
      set_style(label, "font_color", COLOR.muted)
      set_style(label, "single_line", false)
      return
    end

    ensure_evolution_state(state)

    add_base_section(evolution_panel, state)
    add_specialization_section(evolution_panel, state, entity, ammo_name)
    add_first_element_section(evolution_panel, state)
    add_augments_section(evolution_panel, state)
    add_sub_specialization_section(evolution_panel, state, entity, ammo_name)
    add_second_element_section(evolution_panel, state)
    scroll_evolution_to_anchor(panel, anchor_name)
  end

  return {
    add_specialization_effect_table = add_specialization_effect_table,
    add_evolution_panel = add_evolution_panel,
    has_level = has_level,
    update_evolution_summary = update_evolution_summary,
    add_section = add_section,
    add_choice_delimiter = add_choice_delimiter,
    add_row = add_row,
    add_element_choice_card = add_element_choice_card,
    add_rank_allocation_row = add_rank_allocation_row,
    add_base_allocation_row = add_base_allocation_row,
    add_augment_allocation_row = add_augment_allocation_row,
    add_element_mastery_panel = add_element_mastery_panel,
    add_base_section = add_base_section,
    add_element_choices = add_element_choices,
    add_first_element_section = add_first_element_section,
    add_specialization_choice_card = add_specialization_choice_card,
    add_specialization_option = add_specialization_option,
    add_specialization_section = add_specialization_section,
    add_sub_specialization_option = add_sub_specialization_option,
    add_sub_specialization_section = add_sub_specialization_section,
    add_augments_section = add_augments_section,
    add_second_element_section = add_second_element_section,
    update_evolution_panel = update_evolution_panel,
  }
end

return evolution_panel_module
