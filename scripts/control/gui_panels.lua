local gui_support = require("scripts.control.gui_support")

return function(M)
  setmetatable(M, { __index = _G })
  local _ENV = M

  local gui_support_service = nil

  local function get_gui_support_service()
    if not gui_support_service then
      gui_support_service = gui_support.new({
        COLOR = COLOR,
        LAYOUT = LAYOUT,
        format_number = format_number,
        set_style = set_style,
      })
    end

    return gui_support_service
  end

  function add_stat_row(parent, label, element_name, options)
    options = options or {}

    local label_element = parent.add({
      type = "label",
      caption = with_info_marker(label, options.info_tooltip),
      tooltip = options.info_tooltip,
      style = "caption_label",
    })
    set_style(label_element, "font_color", COLOR.caption)
    set_style(label_element, "single_line", true)

    local value_flow_definition = {
      type = "flow",
      direction = "horizontal",
    }
    if options.flow_name then
      value_flow_definition.name = options.flow_name
    end
    local value_flow = parent.add(value_flow_definition)
    set_style(value_flow, "horizontal_align", "right")
    set_style(value_flow, "horizontally_stretchable", true)
    if options.flow_only then
      return label_element, value_flow
    end

    local value_element = value_flow.add({
      type = "label",
      name = element_name,
      caption = "-",
      style = options.value_style or "label",
    })
    set_style(value_element, "horizontal_align", "right")
    set_style(value_element, "single_line", false)
    set_style(value_element, "maximal_width", options.maximal_width or LAYOUT.stats_value_width)

    return label_element, value_element
  end

  function make_stats_table(parent, name)
    local stat_table = parent.add({
      type = "table",
      name = name,
      column_count = 2,
      draw_horizontal_lines = true,
    })
    set_style(stat_table, "horizontally_stretchable", true)
    set_style(stat_table, "width", LAYOUT.stats_content_width)
    set_style(stat_table, "minimal_width", LAYOUT.stats_content_width)
    set_style(stat_table, "maximal_width", LAYOUT.stats_content_width)
    set_style(stat_table, "horizontal_spacing", 12)
    pcall(function()
      stat_table.style.column_alignments[1] = "left"
      stat_table.style.column_alignments[2] = "right"
    end)
    return stat_table
  end

  function add_xp_panel(parent)
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

    local level = top.add({
      type = "label",
      name = GUI.level,
      caption = { "turret-xp.level", 0 },
      style = "heading_2_label",
    })
    set_style(level, "font", "default-bold")

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

    local percent = xp_panel.add({
      type = "label",
      name = GUI.xp_percent,
      caption = { "turret-xp.progress-percent", 0 },
      style = "caption_label",
    })
    set_style(percent, "font_color", COLOR.muted)
    set_style(percent, "top_margin", 2)
  end

  function add_core_panel(parent)
    local core_panel = parent.add({
      type = "frame",
      name = GUI.core,
      direction = "vertical",
      style = "deep_frame_in_shallow_frame",
    })
    set_style(core_panel, "horizontally_stretchable", true)
    set_style(core_panel, "padding", { 8, 8, 8, 8 })
    set_style(core_panel, "bottom_margin", 6)
    return core_panel
  end

  function core_panel_key(player, state)
    local entity = get_remembered_turret(player)
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

    return "empty:" .. (find_carried_chip_stack(player) and "ready" or "none") .. ":platform:" .. tostring(platform_core_count)
  end

  function add_platform_core_list(core_panel, entity, state)
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
      flow.add({
        type = "button",
        caption = { "turret-xp.platform-core-send" },
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

      row.add({
        type = "button",
        caption = { "turret-xp.platform-core-install" },
        tooltip = { "turret-xp.platform-core-install-tooltip" },
        tags = {
          turret_xp_action = "platform-install-core",
          slot = option.index,
        },
      })
    end
  end

  function add_dev_controls_panel(parent, player)
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

    local label = top.add({
      type = "label",
      caption = "Dev",
      style = "caption_label",
    })
    set_style(label, "font", "default-bold")
    set_style(label, "right_margin", 4)

    local buttons = panel.add({
      type = "table",
      column_count = 2,
    })
    set_style(buttons, "horizontally_stretchable", true)
    set_style(buttons, "horizontal_spacing", 4)
    set_style(buttons, "vertical_spacing", 4)

    buttons.add({
      type = "button",
      caption = "+1",
      tooltip = { "turret-xp.dev-level-1-tooltip" },
      tags = {
        turret_xp_action = "dev-level",
        levels = 1,
      },
    })
    buttons.add({
      type = "button",
      caption = "+5",
      tooltip = { "turret-xp.dev-level-5-tooltip" },
      tags = {
        turret_xp_action = "dev-level",
        levels = 5,
      },
    })
    buttons.add({
      type = "button",
      caption = "Materials",
      tooltip = { "turret-xp.dev-materials-tooltip" },
      tags = {
        turret_xp_action = "dev-complete-element-rank",
      },
    })
    buttons.add({
      type = "button",
      caption = "Reset",
      tooltip = { "turret-xp.dev-reset-core-tooltip" },
      tags = {
        turret_xp_action = "dev-reset-core",
      },
    })
    return panel
  end

  function update_core_panel(root, player, entity, state)
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
      caption = state and "Veteran Core installed" or "No Veteran Core installed",
      style = "caption_label",
    })
    set_style(label, "font", "default-bold")
    set_style(label, "single_line", false)
    set_style(label, "maximal_width", 180)

    if state then
      top.add({
        type = "empty-widget",
        style = "flib_horizontal_pusher",
      })
      local bind_button = top.add({
        type = "button",
        caption = state.bound_turret and "Unbind" or "Bind",
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
      actions.add({
        type = "button",
        caption = "Dev core",
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
      set_style(note, "font_color", COLOR.muted)
      set_style(note, "single_line", false)
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
      caption = "Name",
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
      caption = "Show",
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
        caption = preset and preset.name or "Custom",
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
        caption = "Level",
        state = state.show_label_level ~= false,
        tags = {
          turret_xp_action = "toggle-label-level",
        },
      })
    end

    update_name_render(entity, state)
    add_platform_core_list(core_panel, entity, state)
  end

  function render_ammo_flow(flow, ammo_name, ammo_count, ammo_quality)
    flow.clear()
    if not ammo_name then
      flow.add({
        type = "sprite",
        sprite = "flib_indicator_yellow",
        style = "flib_indicator",
        tooltip = { "turret-xp.no-ammo" },
      })
      return
    end

    local ok, button = pcall(function()
      return flow.add({
        type = "sprite-button",
        sprite = "item/" .. ammo_name,
        quality = ammo_quality or "normal",
        number = ammo_count,
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
      return
    end

    flow.add({
      type = "label",
      caption = string.format("[item=%s] x%d", ammo_name, ammo_count),
    })
  end

  function update_ammo_row(panel, ammo_name, ammo_count, ammo_quality)
    local flow = find_gui_element(panel, GUI.ammo)
    if not flow then
      return
    end

    local current_tags = flow.tags or {}
    if
      current_tags.ammo_name == (ammo_name or "")
      and current_tags.ammo_count == (ammo_count or 0)
      and current_tags.ammo_quality == (ammo_quality or "")
    then
      return
    end

    flow.tags = {
      ammo_name = ammo_name or "",
      ammo_count = ammo_count or 0,
      ammo_quality = ammo_quality or "",
    }

    render_ammo_flow(flow, ammo_name, ammo_count, ammo_quality)
  end

  function format_percent(value, decimals)
    return get_gui_support_service().format_percent(value, decimals)
  end

  function color_to_rich_string(color)
    return get_gui_support_service().color_to_rich_string(color)
  end

  function rich_number(text, color)
    return get_gui_support_service().rich_number(text, color)
  end

  function rich_stat_text(text, color)
    return get_gui_support_service().rich_stat_text(text, color)
  end

  function add_stats_panel(parent)
    local scroll = parent.add({
      type = "scroll-pane",
      name = GUI.stats_scroll,
      direction = "vertical",
      vertical_scroll_policy = "auto",
      horizontal_scroll_policy = "never",
    })
    set_style(scroll, "top_margin", 8)
    set_style(scroll, "horizontally_stretchable", true)
    set_style(scroll, "width", LAYOUT.stats_scroll_width)
    set_style(scroll, "minimal_width", LAYOUT.stats_scroll_width)
    set_style(scroll, "maximal_width", LAYOUT.stats_scroll_width)
    set_style(scroll, "height", LAYOUT.stats_height)
    set_style(scroll, "maximal_height", LAYOUT.stats_height)
    set_style(scroll, "padding", { 6, 6, 6, 6 })

    return make_stats_table(scroll, GUI.stats)
  end

  function add_stat_value(stats, label, value, tooltip)
    local _, value_element = add_stat_row(stats, label, nil, {
      info_tooltip = tooltip,
      maximal_width = LAYOUT.stats_value_width,
    })
    value_element.caption = value
    return value_element
  end

  function add_custom_stat(stats, label, value)
    if value == nil or value == "" then
      return
    end

    local _, value_element = add_stat_row(stats, label, nil, {
      maximal_width = LAYOUT.stats_value_width,
      value_style = "caption_label",
    })
    value_element.caption = value
  end

  function add_base_crit_stats(stats, state)
    local crit_chance_rank = get_base_rank(state, "crit_chance")
    local raw_chance = ((crit_chance_rank * 0.0025) + get_sub_specialization_flat_bonus(state, "crit_chance_flat")) * 100
    local luck_multiplier = get_luck_multiplier(state)
    add_stat_value(
      stats,
      "Crit chance",
      format_stat_formula(0, raw_chance, luck_multiplier, get_crit_chance_fraction(state) * 100, "% / shot", 2),
      nil
    )

    local crit_damage_values = get_crit_damage_formula_values(state)
    add_stat_value(
      stats,
      "Crit damage",
      format_stat_formula(
        crit_damage_values.base,
        crit_damage_values.additive,
        crit_damage_values.multiplier,
        crit_damage_values.total,
        "% on crit",
        1
      ),
      nil
    )
  end

  function format_bonus_value_with_multiplier(value, multiplier, suffix, decimals, numeric_suffix)
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

  function add_active_custom_stats(stats, state, entity)
    if not state then
      return
    end

    local specialization = get_specialization(state)
    if specialization then
      add_custom_stat(stats, "Specialization", specialization.name)
    end
    local sub_specialization = get_sub_specialization(state)
    if sub_specialization then
      add_custom_stat(stats, "Sub-specialization", sub_specialization.name)
    end

    local damage_rank = get_base_rank(state, "damage")
    if damage_rank > 0 then
      add_custom_stat(stats, "Core damage", rich_number("+" .. format_number(damage_rank * 0.5, 1)) .. " / shot")
    end

    local repair_rank = get_base_rank(state, "repair")
    if repair_rank > 0 then
      add_custom_stat(
        stats,
        "Regeneration",
        format_bonus_value_with_multiplier(
          get_repair_base_per_second(state, entity),
          get_specialization_multiplier(state, "repair_multiplier"),
          " HP/s",
          1
        )
      )
    end

    local resistance = get_damage_resistance_fraction(state)
    if resistance > 0 then
      add_custom_stat(stats, "Resistance", { "", rich_number("-" .. format_number(resistance * 100, 2) .. "%"), " damage taken" })
    end

    local max_health_rank = get_augment_rank(state, "max_health")
    if max_health_rank > 0 then
      add_custom_stat(stats, "Max HP augment", rich_number("+" .. format_number(max_health_rank * MAX_HEALTH_PER_RANK, 0)) .. " HP")
    end

    local ammo_regen_rank = get_base_rank(state, "ammo_regen")
    if ammo_regen_rank > 0 then
      local caption = format_bonus_value_with_multiplier(
        ammo_regen_rank,
        get_specialization_multiplier(state, "ammo_recovery_multiplier"),
        " ammo/min",
        0
      )
      if state.last_ammo and state.last_ammo.name then
        caption = { "", caption, " [item=", state.last_ammo.name, "]" }
      end
      add_custom_stat(stats, "Ammo recovery", caption)
    end

    local siphon_rank = get_base_rank(state, "siphon")
    if siphon_rank > 0 then
      add_custom_stat(
        stats,
        "Lifesteal",
        format_bonus_value_with_multiplier(
          (siphon_rank * 0.004) * 100,
          get_specialization_multiplier(state, "lifesteal_multiplier"),
          " of damage",
          1,
          "%"
        )
      )
    end

    local bounce_rank = get_augment_rank(state, "bounce")
    if bounce_rank > 0 then
      add_custom_stat(
        stats,
        "Bullet bounce",
        rich_number(format_percent(apply_luck_to_chance(state, bounce_rank * 0.05), 1)) .. ", " .. rich_number("35%") .. " shot damage"
      )
    end

    local double_shot_chance = get_double_shot_chance(state)
    if double_shot_chance > 0 then
      add_custom_stat(stats, "Double shot", rich_number(format_percent(double_shot_chance, 1)) .. " chance")
    end

    local luck_rank = get_augment_rank(state, "luck")
    if luck_rank > 0 then
      add_custom_stat(stats, "Luck", format_colored_multiplier(get_luck_multiplier(state)) .. " proc odds")
    end

    local training_rank = get_augment_rank(state, "veteran_training")
    if training_rank > 0 then
      add_custom_stat(stats, "XP gain", rich_number("+" .. format_number(training_rank * 5, 0) .. "%") .. " combat XP")
    end

    local range_rank = get_augment_rank(state, "range")
    if range_rank > 0 then
      local value = rich_number("+" .. tostring(range_rank)) .. " attack range"
      local multiplier = get_specialization_multiplier(state, "range_multiplier")
      if math.abs(multiplier - 1) >= 0.005 then
        value = value .. " " .. (format_colored_multiplier(multiplier) or "")
      end
      add_custom_stat(stats, "Range augment", value)
    end

    for _, element_id in ipairs(get_unique_active_element_ids(state)) do
      local rank = get_element_rank(state, element_id)
      local summary = get_element_effect_summary_for_rank(state, element_id, rank, true, false)
      if summary then
        add_custom_stat(stats, element_name(element_id), summary)
      end
    end

    local combo = get_combo_caption(state)
    if combo and combo ~= "No combo yet" then
      add_custom_stat(stats, "Element combo", combo)
    end
  end

  function update_stats_panel(panel, entity, state, ammo_name, ammo_count, ammo_quality, quality_name, max_health, health)
    local stats = find_gui_element(panel, GUI.stats)
    if not stats then
      return
    end

    stats.clear()

    local health_tooltip = make_quality_tooltip(function(quality)
      return format_number(get_max_health_for_quality(entity, quality.name), 0)
    end)
    local health_values = get_health_formula_values(entity, state, quality_name, max_health)
    local health_caption = health_values
        and {
          "",
          format_number(health, 0),
          " / ",
          format_stat_formula(health_values.base, health_values.additive, health_values.multiplier, health_values.total, "", 0),
        }
      or string.format("%s / %s", format_number(health, 0), format_number(max_health, 0))
    add_stat_value(stats, { "turret-xp.hp" }, with_quality_marker(health_caption, health_tooltip), health_tooltip)

    local speed_values = get_shooting_speed_formula_values(entity, state, ammo_name)
    add_stat_value(
      stats,
      { "turret-xp.shooting-speed" },
      speed_values and format_stat_formula(speed_values.base, speed_values.additive, speed_values.multiplier, speed_values.total, "/s", 2)
        or format_shots_per_second(entity, ammo_name),
      { "turret-xp.shooting-speed-tooltip" }
    )

    local range_tooltip = make_quality_tooltip(function(quality)
      return format_range_for_quality(entity, quality.name)
    end)
    local range_values = get_range_formula_values(entity, state, quality_name)
    add_stat_value(
      stats,
      { "turret-xp.range" },
      with_quality_marker(
        range_values and format_stat_formula(range_values.base, range_values.additive, range_values.multiplier, range_values.total, "", 1)
          or format_range(entity),
        range_tooltip
      ),
      range_tooltip
    )

    local _, ammo_flow = add_stat_row(stats, { "turret-xp.ammo" }, nil, {
      info_tooltip = { "turret-xp.ammo-tooltip" },
      flow_name = GUI.ammo,
      flow_only = true,
    })
    render_ammo_flow(ammo_flow, ammo_name, ammo_count, ammo_quality)

    if ammo_name then
      local damage_values = get_damage_formula_values(entity, state, ammo_name)
      local damage_caption = damage_values
          and {
            "turret-xp.damage-value",
            {
              "turret-xp.damage-value-with-type",
              format_stat_formula(damage_values.base, damage_values.additive, damage_values.multiplier, damage_values.total, "", 1),
              { "damage-type-name." .. damage_values.damage_type },
            },
          }
        or { "turret-xp.damage-value", format_damage_per_shot(entity, ammo_name) }
      add_stat_value(stats, { "turret-xp.damage" }, damage_caption, { "turret-xp.damage-tooltip" })
      add_stat_value(stats, { "turret-xp.dps" }, format_estimated_dps(entity, ammo_name, state), { "turret-xp.dps-tooltip" })
    else
      add_stat_value(stats, { "turret-xp.damage" }, { "turret-xp.damage-no-ammo" }, nil)
      add_stat_value(stats, { "turret-xp.dps" }, "-", nil)
    end

    add_stat_value(stats, { "turret-xp.kills" }, state and format_number(state.kills, 0) or "-")
    add_stat_value(stats, { "turret-xp.damage-dealt" }, state and format_number(state.damage, 0) or "-")
    if state then
      add_base_crit_stats(stats, state)
    end
    add_active_custom_stats(stats, state, entity)
  end

  function add_evolution_panel(parent)
    local outer = parent.add({
      type = "frame",
      direction = "vertical",
      style = "inside_shallow_frame",
    })
    set_style(outer, "width", LAYOUT.evolution_column_width)
    set_style(outer, "minimal_width", LAYOUT.evolution_column_width)
    set_style(outer, "maximal_width", LAYOUT.evolution_column_width)
    set_style(outer, "height", LAYOUT.evolution_outer_height)
    set_style(outer, "maximal_height", LAYOUT.evolution_outer_height)

    local header = outer.add({
      type = "frame",
      name = GUI.evolution_summary,
      direction = "horizontal",
      style = "subheader_frame",
    })
    set_style(header, "height", LAYOUT.evolution_header_height)
    set_style(header, "horizontally_stretchable", true)
    set_style(header, "vertical_align", "center")

    local panel = outer.add({
      type = "scroll-pane",
      name = GUI.evolution,
      vertical_scroll_policy = "auto",
      horizontal_scroll_policy = "never",
    })
    set_style(panel, "horizontally_stretchable", true)
    set_style(panel, "vertically_stretchable", true)
    set_style(panel, "width", LAYOUT.evolution_scroll_width)
    set_style(panel, "minimal_width", LAYOUT.evolution_scroll_width)
    set_style(panel, "maximal_width", LAYOUT.evolution_scroll_width)
    set_style(panel, "height", LAYOUT.evolution_scroll_height)
    set_style(panel, "maximal_height", LAYOUT.evolution_scroll_height)
    return panel
  end

  function set_evolution_content_width(element, inner)
    get_gui_support_service().set_evolution_content_width(element, inner)
  end

  function set_card_text_width(element)
    get_gui_support_service().set_card_text_width(element)
  end

  function set_evolution_card_child_width(element)
    get_gui_support_service().set_evolution_card_child_width(element)
  end

  element_name = function(element_id)
    local element = ELEMENT_BY_ID[element_id]
    return element and element.name or "None"
  end

  get_unique_active_element_ids = function(state)
    local evolution = ensure_evolution_state(state)
    local unique = {}
    local seen = {}
    for slot = 1, 2 do
      local element_id = evolution.elements[slot]
      if element_id and ELEMENT_BY_ID[element_id] and not seen[element_id] then
        seen[element_id] = true
        unique[#unique + 1] = element_id
      end
    end
    return unique
  end

  function has_level(state, level)
    return (state.level or 0) >= level
  end

  function add_summary_label(parent, title, value, value_color)
    local caption = {
      "",
      rich_color("1,1,1", title .. ":"),
      " ",
      rich_color(value_color or "0.58,0.82,0.38", value),
    }
    local label = parent.add({
      type = "label",
      caption = caption,
      style = "caption_label",
    })
    set_style(label, "font_color", COLOR.muted)
    set_style(label, "single_line", true)
    set_style(label, "left_margin", 8)
    return label
  end

  function update_evolution_summary(panel, state)
    local header = find_gui_element(panel, GUI.evolution_summary)
    if not header then
      return
    end

    header.clear()

    local label = header.add({
      type = "label",
      caption = "Evolution",
      style = "heading_2_label",
    })
    set_style(label, "font", "default-bold")

    header.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    if not state then
      add_summary_label(header, "Core", "None", "0.74,0.74,0.74")
      return
    end

    local evolution = ensure_evolution_state(state)
    local specialization = evolution.specialization and SPECIALIZATION_BY_ID[evolution.specialization] or nil
    local sub_specialization = get_sub_specialization(state)
    local specialization_caption = specialization and specialization.name or "-"
    if specialization and sub_specialization then
      specialization_caption = specialization.name .. "/" .. sub_specialization.name
    end
    add_summary_label(header, "Core", tostring(get_available_skill_points(state)), "0.58,0.82,0.38")
    add_summary_label(header, "Aug", tostring(get_available_augment_points(state)), "0.35,0.75,1")
    add_summary_label(header, "Spec", specialization_caption, specialization and "1,0.86,0.46" or "0.74,0.74,0.74")

    local reset = header.add({
      type = "button",
      caption = "Reset",
      tooltip = "Reset all Evolution choices and refund core and augment ranks. XP, level, combat history, name, and binding are kept.",
      tags = {
        turret_xp_action = "reset-evolution",
      },
    })
    set_style(reset, "left_margin", 8)
    set_style(reset, "minimal_width", 56)
  end

  function add_section(parent, title, unlocked, gate_level, right_caption, action_caption, action_tags, action_tooltip, action_enabled)
    local section = parent.add({
      type = "frame",
      direction = "vertical",
      style = "deep_frame_in_shallow_frame",
    })
    set_evolution_content_width(section)
    set_style(section, "top_margin", 6)
    set_style(section, "bottom_margin", 6)
    set_style(section, "left_margin", LAYOUT.evolution_section_margin)
    set_style(section, "right_margin", LAYOUT.evolution_section_margin)
    set_style(section, "padding", { 6, 6, 6, 6 })

    if not unlocked then
      set_style(section, "height", 70)
      set_style(section, "vertical_align", "center")
      local locked = section.add({
        type = "label",
        caption = "Unlocks at level " .. tostring(gate_level),
        style = "caption_label",
      })
      set_style(locked, "font", "default-bold")
      set_style(locked, "horizontally_stretchable", true)
      set_style(locked, "horizontal_align", "center")
      return section
    end

    if not title or title == "" then
      return section
    end

    local header = section.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_content_width(header, true)
    set_style(header, "horizontally_stretchable", true)
    set_style(header, "vertical_align", "center")
    set_style(header, "bottom_margin", 6)

    local title_label = header.add({
      type = "label",
      caption = title,
      style = "caption_label",
    })
    set_style(title_label, "font", "default-bold")

    header.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    if right_caption and right_caption ~= "" and not action_caption then
      local right = header.add({
        type = "label",
        caption = right_caption,
        style = "caption_label",
      })
      set_style(right, "font_color", COLOR.muted)
      set_style(right, "right_margin", action_caption and 6 or 0)
    end

    if action_caption and action_tags then
      local button = header.add({
        type = "button",
        caption = action_caption,
        tooltip = action_tooltip,
        enabled = action_enabled ~= false,
        tags = action_tags,
      })
      set_style(button, "minimal_width", 56)
    end

    if right_caption and right_caption ~= "" and action_caption then
      local right = section.add({
        type = "label",
        caption = right_caption,
        style = "caption_label",
      })
      set_style(right, "font_color", COLOR.muted)
      set_style(right, "single_line", false)
      set_style(right, "maximal_width", LAYOUT.evolution_inner_width)
      set_style(right, "top_margin", 2)
    end

    return section
  end

  function specialization_value_caption(specialization)
    if not specialization then
      return ""
    end

    local fire_rate_multiplier = 1 / (specialization.cooldown_multiplier or 1)
    local ordered = {
      sniper = {
        { specialization.range_multiplier, " range" },
        { specialization.damage_multiplier, " damage" },
        { specialization.crit_damage_multiplier, " crit damage" },
        { fire_rate_multiplier, " fire rate" },
        { specialization.health_multiplier, " HP" },
      },
      machine_gun = {
        { fire_rate_multiplier, " fire rate" },
        { specialization.ammo_recovery_multiplier, " ammo recovery" },
        { specialization.damage_multiplier, " damage" },
        { specialization.range_multiplier, " range" },
        { specialization.health_multiplier, " HP" },
      },
      bulwark = {
        { specialization.health_multiplier, " HP" },
        { specialization.repair_multiplier, " regeneration" },
        { specialization.damage_multiplier, " damage" },
        { fire_rate_multiplier, " fire rate" },
        { specialization.range_multiplier, " range" },
      },
      brawler = {
        { specialization.damage_multiplier, " damage" },
        { specialization.lifesteal_multiplier, " lifesteal" },
        { specialization.range_multiplier, " range" },
        { specialization.health_multiplier, " HP" },
        { fire_rate_multiplier, " fire rate" },
      },
    }

    local entries = ordered[specialization.id]
      or {
        { specialization.range_multiplier, " range" },
        { specialization.damage_multiplier, " damage" },
        { fire_rate_multiplier, " fire rate" },
        { specialization.health_multiplier, " HP" },
      }

    local caption = { "" }
    for index, entry in ipairs(entries) do
      local multiplier = entry[1] or 1
      local label = entry[2] or ""
      local formatted = format_colored_multiplier(multiplier) or ("x" .. format_number(multiplier, 2))
      if index > 1 then
        caption[#caption + 1] = ", "
      end
      caption[#caption + 1] = formatted
      caption[#caption + 1] = label
    end

    return caption
  end

  function sub_specialization_value_caption(sub_specialization)
    if not sub_specialization then
      return ""
    end

    local entries = {
      { value = sub_specialization.range_multiplier, label = " range", kind = "multiplier" },
      { value = sub_specialization.damage_multiplier, label = " damage", kind = "multiplier" },
      { value = sub_specialization.crit_chance_flat, label = " crit chance", kind = "percent" },
      { value = sub_specialization.crit_damage_multiplier, label = " crit damage", kind = "multiplier" },
      { value = sub_specialization.double_shot_chance_flat, label = " double shot", kind = "percent" },
      {
        value = sub_specialization.cooldown_multiplier and (1 / sub_specialization.cooldown_multiplier) or nil,
        label = " fire rate",
        kind = "multiplier",
      },
      { value = sub_specialization.health_multiplier, label = " HP", kind = "multiplier" },
      { value = sub_specialization.resistance_flat, label = " resistance", kind = "percent" },
      { value = sub_specialization.repair_multiplier, label = " regeneration", kind = "multiplier" },
      { value = sub_specialization.ammo_recovery_multiplier, label = " ammo recovery", kind = "multiplier" },
      { value = sub_specialization.lifesteal_multiplier, label = " lifesteal", kind = "multiplier" },
    }

    local caption = { "" }
    local added = 0
    for _, entry in ipairs(entries) do
      local value = entry.value
      local include
      local formatted = nil
      if entry.kind == "percent" then
        include = value and math.abs(value) >= 0.0001
        if include then
          local color = value < 0 and COLOR.penalty or COLOR.bonus
          formatted = rich_color(color_to_rich_string(color), (value < 0 and "-" or "+") .. format_number(math.abs(value) * 100, 1) .. "%")
        end
      else
        include = value and math.abs(value - 1) >= 0.005
        if include then
          formatted = format_colored_multiplier(value)
        end
      end

      if include then
        if added > 0 then
          caption[#caption + 1] = ", "
        end
        caption[#caption + 1] = formatted
        caption[#caption + 1] = entry.label
        added = added + 1
      end
    end

    return added > 0 and caption or sub_specialization.value or ""
  end

  function add_choice_delimiter(parent)
    local delimiter = parent.add({
      type = "line",
      direction = "horizontal",
    })
    set_style(delimiter, "horizontally_stretchable", true)
    set_style(delimiter, "top_margin", 4)
    set_style(delimiter, "bottom_margin", 4)
    return delimiter
  end

  function add_row(parent, sprite, name, detail, right_caption, tags, enabled, row_name)
    local row_definition = {
      type = "table",
      column_count = 3,
    }
    if row_name then
      row_definition.name = row_name
    end
    local row = parent.add(row_definition)
    set_evolution_content_width(row, true)
    set_style(row, "horizontal_spacing", 8)
    set_style(row, "vertical_spacing", 2)
    pcall(function()
      row.style.column_alignments[1] = "left"
      row.style.column_alignments[2] = "left"
      row.style.column_alignments[3] = "right"
    end)

    local icon = row.add({
      type = "sprite",
      sprite = sprite,
    })
    set_style(icon, "size", 28)

    local details = row.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(details, "horizontally_stretchable", true)

    local title = details.add({
      type = "label",
      caption = name,
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")

    if detail and detail ~= "" then
      local desc = details.add({
        type = "label",
        caption = detail,
        style = "caption_label",
      })
      set_style(desc, "font_color", COLOR.muted)
      set_style(desc, "single_line", false)
      set_style(desc, "maximal_width", LAYOUT.evolution_detail_width)
    end

    if tags then
      local button = row.add({
        type = "button",
        caption = right_caption,
        tags = tags,
        enabled = enabled,
      })
      set_style(button, "minimal_width", 72)
      return button
    end

    local value = row.add({
      type = "label",
      caption = right_caption or "",
      style = "caption_label",
    })
    set_style(value, "font_color", COLOR.muted)
    return value
  end

  function add_element_choice_card(parent, element, state, slot)
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
      caption = { "", "[color=0.58,0.82,0.38]Effect:[/color] ", get_element_effect_summary_for_rank(state, element.id, 1, true) or "" },
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
      caption = { "", "[color=0.74,0.74,0.74]Unlock:[/color] ", rich_number("Free") },
      style = "caption_label",
    })
    set_style(cost, "single_line", false)
    set_style(cost, "horizontally_stretchable", true)
    set_style(cost, "maximal_width", LAYOUT.evolution_card_inner_width - 80)

    local start = cost_row.add({
      type = "button",
      caption = "Pick",
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
        caption = { "", "[color=0.35,0.75,1]Combo:[/color] ", get_combo_caption_for_pair(evolution.elements[1], element.id) },
        style = "caption_label",
      })
      set_card_text_width(combo)
    end

    return row
  end

  function add_allocation_row(parent, sprite, name, rank_caption, value_caption, button_caption, tags, enabled, tooltip, row_name)
    local row_definition = {
      type = "table",
      column_count = 4,
    }
    if row_name then
      row_definition.name = row_name
    end
    local row = parent.add(row_definition)
    set_evolution_content_width(row, true)
    set_style(row, "horizontal_spacing", 8)
    set_style(row, "vertical_spacing", 2)
    pcall(function()
      row.style.column_alignments[1] = "left"
      row.style.column_alignments[2] = "left"
      row.style.column_alignments[3] = "right"
      row.style.column_alignments[4] = "right"
    end)

    local icon = row.add({
      type = "sprite",
      sprite = sprite,
    })
    set_style(icon, "size", 28)

    local details = row.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(details, "horizontally_stretchable", true)

    local title = details.add({
      type = "label",
      caption = name,
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")

    local rank = details.add({
      type = "label",
      caption = rank_caption or "",
      style = "caption_label",
    })
    set_style(rank, "font_color", COLOR.muted)

    local value = row.add({
      type = "label",
      caption = rich_stat_text(value_caption or ""),
      style = "caption_label",
    })
    set_style(value, "horizontal_align", "right")

    local button = row.add({
      type = "button",
      caption = button_caption or "+",
      tooltip = tooltip,
      tags = tags,
      enabled = enabled,
    })

    set_style(button, "font", "default-bold")
    set_style(button, "width", 40)
    set_style(button, "height", 32)
    set_style(button, "minimal_width", 40)

    return button
  end

  function add_base_allocation_row(parent, upgrade, rank, can_increase)
    local row = parent.add({
      type = "table",
      name = evolution_anchor_name("base", upgrade.id),
      column_count = 4,
    })
    set_evolution_content_width(row, true)
    set_style(row, "horizontal_spacing", 8)
    set_style(row, "vertical_spacing", 2)
    pcall(function()
      row.style.column_alignments[1] = "left"
      row.style.column_alignments[2] = "left"
      row.style.column_alignments[3] = "right"
      row.style.column_alignments[4] = "right"
    end)

    local icon = row.add({
      type = "sprite",
      sprite = upgrade.sprite,
    })
    set_style(icon, "size", 28)

    local name_label = row.add({
      type = "label",
      caption = upgrade.name,
      style = "caption_label",
    })
    set_style(name_label, "font", "default-bold")
    set_style(name_label, "horizontally_stretchable", true)

    local value = row.add({
      type = "label",
      caption = rich_stat_text(upgrade.value),
      style = "caption_label",
    })
    set_style(value, "horizontal_align", "right")

    local controls = row.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(controls, "horizontal_spacing", 4)
    set_style(controls, "vertical_align", "center")
    set_style(controls, "horizontal_align", "right")

    local decrease = controls.add({
      type = "button",
      caption = "-",
      tooltip = {
        "",
        "Remove one ",
        upgrade.name,
        " rank.\nShift-click removes up to 10.",
      },
      enabled = rank > 0,
      tags = {
        turret_xp_action = "deallocate-base",
        upgrade = upgrade.id,
      },
    })
    set_style(decrease, "font", "default-bold")
    set_style(decrease, "width", 32)
    set_style(decrease, "height", 32)
    set_style(decrease, "minimal_width", 32)

    local rank_label = controls.add({
      type = "label",
      caption = tostring(rank),
      style = "caption_label",
    })
    set_style(rank_label, "width", 28)
    set_style(rank_label, "horizontal_align", "center")

    local increase = controls.add({
      type = "button",
      caption = "+",
      tooltip = {
        "",
        upgrade.name,
        "\n",
        rich_stat_text(upgrade.value),
        "\n",
        tostring(rank),
        " -> ",
        tostring(rank + 1),
        "\nShift-click adds up to 10.",
      },
      enabled = can_increase,
      tags = {
        turret_xp_action = "allocate-base",
        upgrade = upgrade.id,
      },
    })
    set_style(increase, "font", "default-bold")
    set_style(increase, "width", 32)
    set_style(increase, "height", 32)
    set_style(increase, "minimal_width", 32)
  end

  function add_rank_stepper(parent, rank, decrease_tags, increase_tags, can_decrease, can_increase, decrease_tooltip, increase_tooltip)
    local controls = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(controls, "horizontal_spacing", 4)
    set_style(controls, "vertical_align", "center")
    set_style(controls, "horizontal_align", "right")

    local decrease = controls.add({
      type = "button",
      caption = "-",
      tooltip = decrease_tooltip,
      enabled = can_decrease,
      tags = decrease_tags,
    })
    set_style(decrease, "font", "default-bold")
    set_style(decrease, "width", 32)
    set_style(decrease, "height", 32)
    set_style(decrease, "minimal_width", 32)

    local rank_label = controls.add({
      type = "label",
      caption = tostring(rank or 0),
      style = "caption_label",
    })
    set_style(rank_label, "width", 28)
    set_style(rank_label, "horizontal_align", "center")

    local increase = controls.add({
      type = "button",
      caption = "+",
      tooltip = increase_tooltip,
      enabled = can_increase,
      tags = increase_tags,
    })
    set_style(increase, "font", "default-bold")
    set_style(increase, "width", 32)
    set_style(increase, "height", 32)
    set_style(increase, "minimal_width", 32)

    return controls
  end

  function add_augment_allocation_row(parent, augment, rank, available, at_max)
    local row = parent.add({
      type = "table",
      name = evolution_anchor_name("augment", augment.id),
      column_count = 4,
    })
    set_evolution_content_width(row, true)
    set_style(row, "horizontal_spacing", 8)
    set_style(row, "vertical_spacing", 2)
    pcall(function()
      row.style.column_alignments[1] = "left"
      row.style.column_alignments[2] = "left"
      row.style.column_alignments[3] = "right"
      row.style.column_alignments[4] = "right"
    end)

    local icon = row.add({
      type = "sprite",
      sprite = augment.sprite,
    })
    set_style(icon, "size", 28)

    local details = row.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(details, "horizontally_stretchable", true)

    local title = details.add({
      type = "label",
      caption = augment.name,
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")

    local rank_caption = augment.max_rank and ("Rank " .. tostring(rank) .. " / " .. tostring(augment.max_rank))
      or ("Rank " .. tostring(rank))
    local rank_label = details.add({
      type = "label",
      caption = rank_caption,
      style = "caption_label",
    })
    set_style(rank_label, "font_color", COLOR.muted)

    local value = row.add({
      type = "label",
      caption = at_max and "Max" or rich_stat_text(augment.value),
      style = "caption_label",
    })
    set_style(value, "horizontal_align", "right")

    add_rank_stepper(
      row,
      rank,
      {
        turret_xp_action = "deallocate-augment",
        augment = augment.id,
      },
      {
        turret_xp_action = "allocate-augment",
        augment = augment.id,
      },
      rank > 0,
      available >= 1 and not at_max,
      {
        "",
        "Remove one ",
        augment.name,
        " rank.\nShift-click removes up to 10.",
      },
      {
        "",
        augment.name,
        "\n",
        rich_stat_text(augment.description),
        "\nRank ",
        tostring(rank),
        " -> ",
        tostring(at_max and rank or (rank + 1)),
        "\nShift-click adds up to 10.",
      }
    )
  end

  function add_element_mastery_panel(parent, state, element_id)
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
      caption = element.name .. " rank " .. tostring(mastery_rank),
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
        "",
        "[item=",
        element_requirement.name,
        "] ",
        "Rank ",
        tostring(next_rank),
        ": ",
        rich_number(format_number(delivered, 0)),
        " / ",
        rich_number(format_number(required, 0)),
      } or "No material requirement.",
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

  get_combo_caption_for_pair = nil

  get_combo_caption = function(state)
    local evolution = ensure_evolution_state(state)
    local first = evolution.elements[1]
    local second = evolution.elements[2]

    return get_combo_caption_for_pair(first, second)
  end

  get_combo_caption_for_pair = function(first, second)
    if not first or not second then
      return "No combo yet"
    end

    if first == second then
      return "Pure " .. element_name(first) .. ": stronger " .. string.lower(element_name(first)) .. " effects"
    end

    local key = first < second and (first .. "+" .. second) or (second .. "+" .. first)
    local combos = {
      ["electric+fire"] = "Stormfire: arcs can add burn damage",
      ["electric+explosive"] = "Shockburst: explosive splashes arc to one target",
      ["explosive+fire"] = "Incendiary burst: explosive splashes add fire damage",
      ["fire+toxic"] = "Choking flame: burns and poison stacks reinforce damage over time",
      ["electric+toxic"] = "Neuroshock: electric arcs can carry toxic slow",
      ["explosive+toxic"] = "Contaminated blast: splash spreads toxic stacks",
    }

    return combos[key] or (element_name(first) .. " + " .. element_name(second))
  end

  function rich_color(color, text)
    return get_gui_support_service().rich_color(color, text)
  end

  function get_element_proc_chance_for_rank(state, rank)
    rank = math.max(0, math.floor(tonumber(rank) or 0))
    if rank <= 0 then
      return 0
    end
    return apply_luck_to_chance(state, math.min(0.60, 0.10 + (rank * 0.02)))
  end

  function get_element_multiplier_for_rank(rank)
    rank = math.max(0, math.floor(tonumber(rank) or 0))
    if rank <= 0 then
      return 0
    end
    return 1 + ((rank - 1) * 0.18)
  end

  function get_element_arc_count_for_rank(rank)
    rank = math.max(0, math.floor(tonumber(rank) or 0))
    if rank <= 0 then
      return 0
    end
    return math.min(5, rank)
  end

  function get_element_effect_summary_for_rank(state, element_id, rank, rich, color_terms)
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
    local function value(text, color)
      return rich and rich_color(color or value_color, text) or tostring(text)
    end

    if element_id == "fire" then
      return value(chance)
        .. " proc, "
        .. value(format_number(10 * multiplier, 1) .. "%", fire_color)
        .. " hit + "
        .. value(format_number(25 * multiplier, 1) .. "%", fire_color)
        .. " burn / 4s"
    end

    if element_id == "electric" then
      local arcs = get_element_arc_count_for_rank(rank)
      return value(chance)
        .. " proc, "
        .. value(arcs)
        .. " arc"
        .. (arcs == 1 and "" or "s")
        .. ", "
        .. value(format_number(25 * multiplier, 1) .. "%", electric_color)
        .. " shot electric damage"
    end

    if element_id == "explosive" then
      local splash_radius = 3 + math.min(3, rank * 0.15)
      return value(chance)
        .. " proc, "
        .. value(format_number(20 * multiplier, 1) .. "%", explosive_color)
        .. " splash damage, radius "
        .. value(format_number(splash_radius, 1))
    end

    if element_id == "toxic" then
      local toxic_color = "0.42,0.92,0.28"
      return value(chance) .. " proc, " .. value(format_number(8 * multiplier, 1) .. "%", toxic_color) .. " stacking poison / 8s, slow"
    end

    return value(chance) .. " proc"
  end

  function add_base_section(parent, state)
    local available = get_available_skill_points(state)
    local section = add_section(parent, "Core upgrades", true, nil, nil, nil, nil, nil)

    for index, upgrade in ipairs(BASE_UPGRADES) do
      if index > 1 then
        add_choice_delimiter(section)
      end
      local rank = get_base_rank(state, upgrade.id)
      local at_max = upgrade.max_rank and rank >= upgrade.max_rank
      add_base_allocation_row(section, upgrade, rank, available >= 1 and not at_max)
    end
  end

  function add_element_choices(section, state, slot)
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

  function add_first_element_section(parent, state)
    local unlocked = has_level(state, GATES.first_element)
    local evolution = ensure_evolution_state(state)
    local has_element = evolution.elements[1] ~= nil
    local section =
      add_section(parent, "First element", unlocked, GATES.first_element, nil, has_element and "Change" or nil, has_element and {
        turret_xp_action = "reset-element-slot",
        slot = 1,
      } or nil, "Clear the first element so another one can be picked. This also clears the second element and their element ranks.")
    if unlocked then
      add_element_choices(section, state, 1)
    end
  end

  function add_specialization_option(parent, specialization, selected)
    local row = parent.add({
      type = "frame",
      name = evolution_anchor_name("specialization", specialization.id),
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_evolution_content_width(row, true)
    set_style(row, "top_margin", 6)

    local top = row.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_card_child_width(top)
    set_style(top, "vertical_align", "center")
    set_style(top, "horizontal_spacing", 8)

    local icon = top.add({
      type = "sprite",
      sprite = specialization.sprite,
    })
    set_style(icon, "size", 28)

    local title = top.add({
      type = "label",
      caption = specialization.name,
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "single_line", true)
    set_style(title, "maximal_width", LAYOUT.evolution_card_inner_width - 44)

    local description = row.add({
      type = "label",
      caption = specialization.description,
      style = "caption_label",
    })
    set_style(description, "font_color", COLOR.muted)
    set_card_text_width(description)

    local technical_separator = row.add({
      type = "line",
      direction = "horizontal",
    })
    set_evolution_card_child_width(technical_separator)
    set_style(technical_separator, "top_margin", 2)
    set_style(technical_separator, "bottom_margin", 2)

    local value_row = row.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_card_child_width(value_row)
    set_style(value_row, "vertical_align", "center")
    set_style(value_row, "horizontal_spacing", 8)
    set_style(value_row, "horizontal_align", "right")

    local value = value_row.add({
      type = "label",
      caption = specialization_value_caption(specialization),
      style = "caption_label",
    })
    set_style(value, "single_line", false)
    set_style(value, "horizontally_stretchable", true)
    set_style(value, "maximal_width", LAYOUT.evolution_card_inner_width - 72)

    if selected then
      return
    end

    local button = value_row.add({
      type = "button",
      caption = "Pick",
      tags = {
        turret_xp_action = "choose-specialization",
        specialization = specialization.id,
      },
    })
    set_style(button, "width", 56)
    set_style(button, "minimal_width", 56)
    set_style(button, "maximal_width", 56)
  end

  function add_specialization_section(parent, state)
    local unlocked = has_level(state, GATES.specialization)
    local evolution = ensure_evolution_state(state)
    local section = add_section(
      parent,
      "Specialization",
      unlocked,
      GATES.specialization,
      nil,
      evolution.specialization and "Change" or nil,
      evolution.specialization and {
        turret_xp_action = "reset-specialization",
      } or nil,
      "Clear the current specialization so another one can be picked."
    )
    if not unlocked then
      return
    end

    if evolution.specialization then
      local specialization = SPECIALIZATION_BY_ID[evolution.specialization]
      add_specialization_option(section, specialization, true)
      return
    end

    for index, specialization in ipairs(SPECIALIZATIONS) do
      if index > 1 then
        add_choice_delimiter(section)
      end
      add_specialization_option(section, specialization, false)
    end
  end

  function add_sub_specialization_option(parent, sub_specialization, selected)
    local row = parent.add({
      type = "frame",
      name = evolution_anchor_name("sub-specialization", sub_specialization.id),
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_evolution_content_width(row, true)
    set_style(row, "top_margin", 6)

    local top = row.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_card_child_width(top)
    set_style(top, "vertical_align", "center")
    set_style(top, "horizontal_spacing", 8)

    local icon = top.add({
      type = "sprite",
      sprite = sub_specialization.sprite,
    })
    set_style(icon, "size", 28)

    local title = top.add({
      type = "label",
      caption = sub_specialization.name,
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "single_line", true)
    set_style(title, "maximal_width", LAYOUT.evolution_card_inner_width - 44)

    local description = row.add({
      type = "label",
      caption = sub_specialization.description,
      style = "caption_label",
    })
    set_style(description, "font_color", COLOR.muted)
    set_card_text_width(description)

    local technical_separator = row.add({
      type = "line",
      direction = "horizontal",
    })
    set_evolution_card_child_width(technical_separator)
    set_style(technical_separator, "top_margin", 2)
    set_style(technical_separator, "bottom_margin", 2)

    local value_row = row.add({
      type = "flow",
      direction = "horizontal",
    })
    set_evolution_card_child_width(value_row)
    set_style(value_row, "vertical_align", "center")
    set_style(value_row, "horizontal_spacing", 8)
    set_style(value_row, "horizontal_align", "right")

    local value = value_row.add({
      type = "label",
      caption = sub_specialization_value_caption(sub_specialization),
      style = "caption_label",
    })
    set_style(value, "single_line", false)
    set_style(value, "horizontally_stretchable", true)
    set_style(value, "maximal_width", LAYOUT.evolution_card_inner_width - 72)

    if selected then
      return
    end

    local button = value_row.add({
      type = "button",
      caption = "Pick",
      tags = {
        turret_xp_action = "choose-sub-specialization",
        sub_specialization = sub_specialization.id,
      },
    })
    set_style(button, "width", 56)
    set_style(button, "minimal_width", 56)
    set_style(button, "maximal_width", 56)
  end

  function add_sub_specialization_section(parent, state)
    local unlocked = has_level(state, GATES.sub_specialization)
    local evolution = ensure_evolution_state(state)
    local section = add_section(
      parent,
      "Sub-specialization",
      unlocked,
      GATES.sub_specialization,
      nil,
      evolution.sub_specialization and "Change" or nil,
      evolution.sub_specialization and {
        turret_xp_action = "reset-sub-specialization",
      } or nil,
      "Clear the current sub-specialization so another one can be picked."
    )
    if not unlocked then
      return
    end

    if not evolution.specialization then
      local label = section.add({
        type = "label",
        caption = "Pick a specialization before choosing a branch.",
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
        add_sub_specialization_option(section, sub_specialization, true)
      end
      return
    end

    local choices = SUB_SPECIALIZATIONS_BY_PARENT[evolution.specialization] or {}
    for index, sub_specialization in ipairs(choices) do
      if index > 1 then
        add_choice_delimiter(section)
      end
      add_sub_specialization_option(section, sub_specialization, false)
    end
  end

  function add_augments_section(parent, state)
    local unlocked = has_level(state, GATES.augments)
    local available = get_available_augment_points(state)
    local section = add_section(parent, "Augments", unlocked, GATES.augments, nil, nil, nil, nil)
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

  function add_second_element_section(parent, state)
    local unlocked = has_level(state, GATES.second_element)
    local evolution = ensure_evolution_state(state)
    local has_element = evolution.elements[2] ~= nil
    local section =
      add_section(parent, "Second element", unlocked, GATES.second_element, nil, has_element and "Change" or nil, has_element and {
        turret_xp_action = "reset-element-slot",
        slot = 2,
      } or nil, "Clear the second element so another one can be picked.")
    if not unlocked then
      return
    end

    if not evolution.elements[1] then
      local label = section.add({
        type = "label",
        caption = "Unlock the first element before starting the second.",
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
      caption = "Combo: " .. get_combo_caption(state),
      style = "caption_label",
    })
    set_style(combo, "font", "default-bold")
    set_style(combo, "top_margin", 4)
    set_style(combo, "single_line", false)
    set_style(combo, "maximal_width", LAYOUT.evolution_inner_width)
  end

  function update_evolution_panel(panel, state, anchor_name)
    update_evolution_summary(panel, state)

    local evolution_panel = find_gui_element(panel, GUI.evolution)
    if not evolution_panel then
      return
    end

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
    add_specialization_section(evolution_panel, state)
    add_first_element_section(evolution_panel, state)
    add_augments_section(evolution_panel, state)
    add_sub_specialization_section(evolution_panel, state)
    add_second_element_section(evolution_panel, state)
    scroll_evolution_to_anchor(panel, anchor_name)
  end

  function update_turret_gui(player, entity, evolution_anchor)
    local panel = get_gui_panel(player)
    if not panel then
      return false
    end

    local state = get_turret_state(entity)
    local progression = state and sync_turret_progression(state) or nil
    local required = progression and progression.required or 1
    local progress = progression and required > 0 and math.min(1, progression.xp / required) or 0
    local ammo_name, ammo_count, ammo_quality = get_loaded_ammo(entity)
    local quality_name = get_entity_quality_name(entity)
    local max_health = safe_read(entity, "max_health") or get_max_health_for_quality(entity, quality_name)
    local health = safe_read(entity, "health") or max_health

    update_core_panel(panel, player, entity, state)

    if state then
      set_gui_caption(panel, GUI.level, { "turret-xp.level", progression.level })
      set_gui_caption(panel, GUI.xp, { "turret-xp.xp-progress", format_number(progression.xp, 0), format_number(required, 0) })
    else
      set_gui_caption(panel, GUI.level, { "turret-xp.no-core-level" })
      set_gui_caption(panel, GUI.xp, { "turret-xp.no-core-xp" })
    end
    set_gui_progress(panel, GUI.xp_bar, progress)
    set_gui_caption(panel, GUI.xp_percent, state and { "turret-xp.progress-percent", format_number(progress * 100, 0) } or "")

    update_stats_panel(panel, entity, state, ammo_name, ammo_count, ammo_quality, quality_name, max_health, health)
    update_evolution_panel(panel, state, evolution_anchor)

    return true
  end
end
