local core_panel_module = {}

function core_panel_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local LAYOUT = deps.LAYOUT
  local CHIP_NAME = deps.CHIP_NAME
  local set_style = deps.set_style
  local set_element_style = deps.set_element_style
  local find_gui_element = deps.find_gui_element
  local get_remembered_turret = deps.get_remembered_turret
  local get_player_core_options_model = deps.get_player_core_options_model
  local get_core_picker_sort = deps.get_core_picker_sort
  local get_core_picker_filters = deps.get_core_picker_filters
  local core_picker_filters_key = deps.core_picker_filters_key
  local get_platform_core_options = deps.get_platform_core_options
  local get_platform_hub_inventory = deps.get_platform_hub_inventory
  local create_blank_profile = deps.create_blank_profile
  local dev_controls_enabled = deps.dev_controls_enabled
  local update_name_render = deps.update_name_render
  local ensure_evolution_state = deps.ensure_evolution_state
  local get_specialization = deps.get_specialization
  local get_sub_specialization = deps.get_sub_specialization
  local get_loaded_ammo = deps.get_loaded_ammo
  local get_entity_quality_name = deps.get_entity_quality_name
  local get_max_health_for_quality = deps.get_max_health_for_quality
  local get_health_formula_values = deps.get_health_formula_values
  local get_shooting_speed_formula_values = deps.get_shooting_speed_formula_values
  local get_range_formula_values = deps.get_range_formula_values
  local format_number = deps.format_number
  local SPECIALIZATIONS = deps.SPECIALIZATIONS
  local rich_specialization_caption = deps.rich_specialization_caption
  local widgets = deps.widgets
  local components = deps.components
  local core_picker_table = deps.core_picker_table
  local profile_automation = deps.profile_automation
  local get_turret_host = deps.get_turret_host
  local core_requester = deps.core_requester
  local find_matching_label_color_preset = deps.find_matching_label_color_preset

  local function set_fixed_width(element, width)
    set_style(element, "width", width)
    set_style(element, "minimal_width", width)
    set_style(element, "maximal_width", width)
  end

  local function set_fixed_size(element, width, height)
    set_fixed_width(element, width)
    set_style(element, "height", height or width)
    set_style(element, "minimal_height", height or width)
    set_style(element, "maximal_height", height or width)
  end

  local function set_wrapped_width(element, width)
    set_style(element, "single_line", false)
    set_style(element, "maximal_width", width)
  end

  local function section_width(mode)
    return mode == "empty" and LAYOUT.empty_left_section_width or LAYOUT.left_section_width
  end

  local function section_style(build_mode)
    return build_mode and "turret_xp_left_section_frame_build_mode" or "turret_xp_left_section_frame"
  end

  local function set_section_mode(section, role, build_mode)
    set_element_style(section, section_style(build_mode))
    section.tags = {
      key = section.tags and section.tags.key or nil,
      base_key = section.tags and section.tags.base_key or nil,
      picker_key = section.tags and section.tags.picker_key or nil,
      turret_xp_left_section = true,
      turret_xp_section_role = role,
      turret_xp_build_mode = build_mode == true,
    }
  end

  local function add_stack_section(parent, options)
    options = options or {}
    return components.add_left_stack_section(parent, {
      name = options.name,
      role = options.role,
      title = options.title,
      header_name = options.header_name,
      right_caption = options.right_caption,
      width = options.width or section_width(options.mode),
      build_mode = options.build_mode == true,
      vertical_spacing = options.vertical_spacing or 6,
    })
  end

  local function add_header(parent, options)
    options = options or {}
    local header = parent.add({
      type = "frame",
      name = options.name,
      direction = "horizontal",
      style = options.build_mode and "turret_xp_build_mode_subheader_frame" or "subheader_frame",
    })
    set_style(header, "horizontally_stretchable", true)
    set_style(header, "vertical_align", "center")
    set_style(header, "horizontal_spacing", options.spacing or 6)
    set_style(header, "height", options.height or LAYOUT.left_section_header_height)
    return header
  end

  local function core_name(profile, fallback)
    local name = profile and profile.custom_name or nil
    if name and name ~= "" then
      return name
    end
    return fallback or { "turret-xp.inventory-core-unnamed" }
  end

  local function plain_metric(label, value, suffix)
    return {
      "",
      label,
      " ",
      tostring(value or "-"),
      suffix or "",
    }
  end

  local function specialization_caption(profile)
    local specialization = get_specialization(profile)
    if not specialization then
      return rich_specialization_caption("base", { "turret-xp.inventory-core-no-specialization" })
    end

    local sub_specialization = get_sub_specialization(profile)
    if sub_specialization then
      return {
        "",
        rich_specialization_caption(specialization.id, specialization.name),
        " / ",
        rich_specialization_caption(specialization.id, sub_specialization.name),
      }
    end

    return rich_specialization_caption(specialization.id, specialization.name)
  end

  local function preview_stats(entity, profile)
    local quality_name = get_entity_quality_name(entity)
    local max_health = get_max_health_for_quality(entity, quality_name, profile)
    local health_values = get_health_formula_values(entity, profile, quality_name, max_health)
    local ammo_name = get_loaded_ammo(entity)
    local speed_values = get_shooting_speed_formula_values(entity, profile, ammo_name)
    local range_values = get_range_formula_values(entity, profile, quality_name)

    local health_total = health_values and health_values.total or max_health
    local speed_total = speed_values and speed_values.total or nil
    local range_total = range_values and range_values.total or nil

    return {
      health = format_number(health_total, 0),
      speed = format_number(speed_total, 2),
      range = format_number(range_total, 1),
      sort = {
        hp = tonumber(health_total),
        attack = tonumber(speed_total),
        range = tonumber(range_total),
      },
    }
  end

  local function option_key(options)
    local parts = {}
    for _, option in ipairs(options or {}) do
      local profile = option.profile or {}
      local evolution = ensure_evolution_state(profile)
      parts[#parts + 1] = table.concat({
        tostring(option.index or ""),
        tostring(profile.chip_id or ""),
        tostring(profile.level or 0),
        tostring(profile.custom_name or ""),
        tostring(profile.chip_quality or option.quality or "normal"),
        tostring(evolution.specialization or ""),
        tostring(evolution.sub_specialization or ""),
      }, "/")
    end
    return table.concat(parts, "|")
  end

  local function picker_model(player, entity)
    local sort_mode = get_core_picker_sort(player)
    local filters = get_core_picker_filters(player)
    local inventory_model = get_player_core_options_model(player, sort_mode, filters)
    local model = {
      sort_mode = sort_mode,
      filters = filters,
      all_options = inventory_model.all_options or {},
      options = inventory_model.options or {},
    }
    model.key = table.concat({
      tostring(sort_mode),
      "filters",
      core_picker_filters_key(filters),
      "all",
      option_key(model.all_options),
      "shown",
      option_key(model.options),
      "quality",
      tostring(get_entity_quality_name(entity)),
      "ammo",
      tostring(get_loaded_ammo(entity)),
    }, ":")
    return model
  end

  local function profile_has_name(profile)
    local raw = tostring((profile or {}).custom_name or "")
    local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
    return trimmed ~= "", string.lower(trimmed)
  end

  local function specialization_sort_key(profile)
    local specialization = get_specialization(profile)
    if not specialization then
      return "base"
    end
    local sub_specialization = get_sub_specialization(profile)
    local label = tostring(specialization.name or specialization.id or "")
    if sub_specialization then
      label = label .. " / " .. tostring(sub_specialization.name or sub_specialization.id or "")
    end
    return string.lower(label)
  end

  local function compare_number(left, right, field, direction)
    local left_value = left.sort_key and left.sort_key[field] or nil
    local right_value = right.sort_key and right.sort_key[field] or nil
    if left_value == nil and right_value == nil then
      return nil
    end
    if left_value == nil then
      return false
    end
    if right_value == nil then
      return true
    end
    if left_value == right_value then
      return nil
    end
    if direction == "asc" then
      return left_value < right_value
    end
    return left_value > right_value
  end

  local function compare_name(left, right, direction)
    if left.sort_key.has_name ~= right.sort_key.has_name then
      return left.sort_key.has_name
    end
    if left.sort_key.name ~= right.sort_key.name then
      if direction == "asc" then
        return left.sort_key.name < right.sort_key.name
      end
      return left.sort_key.name > right.sort_key.name
    end
    return nil
  end

  local function compare_text(left, right, field, direction)
    local left_value = left.sort_key[field] or ""
    local right_value = right.sort_key[field] or ""
    if left_value == right_value then
      return nil
    end
    if direction == "asc" then
      return left_value < right_value
    end
    return left_value > right_value
  end

  local function compare_default(left, right)
    local result = compare_number(left, right, "level", "desc")
    if result ~= nil then
      return result
    end
    result = compare_name(left, right, "asc")
    if result ~= nil then
      return result
    end
    if left.sort_key.chip_id ~= right.sort_key.chip_id then
      return left.sort_key.chip_id < right.sort_key.chip_id
    end
    return (left.index or 0) < (right.index or 0)
  end

  local function stable_sort(list, less)
    for index = 2, #(list or {}) do
      local value = list[index]
      local scan = index - 1
      while scan >= 1 and less(value, list[scan]) do
        list[scan + 1] = list[scan]
        scan = scan - 1
      end
      list[scan + 1] = value
    end
  end

  local function parse_display_sort(sort_mode)
    local raw = tostring(sort_mode or "")
    local field, direction = string.match(raw, "^([^:]+):([^:]+)$")
    if not field then
      field = raw
      if field == "level" then
        direction = "desc"
      elseif field == "name" or field == "specialization" or field == "hp" or field == "attack" or field == "range" then
        direction = "asc"
      end
    end
    local valid_field = field == "level"
      or field == "name"
      or field == "specialization"
      or field == "hp"
      or field == "attack"
      or field == "range"
    if not valid_field or (direction ~= "asc" and direction ~= "desc") then
      return nil, nil
    end
    return field, direction
  end

  local function prepare_core_options_for_display(entity, options, current_sort)
    local field, direction = parse_display_sort(current_sort)
    for _, option in ipairs(options or {}) do
      local profile = option.profile or create_blank_profile()
      local stats = preview_stats(entity, profile)
      local has_name, name = profile_has_name(profile)
      option.preview_stats = stats
      option.sort_key = {
        level = math.max(0, math.floor(tonumber(profile.level) or 0)),
        hp = stats.sort.hp,
        attack = stats.sort.attack,
        range = stats.sort.range,
        has_name = has_name,
        name = name,
        specialization = specialization_sort_key(profile),
        chip_id = tonumber(profile.chip_id) or 0,
      }
    end

    if not field then
      return options
    end

    stable_sort(options, function(left, right)
      local result
      if field == "name" then
        result = compare_name(left, right, direction)
      elseif field == "specialization" then
        result = compare_text(left, right, "specialization", direction)
      else
        result = compare_number(left, right, field, direction)
      end
      if result ~= nil then
        return result
      end
      return compare_default(left, right)
    end)

    return options
  end

  local function filter_modes()
    local modes = {
      {
        id = "all",
        caption = { "turret-xp.inventory-core-filter-all" },
        tooltip = { "turret-xp.inventory-core-filter-all-tooltip" },
      },
      {
        id = "base",
        caption = { "turret-xp.inventory-core-filter-base" },
        tooltip = { "turret-xp.inventory-core-filter-base-tooltip" },
      },
    }
    for _, specialization in ipairs(SPECIALIZATIONS or {}) do
      modes[#modes + 1] = {
        id = specialization.id,
        caption = specialization.name,
        tooltip = { "turret-xp.inventory-core-filter-specialization-tooltip", specialization.name },
      }
    end
    return modes
  end

  local function filter_enabled(filters, id)
    if id == "all" then
      return filters.all == true
    end
    return filters.all ~= true and filters[id] == true
  end

  local function filter_caption(mode)
    if mode.id == "all" then
      return mode.caption
    end
    return rich_specialization_caption(mode.id, mode.caption)
  end

  local function add_filter_row(parent, filters)
    local row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "vertical_align", "center")
    set_style(row, "horizontal_spacing", 8)

    local label = row.add({
      type = "label",
      caption = { "turret-xp.inventory-core-filter" },
      style = "caption_label",
    })
    set_style(label, "font_color", COLOR.caption)

    for _, mode in ipairs(filter_modes()) do
      row.add({
        type = "checkbox",
        caption = filter_caption(mode),
        tooltip = mode.tooltip,
        state = filter_enabled(filters, mode.id),
        tags = {
          turret_xp_action = "set-core-filter",
          filter = mode.id,
        },
      })
    end
  end

  local function wide_row_data(option, profile, stats)
    return {
      install_tooltip = { "turret-xp.inventory-core-install-tooltip" },
      install_tags = {
        turret_xp_action = "inventory-install-core",
        slot = option.index,
      },
      level_caption = tostring(profile.level or 0),
      name_caption = core_name(profile),
      specialization_caption = specialization_caption(profile),
      hp_caption = tostring(stats.health or "-"),
      attack_caption = tostring(stats.speed or "-") .. "/s",
      range_caption = tostring(stats.range or "-"),
    }
  end

  local function add_inventory_rows(parent, entity, model)
    local scroll = parent.add({
      type = "scroll-pane",
      direction = "vertical",
      style = "flib_naked_scroll_pane_no_padding",
      vertical_scroll_policy = #model.options > LAYOUT.empty_inventory_core_picker_max_rows and "always" or "auto-and-reserve-space",
      horizontal_scroll_policy = "never",
    })
    local visible_rows =
      math.max(LAYOUT.empty_inventory_core_picker_min_rows, math.min(#model.options, LAYOUT.empty_inventory_core_picker_max_rows))
    local height = LAYOUT.inventory_core_table_header_height
      + (LAYOUT.inventory_core_table_row_height * visible_rows)
      + LAYOUT.empty_inventory_core_picker_vertical_padding
    set_fixed_width(scroll, LAYOUT.empty_inventory_core_picker_width)
    set_style(scroll, "height", height)

    prepare_core_options_for_display(entity, model.options, model.sort_mode)

    if #model.options == 0 then
      local label = scroll.add({
        type = "label",
        caption = #model.all_options == 0 and { "turret-xp.inventory-core-empty" } or { "turret-xp.inventory-core-filter-empty" },
        style = "caption_label",
      })
      set_style(label, "font_color", COLOR.muted)
      set_wrapped_width(label, LAYOUT.empty_inventory_core_picker_width - 36)
      set_style(label, "margin", { 8, 8, 8, 8 })
      return
    end

    local table_body = core_picker_table.add(scroll, model.sort_mode)
    for _, option in ipairs(model.options) do
      local profile = option.profile or create_blank_profile()
      local stats = option.preview_stats or preview_stats(entity, profile)
      core_picker_table.add_row(table_body, wide_row_data(option, profile, stats))
    end
  end

  local function add_core_slot(parent, state, options)
    options = options or {}
    local definition = {
      type = "sprite-button",
      name = GUI.core_slot,
      tooltip = state and { "turret-xp.extract-core-tooltip" } or options.pending and {
        "turret-xp.pending-core-slot-tooltip",
      } or { "turret-xp.install-core-tooltip" },
      tags = {
        turret_xp_action = "core-slot",
      },
    }
    if state or options.pending then
      definition.sprite = "item/" .. CHIP_NAME
      definition.quality = state and state.chip_quality or "normal"
      definition.elem_tooltip = {
        type = "item-with-quality",
        name = CHIP_NAME,
        quality = state and state.chip_quality or "normal",
      }
      if options.pending and not state then
        definition.toggled = true
      end
    end
    local button = parent.add(definition)
    set_element_style(button, options.pending and not state and "turret_xp_pending_core_slot_button" or "slot_button")
    set_fixed_size(button, LAYOUT.core_identity_slot_size)
    return button
  end

  local function add_core_details(parent, state, options)
    options = options or {}
    local width = (state or options.pending) and LAYOUT.core_identity_detail_width or LAYOUT.core_identity_empty_detail_width
    local details = parent.add({
      type = "flow",
      direction = "vertical",
    })
    set_fixed_width(details, width)

    local title = details.add({
      type = "label",
      name = GUI.core_status,
      caption = state and core_name(state) or options.pending and { "turret-xp.core-requested" } or { "turret-xp.core-empty" },
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")
    set_wrapped_width(title, width)

    local summary = details.add({
      type = "label",
      caption = state and {
        "turret-xp.core-identity-summary",
        tostring(state.level or 0),
        state.bound_turret and { "turret-xp.core-bound-status" } or { "turret-xp.core-unbound-status" },
      } or options.pending and { "turret-xp.core-requested-summary" } or { "turret-xp.core-empty-summary" },
      style = "caption_label",
    })
    set_style(summary, "font_color", COLOR.muted)
    set_wrapped_width(summary, width)
  end

  local function add_core_actions(parent, player, state)
    parent.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    if state then
      local actions = widgets.add_action_toolbar(parent, {
        name = GUI.core_actions,
        spacing = LAYOUT.core_identity_action_spacing,
      })
      widgets.add_tool_button(actions, {
        sprite = "utility/export_slot",
        tooltip = { "turret-xp.extract-core-button-tooltip" },
        size = LAYOUT.core_identity_tool_button_size,
        tags = {
          turret_xp_action = "extract-core",
        },
      })
      local bind = actions.add({
        type = "button",
        caption = state.bound_turret and { "turret-xp.core-unbind" } or { "turret-xp.core-bind" },
        tooltip = state.bound_turret and { "turret-xp.unbind-turret-tooltip" } or { "turret-xp.bind-turret-tooltip" },
        tags = {
          turret_xp_action = state.bound_turret and "unbind-turret" or "bind-turret",
        },
      })
      set_fixed_width(bind, LAYOUT.core_identity_action_button_width)
      return
    end

    if dev_controls_enabled(player) then
      local actions = widgets.add_action_toolbar(parent, {
        name = GUI.core_actions,
        spacing = LAYOUT.core_identity_action_spacing,
      })
      widgets.add_tool_button(actions, {
        sprite = "utility/add",
        style = "flib_tool_button_light_green",
        tooltip = { "turret-xp.dev-create-core-tooltip" },
        size = LAYOUT.core_identity_tool_button_size,
        tags = {
          turret_xp_action = "dev-create-core",
        },
      })
    end
  end

  local function add_pending_build_summary(parent, entity)
    local host = get_turret_host(entity, false)
    local target = profile_automation.target_model(host and host.pending_policy or nil)
    if not target then
      return
    end

    local summary = parent.add({
      type = "label",
      caption = { "turret-xp.pending-build-summary", target.level or 0 },
      tooltip = target.tooltip,
      style = "caption_label",
    })
    set_style(summary, "font_color", COLOR.build_mode_muted)
    set_wrapped_width(summary, section_width("empty") - 16)
  end

  local function label_controls_visible(state)
    return state.show_name_label == true or state.show_label_level == true or state.show_unspent_label == true
  end

  local function add_row_label(parent, caption, width)
    local label = parent.add({
      type = "label",
      caption = caption,
      style = "caption_label",
    })
    set_style(label, "font_color", COLOR.caption)
    set_fixed_width(label, width or 70)
    return label
  end

  local function add_label_controls(parent, state)
    local name_row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(name_row, "horizontally_stretchable", true)
    set_style(name_row, "vertical_align", "center")
    set_style(name_row, "horizontal_spacing", 8)
    add_row_label(name_row, { "turret-xp.core-name" })

    local name = name_row.add({
      type = "textfield",
      name = GUI.core_name,
      text = state.custom_name or "",
      clear_and_focus_on_right_click = true,
      lose_focus_on_confirm = true,
    })
    set_style(name, "minimal_width", 180)
    set_style(name, "horizontally_stretchable", true)

    local visible_row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(visible_row, "horizontally_stretchable", true)
    set_style(visible_row, "vertical_align", "center")
    set_style(visible_row, "horizontal_spacing", 8)
    add_row_label(visible_row, { "turret-xp.label-show" })
    visible_row.add({
      type = "checkbox",
      name = GUI.core_name_visible,
      caption = { "turret-xp.label-name" },
      state = state.show_name_label == true,
      tags = {
        turret_xp_action = "toggle-core-label",
      },
    })
    visible_row.add({
      type = "checkbox",
      name = GUI.core_name_level_visible,
      caption = { "turret-xp.label-level" },
      state = state.show_label_level == true,
      tags = {
        turret_xp_action = "toggle-label-level",
      },
    })
    visible_row.add({
      type = "checkbox",
      name = GUI.core_unspent_visible,
      caption = { "turret-xp.label-unspent" },
      tooltip = { "turret-xp.label-unspent-tooltip" },
      state = state.show_unspent_label == true,
      tags = {
        turret_xp_action = "toggle-label-unspent",
      },
    })

    if not label_controls_visible(state) then
      return
    end

    local color = state.label_color or { 1, 0.86, 0.46 }
    local preset = find_matching_label_color_preset(state)
    local color_row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(color_row, "horizontally_stretchable", true)
    set_style(color_row, "vertical_align", "center")
    set_style(color_row, "horizontal_spacing", 8)
    add_row_label(color_row, { "turret-xp.label-color-title" })

    local swatch = color_row.add({
      type = "progressbar",
      name = GUI.core_color_swatch,
      value = 1,
      tooltip = { "turret-xp.label-color-tooltip" },
    })
    set_fixed_size(swatch, 22)
    set_style(swatch, "bar_width", 22)
    set_style(swatch, "color", color)

    local picker = color_row.add({
      type = "button",
      name = GUI.core_color_preview,
      caption = preset and preset.name or { "turret-xp.label-custom-color" },
      tooltip = { "turret-xp.label-color-tooltip" },
      tags = {
        turret_xp_action = "open-label-color-picker",
      },
    })
    set_style(picker, "font_color", color)
    set_style(picker, "minimal_width", 112)
  end

  local function add_build_summary(parent, label_caption, value_caption, value_color)
    local row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "vertical_align", "center")
    set_style(row, "horizontal_spacing", 8)
    add_row_label(row, label_caption, 78)
    local value = row.add({
      type = "label",
      caption = value_caption,
      style = "caption_label",
    })
    set_style(value, "font_color", value_color or COLOR.muted)
    set_wrapped_width(value, LAYOUT.left_section_width - 118)
  end

  local function add_build_contents(parent, state)
    local build_mode = profile_automation.build_mode_active(state)
    local target = profile_automation.target_model(state)
    local has_target = profile_automation.target_has_content(state and state.automation_target)
    local has_unfinished = profile_automation.target_unfinished(state)

    local row = add_header(parent, {
      name = GUI.core_build_controls,
      build_mode = build_mode,
      spacing = 8,
    })
    local title = row.add({
      type = "label",
      caption = { "turret-xp.build-mode-title" },
      style = build_mode and "heading_2_label" or "caption_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "font_color", build_mode and COLOR.build_mode or COLOR.caption)

    if not build_mode and has_unfinished then
      local auto = row.add({
        type = "checkbox",
        name = GUI.core_automation_enabled,
        caption = { "turret-xp.build-mode-auto-enabled" },
        tooltip = { "turret-xp.build-mode-auto-tooltip" },
        state = state and state.automation_enabled == true,
        tags = {
          turret_xp_action = "toggle-build-auto",
        },
      })
      set_style(auto, "font_color", state and state.automation_enabled == true and COLOR.build_mode or COLOR.muted)
    end

    row.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })
    local toggle = row.add({
      type = "button",
      caption = build_mode and { "turret-xp.build-mode-exit" } or { "turret-xp.build-mode-enter" },
      tooltip = build_mode and { "turret-xp.build-mode-exit-tooltip" } or { "turret-xp.build-mode-enter-tooltip" },
      tags = {
        turret_xp_action = build_mode and "exit-build-mode" or "enter-build-mode",
      },
    })
    set_style(toggle, "minimal_width", 72)

    if not build_mode then
      return
    end

    local details = parent.add({
      type = "frame",
      name = GUI.core_build_details,
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_style(details, "horizontally_stretchable", true)
    set_style(details, "vertical_spacing", 4)

    if not target or not has_target then
      add_build_summary(details, { "turret-xp.build-mode-target" }, { "turret-xp.build-mode-target-none" })
      return
    end

    add_build_summary(
      details,
      { "turret-xp.build-mode-level" },
      target.open_ended and { "turret-xp.build-mode-level-open-ended", target.level or 0 }
        or { "turret-xp.build-mode-level-value", target.level or 0 },
      COLOR.build_mode_muted
    )
    add_build_summary(
      details,
      { "turret-xp.build-mode-core" },
      { "turret-xp.build-mode-points-value", target.core_points or 0, target.core_total or 0 },
      COLOR.build_mode_muted
    )
    add_build_summary(
      details,
      { "turret-xp.build-mode-augments" },
      { "turret-xp.build-mode-points-value", target.augment_points or 0, target.augment_total or 0 },
      COLOR.build_mode_muted
    )
    add_build_summary(details, { "turret-xp.build-mode-specialization" }, target.choice and target.choice ~= "" and target.choice or "-")
    add_build_summary(details, { "turret-xp.build-mode-elements" }, target.elements and target.elements ~= "" and target.elements or "-")
  end

  local function add_platform_installed(parent)
    local row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "vertical_align", "center")
    local label = row.add({
      type = "label",
      caption = { "turret-xp.platform-core-installed" },
      style = "caption_label",
    })
    set_style(label, "font_color", COLOR.muted)
    row.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })
    widgets.add_tool_button(row, {
      sprite = "utility/export_slot",
      tooltip = { "turret-xp.platform-core-send-tooltip" },
      tags = {
        turret_xp_action = "platform-send-core",
      },
    })
  end

  local function add_platform_option(parent, entity, option)
    local profile = option.profile or create_blank_profile()
    local row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "vertical_align", "center")
    set_style(row, "horizontal_spacing", 8)

    local icon = row.add({
      type = "sprite-button",
      sprite = "item/" .. CHIP_NAME,
      quality = option.quality or profile.chip_quality or "normal",
      elem_tooltip = {
        type = "item-with-quality",
        name = CHIP_NAME,
        quality = option.quality or profile.chip_quality or "normal",
      },
    })
    set_element_style(icon, "slot_button")
    set_fixed_size(icon, LAYOUT.platform_core_icon_size)

    local details = row.add({
      type = "flow",
      direction = "vertical",
    })
    set_fixed_width(details, LAYOUT.platform_core_row_detail_width)
    local name = details.add({
      type = "label",
      caption = core_name(profile, { "turret-xp.platform-core-unnamed" }),
      style = "caption_label",
    })
    set_style(name, "font", "default-bold")
    set_wrapped_width(name, LAYOUT.platform_core_row_detail_width)

    local summary = details.add({
      type = "label",
      caption = { "turret-xp.platform-core-summary", tostring(profile.level or 0), specialization_caption(profile) },
      style = "caption_label",
    })
    set_style(summary, "font_color", COLOR.muted)
    set_wrapped_width(summary, LAYOUT.platform_core_row_detail_width)

    local stats = preview_stats(entity, profile)
    local stat_summary = details.add({
      type = "label",
      caption = {
        "turret-xp.inventory-core-compact-stats",
        plain_metric({ "turret-xp.inventory-core-stat-hp" }, stats.health),
        plain_metric({ "turret-xp.inventory-core-stat-attack" }, stats.speed, "/s"),
        plain_metric({ "turret-xp.inventory-core-stat-range" }, stats.range),
      },
      style = "caption_label",
    })
    set_style(stat_summary, "font_color", COLOR.muted)
    set_wrapped_width(stat_summary, LAYOUT.platform_core_row_detail_width)

    row.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })
    widgets.add_tool_button(row, {
      sprite = "utility/import_slot",
      style = "flib_tool_button_light_green",
      tooltip = { "turret-xp.platform-core-install-tooltip" },
      tags = {
        turret_xp_action = "platform-install-core",
        slot = option.index,
      },
    })
  end

  local function build_core_key(player, state, entity)
    entity = entity or get_remembered_turret(player)
    if state then
      return table.concat({
        "installed",
        tostring(state.chip_id or ""),
        tostring(state.level or 0),
        tostring(state.custom_name or ""),
        tostring(state.chip_quality or "normal"),
        tostring(state.bound_turret == true),
        tostring(profile_automation.build_mode_active(state)),
        tostring(get_platform_hub_inventory(entity) ~= nil),
      }, ":")
    end

    local host = get_turret_host(entity, false)
    local request_status = core_requester.status(entity)
    local target = profile_automation.target_model(host and host.pending_policy or nil) or {}
    return table.concat({
      "empty",
      tostring(dev_controls_enabled(player)),
      tostring(host and host.request_core == true),
      tostring(request_status.requester_valid == true),
      tostring(request_status.delivered == true),
      tostring(request_status.network == true),
      tostring(host and type(host.pending_policy) == "table"),
      tostring(target.level or ""),
    }, ":")
  end

  local function build_label_key(state)
    if not state then
      return "empty"
    end
    local color = state.label_color or {}
    return table.concat({
      "label",
      tostring(profile_automation.build_mode_active(state)),
      tostring(state.custom_name or ""),
      tostring(state.show_name_label == true),
      tostring(state.show_label_level == true),
      tostring(state.show_unspent_label == true),
      tostring(state.label_color_preset or ""),
      tostring(color[1] or ""),
      tostring(color[2] or ""),
      tostring(color[3] or ""),
    }, ":")
  end

  local function build_panel_key(state)
    if not state then
      return "empty"
    end
    local target = profile_automation.target_model(state) or {}
    return table.concat({
      "build",
      tostring(state.automation_enabled == true),
      tostring(profile_automation.build_mode_active(state)),
      tostring(profile_automation.target_unfinished(state)),
      tostring(target.level or ""),
      tostring(target.core or ""),
      tostring(target.core_infinite or ""),
      tostring(target.augments or ""),
      tostring(target.augment_infinite or ""),
      tostring(target.choice or ""),
      tostring(target.elements or ""),
    }, ":")
  end

  local function core_panel_key(player, state)
    return build_core_key(player, state)
  end

  local function add_core_panel(parent, mode)
    return add_stack_section(parent, {
      name = GUI.core,
      role = "core",
      mode = mode,
      vertical_spacing = 6,
    })
  end

  local function add_label_panel(parent)
    return add_stack_section(parent, {
      name = GUI.core_label_section,
      role = "label",
      title = { "turret-xp.label-name" },
      mode = "installed",
    })
  end

  local function add_build_panel(parent)
    return add_stack_section(parent, {
      name = GUI.core_build_controls_container,
      role = "build",
      mode = "installed",
      vertical_spacing = 6,
    })
  end

  local function add_xp_panel(parent)
    local panel = add_stack_section(parent, {
      name = GUI.xp_panel,
      role = "level",
      mode = "installed",
      vertical_spacing = 6,
    })

    local header = add_header(panel, {})
    local level = header.add({
      type = "label",
      name = GUI.level,
      caption = { "turret-xp.level", 0 },
      style = "heading_2_label",
    })
    set_style(level, "font", "default-bold")
    set_style(level, "font_color", COLOR.section_header)
    header.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    local row = panel.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "vertical_align", "center")
    set_style(row, "horizontal_spacing", 6)

    local percent = row.add({
      type = "label",
      name = GUI.xp_percent,
      caption = "",
      style = "caption_label",
    })
    set_style(percent, "font_color", COLOR.muted)

    row.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    local xp = row.add({
      type = "label",
      name = GUI.xp,
      caption = { "turret-xp.xp-progress", 0, 0 },
      style = "caption_label",
    })
    set_style(xp, "font_color", COLOR.muted)

    local bar = panel.add({
      type = "progressbar",
      name = GUI.xp_bar,
      style = "turret_xp_xp_progressbar",
      value = 0,
    })
    set_style(bar, "horizontally_stretchable", true)
    set_style(bar, "height", 18)

    local modifiers = panel.add({
      type = "label",
      name = GUI.xp_modifiers,
      caption = "",
      style = "caption_label",
    })
    modifiers.visible = false
    set_style(modifiers, "font_color", COLOR.muted)
    set_wrapped_width(modifiers, LAYOUT.left_section_width - 16)
  end

  local function add_inventory_core_panel(parent)
    return add_stack_section(parent, {
      name = GUI.inventory_cores,
      role = "inventory",
      title = { "turret-xp.inventory-core-title" },
      mode = "empty",
      vertical_spacing = 6,
    })
  end

  local function add_platform_core_panel(parent)
    return add_stack_section(parent, {
      name = GUI.platform_cores,
      role = "platform",
      title = { "turret-xp.platform-core-title" },
      mode = "empty",
      vertical_spacing = 6,
    })
  end

  local function add_dev_controls_panel(parent, player)
    if not dev_controls_enabled(player) then
      return nil
    end

    local panel = add_stack_section(parent, {
      name = GUI.dev,
      role = "dev",
      title = { "turret-xp.dev-title" },
      mode = "installed",
      vertical_spacing = 6,
    })

    local buttons = panel.add({
      type = "table",
      column_count = 4,
    })
    set_style(buttons, "horizontally_stretchable", true)
    set_style(buttons, "horizontal_spacing", 4)
    set_style(buttons, "vertical_spacing", 4)

    local function add_level_button(caption, tooltip, levels)
      local button = buttons.add({
        type = "button",
        caption = caption,
        tooltip = tooltip,
        tags = {
          turret_xp_action = "dev-level",
          levels = levels,
        },
      })
      set_style(button, "minimal_width", 44)
    end

    add_level_button({ "turret-xp.dev-level-1" }, { "turret-xp.dev-level-1-tooltip" }, 1)
    add_level_button({ "turret-xp.dev-level-5" }, { "turret-xp.dev-level-5-tooltip" }, 5)
    add_level_button({ "turret-xp.dev-level-100" }, { "turret-xp.dev-level-100-tooltip" }, 100)
    widgets.add_tool_button(buttons, {
      sprite = "utility/add",
      style = "flib_tool_button_light_green",
      tooltip = { "turret-xp.dev-create-core-tooltip" },
      tags = {
        turret_xp_action = "dev-create-core",
      },
    })
    add_level_button({ "turret-xp.dev-level-minus-1" }, { "turret-xp.dev-level-minus-1-tooltip" }, -1)
    add_level_button({ "turret-xp.dev-level-minus-5" }, { "turret-xp.dev-level-minus-5-tooltip" }, -5)
    widgets.add_tool_button(buttons, {
      sprite = "utility/confirm_slot",
      style = "flib_tool_button_light_green",
      tooltip = { "turret-xp.dev-materials-tooltip" },
      tags = {
        turret_xp_action = "dev-complete-element-rank",
      },
    })
    widgets.add_tool_button(buttons, {
      sprite = "utility/reset",
      style = "flib_tool_button_dark_red",
      tooltip = { "turret-xp.dev-reset-core-tooltip" },
      tags = {
        turret_xp_action = "dev-reset-core",
      },
    })
    return panel
  end

  local function update_core_panel(root, player, entity, state)
    local panel = find_gui_element(root, GUI.core)
    if not panel then
      return
    end

    local build_mode = state and profile_automation.build_mode_active(state) or false
    set_section_mode(panel, "core", build_mode)
    local key = build_core_key(player, state, entity)
    if panel.tags and panel.tags.key == key then
      if state then
        update_name_render(entity, state)
      end
      return
    end

    panel.clear()
    panel.tags.key = key

    local host = not state and get_turret_host(entity, false) or nil
    local pending = not state and host and host.request_core == true and type(host.pending_policy) == "table"
    local header = add_header(panel, {
      name = GUI.core_header,
      build_mode = build_mode,
      spacing = 6,
      height = 46,
    })
    add_core_slot(header, state, {
      pending = pending,
    })
    add_core_details(header, state, {
      pending = pending,
    })
    add_core_actions(header, player, state)

    if state then
      if get_platform_hub_inventory(entity) then
        add_platform_installed(panel)
      end
      update_name_render(entity, state)
      return
    end

    if pending then
      add_pending_build_summary(panel, entity)
      return
    end

    local note = panel.add({
      type = "label",
      caption = { "turret-xp.no-core-note" },
      style = "caption_label",
    })
    set_style(note, "font_color", COLOR.muted)
    set_wrapped_width(note, section_width("empty") - 16)
  end

  local function update_label_panel(root, state)
    local panel = find_gui_element(root, GUI.core_label_section)
    if not panel then
      return
    end

    local build_mode = state and profile_automation.build_mode_active(state) or false
    set_section_mode(panel, "label", build_mode)
    local key = build_label_key(state)
    if panel.tags and panel.tags.key == key then
      return
    end

    panel.clear()
    panel.tags.key = key
    if state then
      local header = add_header(panel, {
        build_mode = build_mode,
      })
      local title = header.add({
        type = "label",
        caption = { "turret-xp.label-name" },
        style = "heading_2_label",
      })
      set_style(title, "font", "default-bold")
      set_style(title, "font_color", build_mode and COLOR.build_mode or COLOR.section_header)
      header.add({
        type = "empty-widget",
        style = "flib_horizontal_pusher",
      })
      add_label_controls(panel, state)
    end
  end

  local function update_build_panel(root, state)
    local panel = find_gui_element(root, GUI.core_build_controls_container)
    if not panel then
      return
    end

    local build_mode = state and profile_automation.build_mode_active(state) or false
    set_section_mode(panel, "build", build_mode)
    local key = build_panel_key(state)
    if panel.tags and panel.tags.key == key then
      return
    end

    panel.clear()
    panel.tags.key = key
    if state then
      add_build_contents(panel, state)
    end
  end

  local function update_inventory_core_panel(root, player, entity, state)
    local panel = find_gui_element(root, GUI.inventory_cores)
    if not panel then
      return
    end

    if state then
      panel.visible = false
      return
    end

    local host = get_turret_host(entity, false)
    if host and host.request_core == true and type(host.pending_policy) == "table" then
      panel.visible = false
      return
    end
    panel.visible = true

    local model = picker_model(player, entity)
    if panel.tags and panel.tags.key == model.key then
      return
    end

    panel.clear()
    set_section_mode(panel, "inventory", false)
    panel.tags.key = model.key

    local header = add_header(panel, {})
    local sample = header.add({
      type = "sprite-button",
      sprite = "item/" .. CHIP_NAME,
      quality = "normal",
      tooltip = { "turret-xp.inventory-core-title" },
      elem_tooltip = {
        type = "item-with-quality",
        name = CHIP_NAME,
        quality = "normal",
      },
    })
    set_element_style(sample, "slot_button")
    set_fixed_size(sample, LAYOUT.inventory_core_sample_slot_size)

    local title = header.add({
      type = "label",
      caption = { "turret-xp.inventory-core-title" },
      style = "heading_2_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "font_color", COLOR.section_header)
    header.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })
    local count = header.add({
      type = "label",
      caption = #model.options == #model.all_options and { "turret-xp.inventory-core-count", #model.options }
        or { "turret-xp.inventory-core-count-filtered", #model.options, #model.all_options },
      style = "caption_label",
    })
    set_style(count, "font_color", COLOR.muted)

    add_filter_row(panel, model.filters)
    add_inventory_rows(panel, entity, model)
  end

  local function update_platform_core_panel(root, entity, state)
    local panel = find_gui_element(root, GUI.platform_cores)
    if not panel then
      return
    end

    if state or not get_platform_hub_inventory(entity) then
      panel.visible = false
      return
    end
    panel.visible = true

    local options = get_platform_core_options(entity)
    local key = "platform:" .. option_key(options)
    if panel.tags and panel.tags.key == key then
      return
    end

    panel.clear()
    set_section_mode(panel, "platform", false)
    panel.tags.key = key

    local header = add_header(panel, {})
    local title = header.add({
      type = "label",
      caption = { "turret-xp.platform-core-title" },
      style = "heading_2_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "font_color", COLOR.section_header)
    header.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })
    if #options > 0 then
      local count = header.add({
        type = "label",
        caption = { "turret-xp.inventory-core-count", #options },
        style = "caption_label",
      })
      set_style(count, "font_color", COLOR.muted)
    end

    if #options == 0 then
      local empty = panel.add({
        type = "label",
        caption = { "turret-xp.platform-core-empty" },
        style = "caption_label",
      })
      set_style(empty, "font_color", COLOR.muted)
      set_wrapped_width(empty, section_width("empty") - 16)
      return
    end

    for index, option in ipairs(options) do
      if index > 1 then
        local line = panel.add({
          type = "line",
          direction = "horizontal",
        })
        set_style(line, "horizontally_stretchable", true)
      end
      add_platform_option(panel, entity, option)
    end
  end

  local function add_inventory_core_picker(parent, player, entity, options)
    local panel = find_gui_element(parent, GUI.inventory_cores) or add_inventory_core_panel(parent)
    panel.clear()
    local model = options and options.model or picker_model(player, entity)
    add_filter_row(panel, model.filters)
    add_inventory_rows(panel, entity, model)
    return panel
  end

  local function add_platform_core_list(parent, entity, state)
    local panel = find_gui_element(parent, GUI.platform_cores) or add_platform_core_panel(parent)
    update_platform_core_panel(parent, entity, state)
    return panel
  end

  return {
    add_xp_panel = add_xp_panel,
    add_core_panel = add_core_panel,
    add_label_panel = add_label_panel,
    add_build_panel = add_build_panel,
    add_inventory_core_panel = add_inventory_core_panel,
    add_platform_core_panel = add_platform_core_panel,
    core_panel_key = core_panel_key,
    add_inventory_core_picker = add_inventory_core_picker,
    add_platform_core_list = add_platform_core_list,
    add_dev_controls_panel = add_dev_controls_panel,
    update_core_panel = update_core_panel,
    update_label_panel = update_label_panel,
    update_build_panel = update_build_panel,
    update_inventory_core_panel = update_inventory_core_panel,
    update_platform_core_panel = update_platform_core_panel,
    prepare_core_options_for_display = prepare_core_options_for_display,
  }
end

return core_panel_module
