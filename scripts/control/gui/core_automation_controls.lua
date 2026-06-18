local core_automation_controls = {}

local LAYOUT = {
  label_width = 70,
  value_width = 216,
}

function core_automation_controls.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local set_style = deps.set_style
  local profile_automation = deps.profile_automation

  local service = {}

  local function add_row_label(parent, caption)
    local label = parent.add({
      type = "label",
      caption = caption,
      style = "caption_label",
    })
    set_style(label, "font_color", COLOR.caption)
    set_style(label, "width", LAYOUT.label_width)
    set_style(label, "minimal_width", LAYOUT.label_width)
    set_style(label, "maximal_width", LAYOUT.label_width)
    return label
  end

  local function add_summary_row(parent, label_caption, value_caption, value_color)
    local row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "horizontal_spacing", 8)
    set_style(row, "vertical_align", "center")
    add_row_label(row, label_caption)

    local value = row.add({
      type = "label",
      caption = value_caption,
      style = "caption_label",
    })
    set_style(value, "font_color", value_color or COLOR.muted)
    set_style(value, "single_line", false)
    set_style(value, "maximal_width", LAYOUT.value_width)
    return value
  end

  function service.add_installed(parent, state)
    local build_mode = profile_automation.build_mode_active(state)
    local target = profile_automation.target_model(state)
    local has_target = profile_automation.target_has_content(state and state.automation_target)
    local has_unfinished_target = profile_automation.target_unfinished(state)
    if not build_mode then
      local row = parent.add({
        type = "flow",
        name = GUI.core_build_controls,
        direction = "horizontal",
      })
      set_style(row, "horizontally_stretchable", true)
      set_style(row, "horizontal_spacing", 8)
      set_style(row, "vertical_align", "center")
      local title = row.add({
        type = "label",
        caption = { "turret-xp.build-mode-title" },
        style = "caption_label",
      })
      set_style(title, "font_color", COLOR.caption)

      if has_unfinished_target then
        local auto = row.add({
          type = "checkbox",
          name = GUI.core_automation_enabled,
          caption = { "turret-xp.build-mode-auto-enabled" },
          tooltip = { "turret-xp.build-mode-auto-tooltip" },
          state = state and state.automation_enabled == true or false,
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
        caption = { "turret-xp.build-mode-enter" },
        tooltip = { "turret-xp.build-mode-enter-tooltip" },
        tags = {
          turret_xp_action = "enter-build-mode",
        },
      })
      set_style(toggle, "minimal_width", 72)
      return
    end

    local frame = parent
    set_style(frame, "vertical_spacing", 4)

    local row = frame.add({
      type = "flow",
      name = GUI.core_build_controls,
      direction = "horizontal",
    })
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "horizontal_spacing", 8)
    set_style(row, "vertical_align", "center")
    local title = row.add({
      type = "label",
      caption = { "turret-xp.build-mode-title" },
      style = "heading_2_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "font_color", COLOR.build_mode)

    row.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    local toggle = row.add({
      type = "button",
      caption = { "turret-xp.build-mode-exit" },
      tooltip = { "turret-xp.build-mode-exit-tooltip" },
      tags = {
        turret_xp_action = "exit-build-mode",
      },
    })
    set_style(toggle, "minimal_width", 72)

    if not target or not has_target then
      add_summary_row(frame, { "turret-xp.build-mode-target" }, { "turret-xp.build-mode-target-none" })
      return
    end

    add_summary_row(
      frame,
      { "turret-xp.build-mode-level" },
      target.open_ended and { "turret-xp.build-mode-level-open-ended", target.level or 0 }
        or { "turret-xp.build-mode-level-value", target.level or 0 },
      COLOR.build_mode_muted
    )
    add_summary_row(
      frame,
      { "turret-xp.build-mode-core" },
      { "turret-xp.build-mode-points-value", target.core_points or 0, target.core_total or 0 },
      COLOR.build_mode_muted
    )
    add_summary_row(
      frame,
      { "turret-xp.build-mode-augments" },
      { "turret-xp.build-mode-points-value", target.augment_points or 0, target.augment_total or 0 },
      COLOR.build_mode_muted
    )
    add_summary_row(frame, { "turret-xp.build-mode-specialization" }, target.choice and target.choice ~= "" and target.choice or "-")
    add_summary_row(frame, { "turret-xp.build-mode-elements" }, target.elements and target.elements ~= "" and target.elements or "-")
  end

  return service
end

return core_automation_controls
