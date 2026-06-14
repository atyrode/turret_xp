local core_identity_module = {}

function core_identity_module.new(deps)
  local GUI = deps.GUI
  local LAYOUT = deps.LAYOUT
  local CHIP_NAME = deps.CHIP_NAME
  local set_style = deps.set_style
  local set_element_style = deps.set_element_style
  local dev_controls_enabled = deps.dev_controls_enabled
  local widgets = deps.widgets

  local service = {}

  local function add_empty_dev_actions(parent, player)
    if not dev_controls_enabled(player) then
      return
    end

    local actions = parent.add({
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

  function service.add_header(parent, player, state)
    local top = parent.add({
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
    else
      add_empty_dev_actions(parent, player)
    end
  end

  return service
end

return core_identity_module
