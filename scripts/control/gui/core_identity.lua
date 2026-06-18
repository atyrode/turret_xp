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

  local function add_header_details(parent, state, options)
    options = options or {}
    local details = parent.add({
      type = "flow",
      direction = "vertical",
    })
    local has_core_slot = state or options.pending_core == true
    local width = has_core_slot and LAYOUT.core_identity_detail_width or LAYOUT.core_identity_empty_detail_width
    set_style(details, "horizontally_stretchable", true)
    set_style(details, "width", width)
    set_style(details, "minimal_width", width)
    set_style(details, "maximal_width", width)

    local title = details.add({
      type = "label",
      name = GUI.core_status,
      caption = state and core_display_name(state) or options.pending_core and { "turret-xp.core-requested" } or { "turret-xp.core-empty" },
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
      } or options.pending_core and { "turret-xp.core-requested-summary" } or { "turret-xp.core-empty-summary" },
      style = "caption_label",
    })
    set_style(subtitle, "font_color", COLOR.muted)
    set_style(subtitle, "single_line", false)
    set_style(subtitle, "maximal_width", width)

    return details
  end

  local function add_empty_dev_actions(parent, player)
    if not dev_controls_enabled(player) then
      return
    end

    parent.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    local actions = widgets.add_action_toolbar(parent, {
      name = GUI.core_actions,
      spacing = LAYOUT.core_identity_action_spacing,
    })
    widgets.add_tool_button(actions, {
      sprite = "utility/add",
      style = "flib_tool_button_light_green",
      tooltip = { "turret-xp.dev-create-core-tooltip" },
      tags = {
        turret_xp_action = "dev-create-core",
      },
    })
  end

  function service.add_header(parent, player, state, options)
    options = options or {}
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
      tooltip = state and { "turret-xp.extract-core-tooltip" } or options.pending_core and {
        "turret-xp.pending-core-slot-tooltip",
      } or { "turret-xp.install-core-tooltip" },
      tags = {
        turret_xp_action = "core-slot",
      },
    }
    if state or options.pending_core == true then
      slot_definition.sprite = "item/" .. CHIP_NAME
      slot_definition.quality = state and state.chip_quality or "normal"
      slot_definition.elem_tooltip = {
        type = "item-with-quality",
        name = CHIP_NAME,
        quality = state and state.chip_quality or "normal",
      }
      if options.pending_core == true and not state then
        slot_definition.toggled = true
      end
    end

    local icon = top.add(slot_definition)
    set_element_style(icon, options.pending_core == true and not state and "turret_xp_pending_core_slot_button" or "slot_button")
    set_style(icon, "size", LAYOUT.core_identity_slot_size)

    add_header_details(top, state, options)

    if state then
      top.add({
        type = "empty-widget",
        style = "flib_horizontal_pusher",
      })

      local actions = widgets.add_action_toolbar(top, {
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
    elseif not options.pending_core then
      add_empty_dev_actions(top, player)
    end
  end

  return service
end

return core_identity_module
