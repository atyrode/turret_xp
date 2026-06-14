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
  local get_player_core_options = deps.get_player_core_options
  local get_player_core_options_model = deps.get_player_core_options_model
  local get_core_picker_sort = deps.get_core_picker_sort
  local get_core_picker_filters = deps.get_core_picker_filters
  local core_picker_filters_key = deps.core_picker_filters_key
  local get_platform_core_options = deps.get_platform_core_options
  local get_platform_hub_inventory = deps.get_platform_hub_inventory
  local create_blank_profile = deps.create_blank_profile
  local dev_controls_enabled = deps.dev_controls_enabled
  local update_name_render = deps.update_name_render
  local find_matching_label_color_preset = deps.find_matching_label_color_preset
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
  local rich_value = deps.rich_value
  local rich_metric = deps.rich_metric
  local rich_specialization_caption = deps.rich_specialization_caption
  local widgets = deps.widgets
  local core_picker_table = deps.core_picker_table
  local core_identity = deps.core_identity

  local function add_xp_panel(parent)
    local xp_panel = parent.add({
      type = "frame",
      direction = "vertical",
      style = "deep_frame_in_shallow_frame",
    })
    set_style(xp_panel, "horizontally_stretchable", true)
    set_style(xp_panel, "padding", { 8, 8, 8, 8 })

    local top = xp_panel.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(top, "horizontally_stretchable", true)
    set_style(top, "vertical_align", "center")
    set_style(top, "horizontal_spacing", 6)

    local level = top.add({
      type = "label",
      name = GUI.level,
      caption = { "turret-xp.level", 0 },
      style = "heading_2_label",
    })
    set_style(level, "font", "default-bold")

    local percent = top.add({
      type = "label",
      name = GUI.xp_percent,
      caption = "",
      style = "caption_label",
    })
    set_style(percent, "font_color", COLOR.muted)
    set_style(percent, "left_margin", 0)

    top.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    local xp = top.add({
      type = "label",
      name = GUI.xp,
      caption = { "turret-xp.xp-progress", 0, 0 },
      style = "caption_label",
    })
    set_style(xp, "font_color", COLOR.muted)

    local bar = xp_panel.add({
      type = "progressbar",
      name = GUI.xp_bar,
      style = "turret_xp_xp_progressbar",
      value = 0,
    })
    set_style(bar, "horizontally_stretchable", true)
    set_style(bar, "height", 18)
    set_style(bar, "top_margin", 4)
    set_style(bar, "bottom_margin", 0)
  end

  local function add_core_panel(parent, mode)
    local core_panel = parent.add({
      type = "frame",
      name = GUI.core,
      direction = "vertical",
      style = "deep_frame_in_shallow_frame",
    })
    set_style(core_panel, "horizontally_stretchable", true)
    set_style(core_panel, "padding", { 8, 8, 8, 8 })
    set_style(core_panel, "bottom_margin", mode == "empty" and 0 or 6)
    return core_panel
  end

  local function core_options_key(options)
    local parts = {}
    for _, option in ipairs(options or {}) do
      local profile = option.profile or {}
      local evolution = ensure_evolution_state(profile)
      parts[#parts + 1] = table.concat({
        tostring(option.index or ""),
        tostring(profile.chip_id or ""),
        tostring(profile.level or 0),
        tostring(profile.kills or 0),
        tostring(math.floor(tonumber(profile.damage) or 0)),
        tostring(profile.custom_name or ""),
        tostring(profile.chip_quality or option.quality or "normal"),
        tostring(evolution.specialization or ""),
        tostring(evolution.sub_specialization or ""),
      }, "/")
    end
    return table.concat(parts, "|")
  end

  local function build_empty_core_picker_model(player, entity)
    local sort_mode = get_core_picker_sort(player)
    local core_filters = get_core_picker_filters(player)
    local inventory_model = get_player_core_options_model(player, sort_mode, core_filters)
    local all_inventory_core_options = inventory_model.all_options or {}
    local inventory_core_options = inventory_model.options or {}

    local model = {
      sort_mode = sort_mode,
      filters = core_filters,
      all_options = all_inventory_core_options,
      options = inventory_core_options,
    }
    model.key = table.concat({
      sort_mode,
      "filters",
      core_picker_filters_key(core_filters),
      "all",
      core_options_key(all_inventory_core_options),
      "inventory",
      core_options_key(inventory_core_options),
    }, ":")
    return model
  end

  local function core_panel_key_and_model(player, state, entity)
    entity = entity or get_remembered_turret(player)
    local empty_picker_model
    local platform_core_count = #get_platform_core_options(entity)
    local platform_inventory_present = get_platform_hub_inventory(entity) ~= nil
    if state then
      local color = state.label_color or {}
      return table.concat({
        "installed",
        tostring(state.chip_id or ""),
        tostring(state.bound_turret == true),
        tostring(state.show_name_label == true),
        tostring(state.show_label_level ~= false),
        tostring(platform_inventory_present),
        tostring(state.label_color_preset or ""),
        tostring(color[1] or ""),
        tostring(color[2] or ""),
        tostring(color[3] or ""),
      }, ":")
    end

    empty_picker_model = build_empty_core_picker_model(player, entity)
    local picker_key = "picker:"
      .. empty_picker_model.key
      .. ":quality:"
      .. tostring(get_entity_quality_name(entity))
      .. ":ammo:"
      .. tostring(get_loaded_ammo(entity))
    local base_key = table.concat({
      "empty",
      tostring(dev_controls_enabled(player)),
      tostring(platform_inventory_present),
      tostring(platform_core_count),
    }, ":")
    return base_key .. ":" .. picker_key, empty_picker_model, base_key, picker_key
  end

  local function core_panel_key(player, state)
    local key = core_panel_key_and_model(player, state)
    return key
  end

  local function core_display_name(profile, fallback)
    local name = profile and profile.custom_name or nil
    if name and name ~= "" then
      return name
    end

    return fallback or { "turret-xp.inventory-core-unnamed" }
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

  local function core_filter_modes()
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

  local function filter_checkbox_state(current_filters, filter_id)
    if filter_id == "all" then
      return current_filters.all == true
    end

    return current_filters.all ~= true and current_filters[filter_id] == true
  end

  local function filter_caption(mode)
    if mode.id == "all" then
      return mode.caption
    end

    return rich_specialization_caption(mode.id, mode.caption)
  end

  local function add_inventory_core_filter_controls(parent, current_filters)
    local filter_flow = parent.add({
      type = "flow",
      name = GUI.inventory_core_filters,
      direction = "horizontal",
    })
    set_style(filter_flow, "top_margin", 4)
    set_style(filter_flow, "horizontal_spacing", 8)
    set_style(filter_flow, "vertical_align", "center")
    set_style(filter_flow, "horizontally_stretchable", true)

    local label = filter_flow.add({
      type = "label",
      caption = { "turret-xp.inventory-core-filter" },
      style = "caption_label",
    })
    set_style(label, "font_color", COLOR.caption)
    set_style(label, "right_margin", 2)

    for _, mode in ipairs(core_filter_modes()) do
      local checkbox = filter_flow.add({
        type = "checkbox",
        caption = filter_caption(mode),
        tooltip = mode.tooltip,
        state = filter_checkbox_state(current_filters, mode.id),
        tags = {
          turret_xp_action = "set-core-filter",
          filter = mode.id,
        },
      })
      set_style(checkbox, "font", "default")
    end
  end

  local function add_narrow_inventory_core_row(rows, option, profile, stats, detail_width)
    local row = rows.add({
      type = "table",
      column_count = 3,
    })
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "horizontal_spacing", 8)
    set_style(row, "vertical_spacing", 0)
    pcall(function()
      row.style.column_alignments[1] = "left"
      row.style.column_alignments[2] = "left"
      row.style.column_alignments[3] = "right"
    end)

    local button_definition = {
      type = "sprite-button",
      sprite = "item/" .. CHIP_NAME,
      quality = option.quality or profile.chip_quality or "normal",
      number = (profile.level or 0) > 0 and profile.level or nil,
      tooltip = { "turret-xp.inventory-core-install-tooltip" },
      elem_tooltip = {
        type = "item-with-quality",
        name = CHIP_NAME,
        quality = option.quality or profile.chip_quality or "normal",
      },
      tags = {
        turret_xp_action = "inventory-install-core",
        slot = option.index,
      },
    }
    local icon = row.add(button_definition)
    set_element_style(icon, "slot_button")
    set_style(icon, "size", 36)

    local details = row.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(details, "horizontally_stretchable", true)
    set_style(details, "width", detail_width)
    set_style(details, "minimal_width", detail_width)
    set_style(details, "maximal_width", detail_width)

    local name = details.add({
      type = "label",
      caption = { "turret-xp.inventory-core-name", core_display_name(profile), rich_value(profile.level or 0) },
      style = "caption_label",
    })
    set_style(name, "font", "default-bold")
    set_style(name, "single_line", false)
    set_style(name, "maximal_width", detail_width)

    local specialization = details.add({
      type = "label",
      caption = specialization_caption(profile),
      style = "caption_label",
    })
    set_style(specialization, "font_color", COLOR.muted)
    set_style(specialization, "single_line", false)
    set_style(specialization, "maximal_width", detail_width)

    local stat_summary = details.add({
      type = "label",
      caption = {
        "turret-xp.inventory-core-compact-stats",
        rich_metric({ "turret-xp.inventory-core-stat-hp" }, stats.health),
        rich_metric({ "turret-xp.inventory-core-stat-attack" }, stats.speed, "/s"),
        rich_metric({ "turret-xp.inventory-core-stat-range" }, stats.range),
      },
      style = "caption_label",
    })
    set_style(stat_summary, "font_color", COLOR.muted)
    set_style(stat_summary, "single_line", false)
    set_style(stat_summary, "maximal_width", detail_width)

    widgets.add_tool_button(row, {
      sprite = "utility/add",
      style = "flib_tool_button_light_green",
      tooltip = { "turret-xp.inventory-core-install-tooltip" },
      tags = {
        turret_xp_action = "inventory-install-core",
        slot = option.index,
      },
    })
  end

  local function core_option_name_key(profile)
    local raw_name = tostring((profile or {}).custom_name or "")
    local normalized_name = raw_name:gsub("^%s+", ""):gsub("%s+$", "")
    return normalized_name ~= "", string.lower(normalized_name)
  end

  local function core_option_specialization_key(profile)
    local specialization = get_specialization(profile)
    if not specialization then
      return "base"
    end

    local sub_specialization = get_sub_specialization(profile)
    local key = tostring(specialization.name or specialization.id or "")
    if sub_specialization then
      key = key .. " / " .. tostring(sub_specialization.name or sub_specialization.id or "")
    end
    return string.lower(key)
  end

  local function compare_number(left, right, field, direction)
    local left_value = left.sort_key[field]
    local right_value = right.sort_key[field]
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
    if left_value ~= right_value then
      if direction == "asc" then
        return left_value < right_value
      end
      return left_value > right_value
    end
    return nil
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

  local function prepare_core_options_for_display(entity, option_list, current_sort)
    local field, direction = core_picker_table.parse_sort(current_sort)
    for _, option in ipairs(option_list or {}) do
      local profile = option.profile or create_blank_profile()
      local stats = preview_stats(entity, profile)
      local has_name, name = core_option_name_key(profile)
      option.preview_stats = stats
      option.sort_key = {
        level = math.max(0, math.floor(tonumber(profile.level) or 0)),
        hp = stats.sort.hp,
        attack = stats.sort.attack,
        range = stats.sort.range,
        has_name = has_name,
        name = name,
        specialization = core_option_specialization_key(profile),
        chip_id = tonumber(profile.chip_id) or 0,
      }
    end

    if not field then
      return option_list
    end

    table.sort(option_list, function(left, right)
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

    return option_list
  end

  local function wide_inventory_core_row_data(option, profile, stats)
    local function value_caption(value, suffix)
      return tostring(value or "-") .. tostring(suffix or "")
    end

    return {
      install_tooltip = { "turret-xp.inventory-core-install-tooltip" },
      install_tags = {
        turret_xp_action = "inventory-install-core",
        slot = option.index,
      },
      name_caption = core_display_name(profile),
      specialization_caption = specialization_caption(profile),
      level_caption = value_caption(profile.level or 0),
      hp_caption = value_caption(stats.health),
      attack_caption = value_caption(stats.speed, "/s"),
      range_caption = value_caption(stats.range),
    }
  end

  local function populate_inventory_core_picker(frame, player, entity, options)
    options = options or {}
    if not frame or not frame.valid then
      return
    end

    local wide = options.wide == true
    local picker_model = options.model or nil
    local current_sort = picker_model and picker_model.sort_mode or get_core_picker_sort(player)
    local current_filters = picker_model and picker_model.filters or get_core_picker_filters(player)
    local all_core_options = picker_model and picker_model.all_options or get_player_core_options(player, current_sort)
    local core_options = picker_model and picker_model.options or get_player_core_options(player, current_sort, current_filters)
    local picker_width = wide and LAYOUT.empty_inventory_core_picker_width or LAYOUT.inventory_core_picker_width
    local picker_height = wide and LAYOUT.empty_inventory_core_picker_height or LAYOUT.inventory_core_picker_height
    local detail_width = wide and LAYOUT.empty_inventory_core_detail_width or LAYOUT.inventory_core_detail_width

    frame.clear()
    frame.tags = {
      picker_key = options.picker_key or "",
    }

    set_style(frame, "horizontally_stretchable", true)

    local header = frame.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(header, "horizontally_stretchable", true)
    set_style(header, "vertical_align", "center")
    set_style(header, "horizontal_spacing", 6)

    if wide then
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
      set_style(sample, "size", LAYOUT.inventory_core_sample_slot_size)
    end

    local title = header.add({
      type = "label",
      caption = { "turret-xp.inventory-core-title" },
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")

    header.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    local count = header.add({
      type = "label",
      caption = #core_options == #all_core_options and { "turret-xp.inventory-core-count", #core_options }
        or { "turret-xp.inventory-core-count-filtered", #core_options, #all_core_options },
      style = "caption_label",
    })
    set_style(count, "font_color", COLOR.muted)

    if wide then
      add_inventory_core_filter_controls(frame, current_filters)
    end

    local scroll = frame.add({
      type = "scroll-pane",
      direction = "vertical",
      style = wide and "flib_naked_scroll_pane_no_padding" or "flib_naked_scroll_pane",
    })
    scroll.vertical_scroll_policy = wide and "always" or "auto-and-reserve-space"
    scroll.horizontal_scroll_policy = "never"
    set_style(scroll, "top_margin", 4)
    set_style(scroll, "height", picker_height)
    set_style(scroll, "width", picker_width)
    set_style(scroll, "minimal_width", picker_width)
    set_style(scroll, "maximal_width", picker_width)

    prepare_core_options_for_display(entity, core_options, current_sort)

    if #core_options == 0 then
      local label = scroll.add({
        type = "label",
        caption = #all_core_options == 0 and { "turret-xp.inventory-core-empty" } or { "turret-xp.inventory-core-filter-empty" },
        style = "caption_label",
      })
      set_style(label, "margin", { 8, 8, 8, 8 })
      set_style(label, "font_color", COLOR.muted)
      set_style(label, "single_line", false)
      set_style(label, "maximal_width", picker_width - 36)
      return
    end

    if wide then
      local table_element = core_picker_table.add(scroll, current_sort)

      for _, option in ipairs(core_options) do
        local profile = option.profile or create_blank_profile()
        local stats = option.preview_stats or preview_stats(entity, profile)
        core_picker_table.add_row(table_element, wide_inventory_core_row_data(option, profile, stats))
      end
    else
      local rows = scroll.add({
        type = "flow",
        direction = "vertical",
      })
      set_style(rows, "vertical_spacing", 4)
      set_style(rows, "horizontally_stretchable", true)

      for index, option in ipairs(core_options) do
        if index > 1 then
          local delimiter = rows.add({
            type = "line",
            direction = "horizontal",
          })
          set_style(delimiter, "horizontally_stretchable", true)
          set_style(delimiter, "top_margin", 2)
          set_style(delimiter, "bottom_margin", 2)
        end

        local profile = option.profile or create_blank_profile()
        local stats = option.preview_stats or preview_stats(entity, profile)
        add_narrow_inventory_core_row(rows, option, profile, stats, detail_width)
      end
    end
  end

  local function add_inventory_core_picker(core_panel, player, entity, options)
    options = options or {}
    local frame_definition = {
      type = "frame",
      name = GUI.inventory_cores,
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    }

    local frame = core_panel.add(frame_definition)
    set_style(frame, "top_margin", 6)
    set_style(frame, "horizontally_stretchable", true)
    populate_inventory_core_picker(frame, player, entity, options)
  end

  local function refresh_inventory_core_picker(core_panel, player, entity, model, picker_key)
    local frame = find_gui_element(core_panel, GUI.inventory_cores)
    if not frame or not frame.valid then
      return false
    end

    if (frame.tags or {}).picker_key == picker_key then
      return true
    end

    populate_inventory_core_picker(frame, player, entity, {
      wide = true,
      model = model,
      picker_key = picker_key,
    })
    return true
  end

  local function add_platform_core_list(core_panel, entity, state)
    local hub_inventory = get_platform_hub_inventory(entity)
    if not hub_inventory then
      return
    end

    local frame = core_panel.add({
      type = "frame",
      name = GUI.platform_cores,
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_style(frame, "top_margin", 6)
    set_style(frame, "horizontally_stretchable", true)

    if state then
      local flow = frame.add({
        type = "flow",
        direction = "horizontal",
      })
      set_style(flow, "horizontally_stretchable", true)
      set_style(flow, "vertical_align", "center")
      local label = flow.add({
        type = "label",
        caption = { "turret-xp.platform-core-installed" },
        style = "caption_label",
      })
      set_style(label, "font_color", COLOR.muted)
      flow.add({
        type = "empty-widget",
        style = "flib_horizontal_pusher",
      })
      widgets.add_tool_button(flow, {
        sprite = "utility/export_slot",
        tooltip = { "turret-xp.platform-core-send-tooltip" },
        tags = {
          turret_xp_action = "platform-send-core",
        },
      })
      return
    end

    local options = get_platform_core_options(entity)
    if #options == 0 then
      local label = frame.add({
        type = "label",
        caption = { "turret-xp.platform-core-empty" },
        style = "caption_label",
      })
      set_style(label, "font_color", COLOR.muted)
      set_style(label, "single_line", false)
      return
    end

    local title = frame.add({
      type = "label",
      caption = { "turret-xp.platform-core-title" },
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")

    for _, option in ipairs(options) do
      local profile = option.profile or create_blank_profile()
      local row = frame.add({
        type = "table",
        column_count = 3,
      })
      set_style(row, "horizontally_stretchable", true)
      set_style(row, "horizontal_spacing", 8)
      set_style(row, "vertical_spacing", 2)
      pcall(function()
        row.style.column_alignments[1] = "left"
        row.style.column_alignments[2] = "left"
        row.style.column_alignments[3] = "right"
      end)

      local button_definition = {
        type = "sprite-button",
        sprite = "item/" .. CHIP_NAME,
        quality = option.quality or profile.chip_quality or "normal",
        elem_tooltip = {
          type = "item-with-quality",
          name = CHIP_NAME,
          quality = option.quality or profile.chip_quality or "normal",
        },
      }
      local icon = row.add(button_definition)
      set_element_style(icon, "slot_button")
      set_style(icon, "size", 34)

      local details = row.add({
        type = "flow",
        direction = "vertical",
      })
      set_style(details, "horizontally_stretchable", true)
      local core_name = profile.custom_name and profile.custom_name ~= "" and profile.custom_name or { "turret-xp.platform-core-unnamed" }
      local name = details.add({
        type = "label",
        caption = core_name,
        style = "caption_label",
      })
      set_style(name, "font", "default-bold")
      local stats = preview_stats(entity, profile)
      local summary = details.add({
        type = "label",
        caption = { "turret-xp.platform-core-summary", rich_value(profile.level or 0), specialization_caption(profile) },
        style = "caption_label",
      })
      set_style(summary, "font_color", COLOR.muted)
      local stat_summary = details.add({
        type = "label",
        caption = {
          "turret-xp.inventory-core-compact-stats",
          rich_metric({ "turret-xp.inventory-core-stat-hp" }, stats.health),
          rich_metric({ "turret-xp.inventory-core-stat-attack" }, stats.speed, "/s"),
          rich_metric({ "turret-xp.inventory-core-stat-range" }, stats.range),
        },
        style = "caption_label",
      })
      set_style(stat_summary, "font_color", COLOR.muted)
      set_style(stat_summary, "single_line", false)

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
  end

  local function add_dev_controls_panel(parent, player)
    if not dev_controls_enabled(player) then
      return nil
    end

    local panel = parent.add({
      type = "frame",
      name = GUI.dev,
      direction = "vertical",
      style = "deep_frame_in_shallow_frame",
    })
    set_style(panel, "horizontally_stretchable", true)
    set_style(panel, "padding", { 6, 6, 6, 6 })
    set_style(panel, "bottom_margin", 6)
    set_style(panel, "vertical_align", "center")

    local top = panel.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(top, "horizontally_stretchable", true)
    set_style(top, "vertical_align", "center")
    set_style(top, "horizontal_spacing", 6)

    local label = top.add({
      type = "label",
      caption = { "turret-xp.dev-title" },
      style = "caption_label",
    })
    set_style(label, "font", "default-bold")
    set_style(label, "right_margin", 4)

    local buttons = panel.add({
      type = "table",
      column_count = 4,
    })
    set_style(buttons, "horizontally_stretchable", true)
    set_style(buttons, "horizontal_spacing", 4)
    set_style(buttons, "vertical_spacing", 4)

    local level_one = buttons.add({
      type = "button",
      caption = { "turret-xp.dev-level-1" },
      tooltip = { "turret-xp.dev-level-1-tooltip" },
      tags = {
        turret_xp_action = "dev-level",
        levels = 1,
      },
    })
    set_style(level_one, "minimal_width", 44)

    local level_five = buttons.add({
      type = "button",
      caption = { "turret-xp.dev-level-5" },
      tooltip = { "turret-xp.dev-level-5-tooltip" },
      tags = {
        turret_xp_action = "dev-level",
        levels = 5,
      },
    })
    set_style(level_five, "minimal_width", 44)

    local level_hundred = buttons.add({
      type = "button",
      caption = { "turret-xp.dev-level-100" },
      tooltip = { "turret-xp.dev-level-100-tooltip" },
      tags = {
        turret_xp_action = "dev-level",
        levels = 100,
      },
    })
    set_style(level_hundred, "minimal_width", 44)

    widgets.add_tool_button(buttons, {
      sprite = "utility/add",
      style = "flib_tool_button_light_green",
      tooltip = { "turret-xp.dev-create-core-tooltip" },
      tags = {
        turret_xp_action = "dev-create-core",
      },
    })

    local delevel_one = buttons.add({
      type = "button",
      caption = { "turret-xp.dev-level-minus-1" },
      tooltip = { "turret-xp.dev-level-minus-1-tooltip" },
      tags = {
        turret_xp_action = "dev-level",
        levels = -1,
      },
    })
    set_style(delevel_one, "minimal_width", 44)

    local delevel_five = buttons.add({
      type = "button",
      caption = { "turret-xp.dev-level-minus-5" },
      tooltip = { "turret-xp.dev-level-minus-5-tooltip" },
      tags = {
        turret_xp_action = "dev-level",
        levels = -5,
      },
    })
    set_style(delevel_five, "minimal_width", 44)

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
    local core_panel = find_gui_element(root, GUI.core)
    if not core_panel then
      return
    end

    local key, empty_picker_model, base_key, picker_key = core_panel_key_and_model(player, state, entity)
    local tags = core_panel.tags or {}
    if tags.key == key then
      if state then
        update_name_render(entity, state)
      end
      return
    end

    if not state and tags.base_key == base_key then
      if refresh_inventory_core_picker(core_panel, player, entity, empty_picker_model, picker_key) then
        core_panel.tags = {
          key = key,
          base_key = base_key,
          picker_key = picker_key,
        }
        return
      end
    end

    core_panel.clear()
    core_panel.tags = {
      key = key,
      base_key = base_key,
      picker_key = picker_key,
    }

    core_identity.add_header(core_panel, player, state)

    if not state then
      local note = core_panel.add({
        type = "label",
        caption = { "turret-xp.no-core-note" },
        style = "caption_label",
      })
      set_style(note, "top_margin", 6)
      set_style(note, "font_color", COLOR.muted)
      set_style(note, "single_line", false)
      set_style(note, "maximal_width", LAYOUT.empty_panel_width - 24)
      add_inventory_core_picker(core_panel, player, entity, {
        wide = true,
        model = empty_picker_model,
        picker_key = picker_key,
      })
      add_platform_core_list(core_panel, entity, state)
      return
    end

    local name_flow = core_panel.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(name_flow, "top_margin", 4)
    set_style(name_flow, "vertical_align", "center")
    set_style(name_flow, "horizontally_stretchable", true)
    set_style(name_flow, "horizontal_spacing", 8)

    name_flow.add({
      type = "label",
      caption = { "turret-xp.core-name" },
      style = "caption_label",
    })

    local textfield = name_flow.add({
      type = "textfield",
      name = GUI.core_name,
      text = state.custom_name or "",
      clear_and_focus_on_right_click = true,
      lose_focus_on_confirm = true,
    })
    set_style(textfield, "minimal_width", 220)
    set_style(textfield, "horizontally_stretchable", true)

    name_flow.add({
      type = "checkbox",
      name = GUI.core_name_visible,
      caption = { "turret-xp.core-name-show" },
      state = state.show_name_label == true,
      tags = {
        turret_xp_action = "toggle-core-label",
      },
    })

    if state.show_name_label == true then
      local preset = find_matching_label_color_preset(state)
      local label_color = state.label_color or { 1, 0.86, 0.46 }

      local preset_flow = core_panel.add({
        type = "flow",
        direction = "horizontal",
      })
      set_style(preset_flow, "top_margin", 4)
      set_style(preset_flow, "horizontally_stretchable", true)
      set_style(preset_flow, "horizontal_spacing", 6)
      set_style(preset_flow, "vertical_align", "center")
      local swatch = preset_flow.add({
        type = "progressbar",
        name = GUI.core_color_swatch,
        value = 1,
        tooltip = { "turret-xp.label-color-tooltip" },
      })
      set_style(swatch, "width", 22)
      set_style(swatch, "height", 22)
      set_style(swatch, "minimal_width", 22)
      set_style(swatch, "maximal_width", 22)
      set_style(swatch, "bar_width", 22)
      set_style(swatch, "color", label_color)

      local color_button = preset_flow.add({
        type = "button",
        name = GUI.core_color_preview,
        caption = preset and preset.name or { "turret-xp.label-custom-color" },
        tooltip = { "turret-xp.label-color-tooltip" },
        tags = {
          turret_xp_action = "open-label-color-picker",
        },
      })
      set_style(color_button, "font_color", label_color)
      set_style(color_button, "minimal_width", 112)

      local label_options = core_panel.add({
        type = "flow",
        direction = "horizontal",
      })
      set_style(label_options, "top_margin", 4)
      set_style(label_options, "horizontally_stretchable", true)
      label_options.add({
        type = "checkbox",
        name = GUI.core_name_level_visible,
        caption = { "turret-xp.label-level" },
        state = state.show_label_level ~= false,
        tags = {
          turret_xp_action = "toggle-label-level",
        },
      })
    end

    update_name_render(entity, state)
    add_platform_core_list(core_panel, entity, state)
  end

  return {
    add_xp_panel = add_xp_panel,
    add_core_panel = add_core_panel,
    core_panel_key = core_panel_key,
    add_inventory_core_picker = add_inventory_core_picker,
    add_platform_core_list = add_platform_core_list,
    add_dev_controls_panel = add_dev_controls_panel,
    update_core_panel = update_core_panel,
    prepare_core_options_for_display = prepare_core_options_for_display,
  }
end

return core_panel_module
