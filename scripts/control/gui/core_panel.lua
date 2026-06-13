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
  local get_core_picker_sort = deps.get_core_picker_sort
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
  local rich_value = deps.rich_value
  local rich_metric = deps.rich_metric
  local widgets = deps.widgets

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

  local function core_panel_key(player, state)
    local entity = get_remembered_turret(player)
    local platform_core_count = #get_platform_core_options(entity)
    local platform_inventory_present = get_platform_hub_inventory(entity) ~= nil
    local sort_mode = get_core_picker_sort(player)
    local inventory_core_options = get_player_core_options(player, sort_mode)
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

    return "empty:"
      .. sort_mode
      .. ":inventory:"
      .. core_options_key(inventory_core_options)
      .. ":platform:"
      .. tostring(platform_core_count)
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
      return { "turret-xp.inventory-core-no-specialization" }
    end

    local sub_specialization = get_sub_specialization(profile)
    if sub_specialization then
      return { "turret-xp.inventory-core-specialization-sub", specialization.name, sub_specialization.name }
    end

    return specialization.name
  end

  local function preview_stats(entity, profile)
    local quality_name = get_entity_quality_name(entity)
    local max_health = get_max_health_for_quality(entity, quality_name, profile)
    local health_values = get_health_formula_values(entity, profile, quality_name, max_health)
    local ammo_name = get_loaded_ammo(entity)
    local speed_values = get_shooting_speed_formula_values(entity, profile, ammo_name)
    local range_values = get_range_formula_values(entity, profile, quality_name)

    return {
      health = format_number(health_values and health_values.total or max_health, 0),
      speed = format_number(speed_values and speed_values.total or nil, 2),
      range = format_number(range_values and range_values.total or nil, 1),
    }
  end

  local CORE_SORT_MODES = {
    { id = "level", caption = { "turret-xp.inventory-core-sort-level" }, tooltip = { "turret-xp.inventory-core-sort-level-tooltip" } },
    { id = "kills", caption = { "turret-xp.inventory-core-sort-kills" }, tooltip = { "turret-xp.inventory-core-sort-kills-tooltip" } },
    { id = "damage", caption = { "turret-xp.inventory-core-sort-damage" }, tooltip = { "turret-xp.inventory-core-sort-damage-tooltip" } },
    { id = "name", caption = { "turret-xp.inventory-core-sort-name" }, tooltip = { "turret-xp.inventory-core-sort-name-tooltip" } },
  }

  local function add_picker_sort_controls(parent, current_sort)
    local sort_flow = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(sort_flow, "top_margin", 4)
    set_style(sort_flow, "horizontal_spacing", 4)
    set_style(sort_flow, "vertical_align", "center")

    local label = sort_flow.add({
      type = "label",
      caption = { "turret-xp.inventory-core-sort" },
      style = "caption_label",
    })
    set_style(label, "font_color", COLOR.caption)
    set_style(label, "right_margin", 2)

    for _, mode in ipairs(CORE_SORT_MODES) do
      local active = current_sort == mode.id
      local button = sort_flow.add({
        type = "button",
        caption = mode.caption,
        tooltip = mode.tooltip,
        tags = {
          turret_xp_action = "set-core-sort",
          sort = mode.id,
        },
      })
      set_style(button, "minimal_width", 56)
      set_style(button, "height", 28)
      if active then
        set_style(button, "font", "default-bold")
        set_style(button, "font_color", COLOR.bonus)
      end
    end
  end

  local function add_inventory_core_stats(parent, stats, wide)
    if wide then
      local details = parent.add({
        type = "flow",
        direction = "vertical",
      })
      set_style(details, "width", 174)
      set_style(details, "minimal_width", 174)
      set_style(details, "maximal_width", 174)

      local values = {
        rich_metric({ "turret-xp.inventory-core-stat-hp" }, stats.health),
        rich_metric({ "turret-xp.inventory-core-stat-attack" }, stats.speed, "/s"),
        rich_metric({ "turret-xp.inventory-core-stat-range" }, stats.range),
      }
      for _, caption in ipairs(values) do
        local label = details.add({
          type = "label",
          caption = caption,
          style = "caption_label",
        })
        set_style(label, "single_line", true)
      end
      return
    end

    return nil
  end

  local function add_inventory_core_picker(core_panel, player, entity, options)
    options = options or {}
    local wide = options.wide == true
    local current_sort = get_core_picker_sort(player)
    local core_options = get_player_core_options(player, current_sort)
    local picker_width = wide and LAYOUT.empty_inventory_core_picker_width or LAYOUT.inventory_core_picker_width
    local picker_height = wide and LAYOUT.empty_inventory_core_picker_height or LAYOUT.inventory_core_picker_height
    local detail_width = wide and LAYOUT.empty_inventory_core_detail_width or LAYOUT.inventory_core_detail_width

    local frame = core_panel.add({
      type = "frame",
      name = GUI.inventory_cores,
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_style(frame, "top_margin", 6)
    set_style(frame, "horizontally_stretchable", true)

    local header = frame.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(header, "horizontally_stretchable", true)
    set_style(header, "vertical_align", "center")

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
      caption = { "turret-xp.inventory-core-count", #core_options },
      style = "caption_label",
    })
    set_style(count, "font_color", COLOR.muted)

    if wide then
      add_picker_sort_controls(frame, current_sort)
    end

    local scroll = frame.add({
      type = "scroll-pane",
      direction = "vertical",
      style = "flib_naked_scroll_pane",
    })
    scroll.vertical_scroll_policy = "auto-and-reserve-space"
    scroll.horizontal_scroll_policy = "never"
    set_style(scroll, "top_margin", 4)
    set_style(scroll, "height", picker_height)
    set_style(scroll, "width", picker_width)
    set_style(scroll, "minimal_width", picker_width)
    set_style(scroll, "maximal_width", picker_width)

    if #core_options == 0 then
      local label = scroll.add({
        type = "label",
        caption = { "turret-xp.inventory-core-empty" },
        style = "caption_label",
      })
      set_style(label, "margin", { 8, 8, 8, 8 })
      set_style(label, "font_color", COLOR.muted)
      set_style(label, "single_line", false)
      set_style(label, "maximal_width", picker_width - 36)
      return
    end

    local rows = scroll.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(rows, "vertical_spacing", 4)
    set_style(rows, "horizontally_stretchable", true)

    for _, option in ipairs(core_options) do
      local profile = option.profile or create_blank_profile()
      local stats = preview_stats(entity, profile)
      local row = rows.add({
        type = "table",
        column_count = wide and 4 or 3,
      })
      set_style(row, "horizontally_stretchable", true)
      set_style(row, "horizontal_spacing", 8)
      set_style(row, "vertical_spacing", 0)
      pcall(function()
        row.style.column_alignments[1] = "left"
        row.style.column_alignments[2] = "left"
        row.style.column_alignments[3] = "right"
        if wide then
          row.style.column_alignments[3] = "left"
          row.style.column_alignments[4] = "right"
        end
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

      local summary = details.add({
        type = "label",
        caption = {
          "turret-xp.inventory-core-summary",
          rich_value(math.floor(profile.kills or 0)),
          rich_value(format_number(profile.damage or 0, 0)),
        },
        style = "caption_label",
      })
      set_style(summary, "font_color", COLOR.muted)
      set_style(summary, "single_line", false)
      set_style(summary, "maximal_width", detail_width)

      if wide then
        add_inventory_core_stats(row, stats, true)
      else
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
      end

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
      local summary = details.add({
        type = "label",
        caption = { "turret-xp.platform-core-summary", profile.level or 0, math.floor(profile.kills or 0), math.floor(profile.damage or 0) },
        style = "caption_label",
      })
      set_style(summary, "font_color", COLOR.muted)

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

    local key = core_panel_key(player, state)
    if (core_panel.tags or {}).key == key then
      if state then
        update_name_render(entity, state)
      end
      return
    end

    core_panel.clear()
    core_panel.tags = {
      key = key,
    }

    local top = core_panel.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(top, "horizontally_stretchable", true)
    set_style(top, "vertical_align", "center")
    set_style(top, "horizontal_spacing", 6)

    local slot_definition = {
      type = "sprite-button",
      name = GUI.core_slot,
      tooltip = state and { "turret-xp.extract-core-tooltip" } or { "turret-xp.install-core-tooltip" },
      tags = {
        turret_xp_action = "core-slot",
      },
    }
    if state then
      slot_definition.sprite = "item/" .. CHIP_NAME
      slot_definition.quality = state.chip_quality or "normal"
      slot_definition.elem_tooltip = {
        type = "item-with-quality",
        name = CHIP_NAME,
        quality = state.chip_quality or "normal",
      }
    end

    local icon = top.add(slot_definition)
    set_element_style(icon, "slot_button")
    set_style(icon, "size", 40)

    local label = top.add({
      type = "label",
      name = GUI.core_status,
      caption = state and { "turret-xp.core-installed" } or { "turret-xp.core-empty" },
      style = "caption_label",
    })
    set_style(label, "font", "default-bold")
    set_style(label, "single_line", false)
    set_style(label, "maximal_width", state and 180 or LAYOUT.empty_panel_width - 136)

    if state then
      top.add({
        type = "empty-widget",
        style = "flib_horizontal_pusher",
      })
      widgets.add_tool_button(top, {
        sprite = "utility/export_slot",
        tooltip = { "turret-xp.extract-core-button-tooltip" },
        tags = {
          turret_xp_action = "extract-core",
        },
      })
      local bind_button = top.add({
        type = "button",
        caption = state.bound_turret and { "turret-xp.core-unbind" } or { "turret-xp.core-bind" },
        tooltip = state.bound_turret and { "turret-xp.unbind-turret-tooltip" } or { "turret-xp.bind-turret-tooltip" },
        tags = {
          turret_xp_action = state.bound_turret and "unbind-turret" or "bind-turret",
        },
      })
      set_style(bind_button, "minimal_width", 56)
    end

    if not state and dev_controls_enabled(player) then
      local actions = core_panel.add({
        type = "flow",
        name = GUI.core_actions,
        direction = "horizontal",
      })
      set_style(actions, "top_margin", 4)
      set_style(actions, "horizontally_stretchable", true)
      set_style(actions, "horizontal_align", "right")
      set_style(actions, "horizontal_spacing", 4)
      widgets.add_tool_button(actions, {
        sprite = "utility/add",
        style = "flib_tool_button_light_green",
        tooltip = { "turret-xp.dev-create-core-tooltip" },
        tags = {
          turret_xp_action = "dev-create-core",
        },
      })
    end

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
      add_inventory_core_picker(core_panel, player, entity, { wide = true })
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

      local color_table = core_panel.add({
        type = "table",
        column_count = 3,
      })
      set_style(color_table, "top_margin", 4)
      set_style(color_table, "horizontally_stretchable", true)
      set_style(color_table, "horizontal_spacing", 6)
      set_style(color_table, "vertical_spacing", 2)

      local channels = {
        { key = "r", label = "R", name = GUI.core_color_r, value_name = GUI.core_color_r_value, color = { 1, 0.36, 0.30 } },
        { key = "g", label = "G", name = GUI.core_color_g, value_name = GUI.core_color_g_value, color = { 0.45, 1, 0.45 } },
        { key = "b", label = "B", name = GUI.core_color_b, value_name = GUI.core_color_b_value, color = { 0.45, 0.78, 1 } },
      }
      for index, channel in ipairs(channels) do
        local channel_label = color_table.add({
          type = "label",
          caption = channel.label,
          style = "caption_label",
        })
        set_style(channel_label, "font", "default-bold")
        set_style(channel_label, "font_color", channel.color)

        local slider = color_table.add({
          type = "slider",
          name = channel.name,
          minimum_value = 0,
          maximum_value = 255,
          value = math.floor(math.max(0, math.min(1, label_color[index] or 0)) * 255 + 0.5),
          tags = {
            turret_xp_action = "set-label-color",
            channel = channel.key,
          },
        })
        set_style(slider, "horizontally_stretchable", true)

        local value = color_table.add({
          type = "label",
          name = channel.value_name,
          caption = tostring(math.floor(math.max(0, math.min(1, label_color[index] or 0)) * 255 + 0.5)),
          style = "caption_label",
        })
        set_style(value, "width", 32)
        set_style(value, "horizontal_align", "right")
      end

      local preset_flow = core_panel.add({
        type = "flow",
        direction = "horizontal",
      })
      set_style(preset_flow, "top_margin", 4)
      set_style(preset_flow, "horizontally_stretchable", true)
      local color_button = preset_flow.add({
        type = "button",
        name = GUI.core_color_preview,
        caption = preset and preset.name or { "turret-xp.label-custom-color" },
        tooltip = { "turret-xp.label-color-tooltip" },
        tags = {
          turret_xp_action = "cycle-label-color",
        },
      })
      set_style(color_button, "font_color", label_color)
      set_style(color_button, "minimal_width", 96)

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
  }
end

return core_panel_module
