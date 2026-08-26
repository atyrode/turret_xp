local core_automation_controls = {}

local LAYOUT = {
  label_width = 82,
  dropdown_width = 150,
}

function core_automation_controls.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local components = deps.components
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

  function service.add_installed(parent, state)
    local frame = components.add_section_frame(parent, {
      top_margin = 6,
      vertical_spacing = 4,
    })

    local row = frame.add({
      type = "flow",
      direction = "horizontal",
    })
    set_style(row, "horizontally_stretchable", true)
    set_style(row, "horizontal_spacing", 8)
    set_style(row, "vertical_align", "center")
    add_row_label(row, { "turret-xp.automation-title" })

    local items = {}
    local ids = {}
    for _, preset in ipairs(profile_automation.presets()) do
      items[#items + 1] = { preset.locale }
      ids[#ids + 1] = preset.id
    end

    local dropdown = row.add({
      type = "drop-down",
      name = GUI.core_automation_preset,
      items = items,
      selected_index = profile_automation.preset_index(state.automation_preset),
      tooltip = { "turret-xp.automation-preset-tooltip" },
      tags = {
        turret_xp_action = "set-automation-preset",
        presets = ids,
      },
    })
    set_style(dropdown, "width", LAYOUT.dropdown_width)

    row.add({
      type = "checkbox",
      name = GUI.core_automation_enabled,
      caption = { "turret-xp.automation-auto" },
      state = state.automation_enabled == true,
      tooltip = { "turret-xp.automation-auto-tooltip" },
      tags = {
        turret_xp_action = "toggle-automation",
      },
    })

    local apply = row.add({
      type = "button",
      caption = { "turret-xp.automation-apply" },
      tooltip = { "turret-xp.automation-apply-tooltip" },
      tags = {
        turret_xp_action = "apply-automation",
      },
    })
    set_style(apply, "minimal_width", 64)
  end

  return service
end

return core_automation_controls
