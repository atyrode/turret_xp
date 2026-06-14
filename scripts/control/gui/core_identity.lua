local core_identity_module = {}

function core_identity_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local LAYOUT = deps.LAYOUT
  local CHIP_NAME = deps.CHIP_NAME
  local set_style = deps.set_style
  local set_element_style = deps.set_element_style
  local dev_controls_enabled = deps.dev_controls_enabled
  local widgets = deps.widgets

  local service = {}

  local function core_display_name(state)
    if state and state.custom_name and state.custom_name ~= "" then
      return state.custom_name
    end

    return { "turret-xp.inventory-core-unnamed" }
  end

  local function add_header_details(parent, state)
    local details = parent.add({
      type = "flow",
      direction = "vertical",
    })
    local width = state and LAYOUT.core_identity_detail_width or LAYOUT.core_identity_empty_detail_width
    set_style(details, "horizontally_stretchable", true)
    set_style(details, "width", width)
    set_style(details, "minimal_width", width)
    set_style(details, "maximal_width", width)

    local title = details.add({
      type = "label",
      name = GUI.core_status,
      caption = state and core_display_name(state) or { "turret-xp.core-empty" },
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "single_line", false)
    set_style(title, "maximal_width", width)

    local subtitle = details.add({
      type = "label",
      caption = state and {
        "turret-xp.core-identity-summary",
        tostring(state.level or 0),
        state.bound_turret and { "turret-xp.core-bound-status" } or { "turret-xp.core-unbound-status" },
      } or { "turret-xp.core-empty-summary" },
      style = "caption_label",
    })
    set_style(subtitle, "font_color", COLOR.muted)
    set_style(subtitle, "single_line", false)
    set_style(subtitle, "maximal_width", width)

    return details
  end

  local function add_action_toolbar(parent)
    local actions = parent.add({
      type = "flow",
      name = GUI.core_actions,
      direction = "horizontal",
    })
    set_style(actions, "horizontal_spacing", LAYOUT.core_identity_action_spacing)
    set_style(actions, "vertical_align", "center")
    return actions
  end

  local function add_empty_dev_actions(parent, player)
    if not dev_controls_enabled(player) then
      return
    end

    parent.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    local actions = add_action_toolbar(parent)
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
    set_style(icon, "size", LAYOUT.core_identity_slot_size)

    add_header_details(top, state)

    if state then
      top.add({
        type = "empty-widget",
        style = "flib_horizontal_pusher",
      })

      local actions = add_action_toolbar(top)
      widgets.add_tool_button(actions, {
        sprite = "utility/export_slot",
        tooltip = { "turret-xp.extract-core-button-tooltip" },
        size = LAYOUT.core_identity_tool_button_size,
        tags = {
          turret_xp_action = "extract-core",
        },
      })
      local bind_button = actions.add({
        type = "button",
        caption = state.bound_turret and { "turret-xp.core-unbind" } or { "turret-xp.core-bind" },
        tooltip = state.bound_turret and { "turret-xp.unbind-turret-tooltip" } or { "turret-xp.bind-turret-tooltip" },
        tags = {
          turret_xp_action = state.bound_turret and "unbind-turret" or "bind-turret",
        },
      })
      set_style(bind_button, "width", LAYOUT.core_identity_action_button_width)
      set_style(bind_button, "minimal_width", LAYOUT.core_identity_action_button_width)
      set_style(bind_button, "maximal_width", LAYOUT.core_identity_action_button_width)
    else
      add_empty_dev_actions(top, player)
    end
  end

  return service
end

return core_identity_module
