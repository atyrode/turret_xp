local core_label_controls_module = {}

local LABEL_LAYOUT = {
  form_label_width = 70,
  textfield_min_width = 180,
  swatch_size = 22,
  color_button_min_width = 112,
}

function core_label_controls_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local set_style = deps.set_style
  local find_matching_label_color_preset = deps.find_matching_label_color_preset

  local service = {}

  local function add_row_label(parent, caption)
    local label = parent.add({
      type = "label",
      caption = caption,
      style = "caption_label",
    })
    set_style(label, "font_color", COLOR.caption)
    set_style(label, "width", LABEL_LAYOUT.form_label_width)
    set_style(label, "minimal_width", LABEL_LAYOUT.form_label_width)
    set_style(label, "maximal_width", LABEL_LAYOUT.form_label_width)
    return label
  end

  local function add_color_controls(frame, state)
    local preset = find_matching_label_color_preset(state)
    local label_color = state.label_color or { 1, 0.86, 0.46 }

    local preset_flow = frame.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(preset_flow, "horizontally_stretchable", true)
    set_style(preset_flow, "horizontal_spacing", 6)
    set_style(preset_flow, "vertical_align", "center")
    add_row_label(preset_flow, { "turret-xp.label-color-title" })

    local swatch = preset_flow.add({
      type = "progressbar",
      name = GUI.core_color_swatch,
      value = 1,
      tooltip = { "turret-xp.label-color-tooltip" },
    })
    set_style(swatch, "width", LABEL_LAYOUT.swatch_size)
    set_style(swatch, "height", LABEL_LAYOUT.swatch_size)
    set_style(swatch, "minimal_width", LABEL_LAYOUT.swatch_size)
    set_style(swatch, "maximal_width", LABEL_LAYOUT.swatch_size)
    set_style(swatch, "bar_width", LABEL_LAYOUT.swatch_size)
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
    set_style(color_button, "minimal_width", LABEL_LAYOUT.color_button_min_width)

    preset_flow.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })
    preset_flow.add({
      type = "checkbox",
      name = GUI.core_name_level_visible,
      caption = { "turret-xp.label-level" },
      state = state.show_label_level ~= false,
      tags = {
        turret_xp_action = "toggle-label-level",
      },
    })
  end

  function service.add(parent, state)
    local frame = parent.add({
      type = "frame",
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_style(frame, "top_margin", 6)
    set_style(frame, "horizontally_stretchable", true)
    set_style(frame, "vertical_spacing", 4)

    local name_flow = frame.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(name_flow, "vertical_align", "center")
    set_style(name_flow, "horizontally_stretchable", true)
    set_style(name_flow, "horizontal_spacing", 8)
    add_row_label(name_flow, { "turret-xp.core-name" })

    local textfield = name_flow.add({
      type = "textfield",
      name = GUI.core_name,
      text = state.custom_name or "",
      clear_and_focus_on_right_click = true,
      lose_focus_on_confirm = true,
    })
    set_style(textfield, "minimal_width", LABEL_LAYOUT.textfield_min_width)
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
      add_color_controls(frame, state)
    end
  end

  return service
end

return core_label_controls_module
