local core_panel_module = {}

function core_panel_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local CHIP_NAME = deps.CHIP_NAME
  local set_style = deps.set_style
  local set_element_style = deps.set_element_style
  local find_gui_element = deps.find_gui_element
  local get_remembered_turret = deps.get_remembered_turret
  local get_platform_core_options = deps.get_platform_core_options
  local get_platform_hub_inventory = deps.get_platform_hub_inventory
  local find_carried_chip_stack = deps.find_carried_chip_stack
  local create_blank_profile = deps.create_blank_profile
  local dev_controls_enabled = deps.dev_controls_enabled
  local update_name_render = deps.update_name_render
  local find_matching_label_color_preset = deps.find_matching_label_color_preset

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

  local function add_core_panel(parent)
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

  local function core_panel_key(player, state)
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

    local label = top.add({
      type = "label",
      caption = { "turret-xp.dev-title" },
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
      caption = { "turret-xp.dev-level-1" },
      tooltip = { "turret-xp.dev-level-1-tooltip" },
      tags = {
        turret_xp_action = "dev-level",
        levels = 1,
      },
    })
    buttons.add({
      type = "button",
      caption = { "turret-xp.dev-level-5" },
      tooltip = { "turret-xp.dev-level-5-tooltip" },
      tags = {
        turret_xp_action = "dev-level",
        levels = 5,
      },
    })
    buttons.add({
      type = "button",
      caption = { "turret-xp.dev-materials" },
      tooltip = { "turret-xp.dev-materials-tooltip" },
      tags = {
        turret_xp_action = "dev-complete-element-rank",
      },
    })
    buttons.add({
      type = "button",
      caption = { "turret-xp.dev-reset" },
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
    set_style(label, "maximal_width", 180)

    if state then
      top.add({
        type = "empty-widget",
        style = "flib_horizontal_pusher",
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
      actions.add({
        type = "button",
        caption = { "turret-xp.dev-create-core" },
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
    add_platform_core_list = add_platform_core_list,
    add_dev_controls_panel = add_dev_controls_panel,
    update_core_panel = update_core_panel,
  }
end

return core_panel_module
