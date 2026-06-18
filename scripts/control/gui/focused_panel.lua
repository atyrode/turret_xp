local focused_panel_module = {}

function focused_panel_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local LAYOUT = deps.LAYOUT
  local CHIP_NAME = deps.CHIP_NAME
  local set_style = deps.set_style
  local set_element_style = deps.set_element_style
  local find_gui_element = deps.find_gui_element
  local get_focused_gui_view = deps.get_focused_gui_view
  local get_specialization = deps.get_specialization
  local get_sub_specialization = deps.get_sub_specialization
  local get_available_skill_points = deps.get_available_skill_points
  local get_available_augment_points = deps.get_available_augment_points
  local rich_specialization_caption = deps.rich_specialization_caption
  local format_number = deps.format_number
  local profile_automation = deps.profile_automation
  local get_turret_host = deps.get_turret_host
  local get_platform_hub_inventory = deps.get_platform_hub_inventory
  local core_requester = deps.core_requester
  local widgets = deps.widgets

  local views = {
    {
      id = "overview",
      name = GUI.focused_overview,
      caption = { "turret-xp.view-overview" },
      placeholder = { "turret-xp.view-overview-placeholder" },
    },
    {
      id = "progression",
      name = GUI.focused_progression,
      caption = { "turret-xp.view-progression" },
      placeholder = { "turret-xp.view-progression-placeholder" },
    },
    {
      id = "stats",
      name = GUI.focused_stats,
      caption = { "turret-xp.view-stats" },
      placeholder = { "turret-xp.view-stats-placeholder" },
    },
    {
      id = "automation",
      name = GUI.focused_automation,
      caption = { "turret-xp.view-automation" },
      placeholder = { "turret-xp.view-automation-placeholder" },
    },
  }

  local service = {}

  local function set_fixed_size(element, width, height)
    height = height or width
    set_style(element, "width", width)
    set_style(element, "height", height)
    set_style(element, "minimal_width", width)
    set_style(element, "minimal_height", height)
    set_style(element, "maximal_width", width)
    set_style(element, "maximal_height", height)
  end

  local function set_fixed_width(element, width)
    set_style(element, "width", width)
    set_style(element, "minimal_width", width)
    set_style(element, "maximal_width", width)
  end

  local function core_display_name(state)
    if state and state.custom_name and state.custom_name ~= "" then
      return state.custom_name
    end
    return { "turret-xp.inventory-core-unnamed" }
  end

  local function role_caption(state)
    local specialization = get_specialization(state)
    if not specialization then
      return rich_specialization_caption("base", { "turret-xp.inventory-core-no-specialization" })
    end

    local sub_specialization = get_sub_specialization(state)
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

  local function build_status_caption(state)
    if not state then
      return { "turret-xp.status-build-live" }
    end
    if profile_automation.build_mode_active(state) then
      return { "turret-xp.status-build-active" }
    end
    if state.automation_enabled == true then
      return { "turret-xp.status-build-follow" }
    end
    return { "turret-xp.status-build-live" }
  end

  local function status_key(state)
    return table.concat({
      tostring(state and state.bound_turret == true),
      tostring(state and profile_automation.build_mode_active(state) == true),
      tostring(state and state.automation_enabled == true),
    }, ":")
  end

  local function add_status_text(parent)
    local details = parent.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(details, "width", 220)
    set_style(details, "minimal_width", 220)
    set_style(details, "maximal_width", 220)
    set_style(details, "vertical_spacing", 2)

    local title = details.add({
      type = "label",
      name = GUI.focused_status_title,
      caption = "",
      style = "heading_2_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "single_line", false)

    local subtitle = details.add({
      type = "label",
      name = GUI.focused_status_subtitle,
      caption = "",
      style = "caption_label",
    })
    set_style(subtitle, "font_color", COLOR.muted)
    set_style(subtitle, "single_line", false)
    return details
  end

  local function add_status_metric(parent, name, caption)
    local label = parent.add({
      type = "label",
      name = name,
      caption = caption or "",
      style = "caption_label",
    })
    set_style(label, "single_line", false)
    set_style(label, "font_color", COLOR.muted)
    return label
  end

  local function add_status_actions(parent, state)
    local actions = widgets.add_action_toolbar(parent, {
      name = GUI.focused_status_actions,
      spacing = 4,
    })

    widgets.add_tool_button(actions, {
      sprite = "utility/export_slot",
      tooltip = { "turret-xp.extract-core-button-tooltip" },
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
    set_fixed_width(bind_button, LAYOUT.focused_status_action_width)

    local build_action = profile_automation.build_mode_active(state) and "exit-build-mode" or "enter-build-mode"
    local build_button = actions.add({
      type = "button",
      caption = profile_automation.build_mode_active(state) and { "turret-xp.build-mode-exit" } or { "turret-xp.build-mode-enter" },
      tooltip = profile_automation.build_mode_active(state) and { "turret-xp.build-mode-exit-tooltip" }
        or { "turret-xp.build-mode-enter-tooltip" },
      tags = {
        turret_xp_action = build_action,
      },
    })
    set_fixed_width(build_button, LAYOUT.focused_status_action_width)
  end

  local function add_status_strip(parent, state)
    local status = parent.add({
      type = "frame",
      name = GUI.focused_status,
      direction = "horizontal",
      style = "turret_xp_focused_status_frame",
    })
    status.tags = {
      turret_xp_focused_status = true,
      key = status_key(state),
    }
    set_style(status, "horizontally_stretchable", true)
    set_style(status, "vertical_align", "center")
    set_style(status, "horizontal_spacing", 8)

    local slot = status.add({
      type = "sprite-button",
      name = GUI.core_slot,
      sprite = "item/" .. CHIP_NAME,
      quality = state and state.chip_quality or "normal",
      tooltip = { "turret-xp.extract-core-tooltip" },
      elem_tooltip = {
        type = "item-with-quality",
        name = CHIP_NAME,
        quality = state and state.chip_quality or "normal",
      },
      tags = {
        turret_xp_action = "core-slot",
      },
    })
    set_element_style(slot, "slot_button")
    set_fixed_size(slot, LAYOUT.focused_status_icon_size)

    add_status_text(status)

    local metrics = status.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(metrics, "width", 250)
    set_style(metrics, "minimal_width", 250)
    set_style(metrics, "maximal_width", 250)
    set_style(metrics, "vertical_spacing", 2)
    add_status_metric(metrics, GUI.focused_status_xp)
    local bar = metrics.add({
      type = "progressbar",
      name = GUI.xp_bar,
      style = "turret_xp_xp_progressbar",
      value = 0,
    })
    set_style(bar, "horizontally_stretchable", true)
    set_style(bar, "height", 12)
    add_status_metric(metrics, GUI.focused_status_points)
    add_status_metric(metrics, GUI.focused_status_role)
    add_status_metric(metrics, GUI.focused_status_build)

    status.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })
    add_status_actions(status, state)
    return status
  end

  local function add_view_nav(parent, selected_view)
    local nav = parent.add({
      type = "flow",
      name = GUI.focused_nav,
      direction = "horizontal",
    })
    nav.tags = {
      turret_xp_focused_nav = true,
    }
    set_style(nav, "horizontal_spacing", 4)
    set_style(nav, "vertical_align", "center")

    for _, view in ipairs(views) do
      local selected = view.id == selected_view
      local button = nav.add({
        type = "button",
        caption = view.caption,
        style = selected and "turret_xp_view_tab_button_selected" or "turret_xp_view_tab_button",
        tags = {
          turret_xp_action = "set-focused-view",
          view = view.id,
        },
      })
      set_fixed_width(button, LAYOUT.focused_nav_button_width)
    end
    return nav
  end

  local function find_view(view_id)
    for _, view in ipairs(views) do
      if view.id == view_id then
        return view
      end
    end
    return views[1]
  end

  local function add_content_shell(parent, view_id)
    local view = find_view(view_id)
    local content = parent.add({
      type = "frame",
      name = GUI.focused_content,
      direction = "vertical",
      style = "turret_xp_focused_content_frame",
    })
    content.tags = {
      turret_xp_active_content = true,
      turret_xp_active_view = view.id,
    }
    set_style(content, "horizontally_stretchable", true)
    set_style(content, "height", LAYOUT.focused_content_height)
    set_style(content, "maximal_height", LAYOUT.focused_content_height)
    set_style(content, "vertical_spacing", 8)
    return content, view
  end

  local function add_overview_card(parent, title_caption, body_caption)
    local card = parent.add({
      type = "frame",
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_style(card, "width", 350)
    set_style(card, "minimal_width", 350)
    set_style(card, "maximal_width", 350)
    set_style(card, "vertical_spacing", 4)

    local title = card.add({
      type = "label",
      caption = title_caption,
      style = "caption_label",
    })
    set_style(title, "font", "default-bold")
    set_style(title, "font_color", COLOR.section_header)

    local body = card.add({
      type = "label",
      caption = body_caption,
      style = "caption_label",
    })
    set_style(body, "font_color", COLOR.muted)
    set_style(body, "single_line", false)
    set_style(body, "maximal_width", 330)
    return card
  end

  local function on_off_caption(value)
    return value and { "turret-xp.overview-label-on" } or { "turret-xp.overview-label-off" }
  end

  local function add_overview_content(content, state)
    local title = content.add({
      type = "label",
      caption = { "turret-xp.view-overview" },
      style = "heading_2_label",
    })
    set_style(title, "font", "default-bold")

    local rows = content.add({
      type = "table",
      column_count = 2,
    })
    set_style(rows, "horizontal_spacing", 8)
    set_style(rows, "vertical_spacing", 8)

    add_overview_card(rows, { "turret-xp.overview-progress" }, {
      "",
      { "turret-xp.level", state.level or 0 },
      "\n",
      { "turret-xp.status-unspent", get_available_skill_points(state) or 0, get_available_augment_points(state) or 0 },
      "\n",
      profile_automation.build_mode_active(state) and { "turret-xp.overview-next-build" } or { "turret-xp.overview-next-live" },
    })
    add_overview_card(rows, { "turret-xp.overview-role" }, {
      "",
      role_caption(state),
      "\n",
      build_status_caption(state),
    })
    add_overview_card(rows, { "turret-xp.overview-build" }, build_status_caption(state))
    add_overview_card(rows, { "turret-xp.overview-labels" }, {
      "turret-xp.overview-label-summary",
      on_off_caption(state.show_name_label == true),
      on_off_caption(state.show_label_level == true),
      on_off_caption(state.show_unspent_label == true),
    })
  end

  local function add_placeholder_content(parent, view_id, state)
    local content, view = add_content_shell(parent, view_id)
    if view.id == "overview" then
      add_overview_content(content, state)
      return content
    end

    local inner = content.add({
      type = "flow",
      name = view.name,
      direction = "vertical",
    })
    inner.tags = {
      turret_xp_content_view = view.id,
    }
    set_style(inner, "horizontally_stretchable", true)
    set_style(inner, "vertical_spacing", 6)

    local title = inner.add({
      type = "label",
      caption = view.caption,
      style = "heading_2_label",
    })
    set_style(title, "font", "default-bold")

    local note = inner.add({
      type = "label",
      caption = view.placeholder,
      style = "caption_label",
    })
    set_style(note, "font_color", COLOR.muted)
    set_style(note, "single_line", false)
    set_style(note, "maximal_width", LAYOUT.focused_panel_width - 48)

    return content
  end

  local function set_caption(root, name, caption)
    local element = find_gui_element(root, name)
    if element then
      element.caption = caption
    end
  end

  local function set_progress(root, name, value)
    local element = find_gui_element(root, name)
    if element then
      element.value = value
    end
  end

  function service.add_installed_panel(parent, player, state)
    local selected_view = get_focused_gui_view(player)
    add_status_strip(parent, state)
    add_view_nav(parent, selected_view)
    add_placeholder_content(parent, selected_view, state)
  end

  function service.add_empty_panel(parent, player, entity, add_inventory_core_picker, add_platform_core_list)
    local host = get_turret_host and get_turret_host(entity, false) or nil
    local request_status = core_requester and core_requester.status(entity) or {}
    local pending_core = (host and host.request_core == true) or request_status.delivered == true
    local has_platform_source = get_platform_hub_inventory and get_platform_hub_inventory(entity) ~= nil
    local panel = parent.add({
      type = "flow",
      name = GUI.empty_picker,
      direction = "vertical",
    })
    panel.tags = {
      turret_xp_empty_picker = true,
    }
    set_style(panel, "horizontally_stretchable", true)
    set_style(panel, "vertical_spacing", LAYOUT.focused_view_spacing)

    local status = panel.add({
      type = "frame",
      name = GUI.empty_status,
      direction = "horizontal",
      style = "turret_xp_focused_status_frame",
    })
    set_style(status, "horizontally_stretchable", true)
    set_style(status, "vertical_align", "center")
    set_style(status, "horizontal_spacing", 8)

    local slot = status.add({
      type = "sprite-button",
      name = GUI.core_slot,
      sprite = "item/" .. CHIP_NAME,
      tooltip = pending_core and { "turret-xp.pending-core-slot-tooltip" } or { "turret-xp.install-core-tooltip" },
      elem_tooltip = {
        type = "item-with-quality",
        name = CHIP_NAME,
        quality = "normal",
      },
      toggled = pending_core,
      tags = {
        turret_xp_action = "core-slot",
      },
    })
    set_element_style(slot, pending_core and "turret_xp_pending_core_slot_button" or "slot_button")
    set_fixed_size(slot, LAYOUT.focused_status_icon_size)

    local text = status.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(text, "vertical_spacing", 2)
    local title = text.add({
      type = "label",
      caption = pending_core and { "turret-xp.core-requested" } or { "turret-xp.empty-picker-title" },
      style = "heading_2_label",
    })
    set_style(title, "font", "default-bold")
    local summary = text.add({
      type = "label",
      caption = pending_core and { "turret-xp.core-requested-summary" } or { "turret-xp.empty-picker-summary" },
      style = "caption_label",
    })
    set_style(summary, "font_color", COLOR.muted)

    if has_platform_source then
      local nav = panel.add({
        type = "flow",
        name = GUI.empty_source_nav,
        direction = "horizontal",
      })
      set_style(nav, "horizontal_spacing", 4)
      for _, source in ipairs({
        { "inventory", { "turret-xp.empty-source-inventory" } },
        { "platform", { "turret-xp.empty-source-platform" } },
      }) do
        local button = nav.add({
          type = "button",
          caption = source[2],
          style = source[1] == "inventory" and "turret_xp_view_tab_button_selected" or "turret_xp_view_tab_button",
        })
        set_fixed_width(button, LAYOUT.focused_nav_button_width)
      end
    end

    local content = panel.add({
      type = "frame",
      name = GUI.focused_content,
      direction = "vertical",
      style = "turret_xp_focused_content_frame",
    })
    content.tags = {
      turret_xp_active_content = true,
      turret_xp_active_view = "empty-picker",
    }
    set_style(content, "horizontally_stretchable", true)

    if add_inventory_core_picker then
      add_inventory_core_picker(content, player, entity, {
        wide = true,
      })
    end
    if add_platform_core_list then
      add_platform_core_list(content, entity, nil)
    end
    return panel
  end

  function service.update_status(root, context)
    local state = context and context.live_state or nil
    if not state then
      return false
    end

    local content = find_gui_element(root, GUI.focused_content)
    if not content or not content.tags or content.tags.turret_xp_active_view ~= get_focused_gui_view(context.player) then
      return false
    end

    local status = find_gui_element(root, GUI.focused_status)
    if not status or not status.tags or status.tags.key ~= status_key(state) then
      return false
    end

    local progression = context.progression or {}
    local required = tonumber(context.required) or tonumber(progression.required) or 0
    local xp = tonumber(progression.xp) or 0
    local progress = tonumber(context.progress) or 0
    local core_points = get_available_skill_points(state) or 0
    local augment_points = get_available_augment_points(state) or 0

    set_caption(root, GUI.focused_status_title, core_display_name(state))
    set_caption(root, GUI.focused_status_subtitle, {
      "turret-xp.core-identity-summary",
      state.level or 0,
      state.bound_turret and { "turret-xp.core-bound-status" } or { "turret-xp.core-unbound-status" },
    })
    set_caption(root, GUI.focused_status_xp, {
      "turret-xp.xp-progress",
      format_number(xp, 0),
      format_number(required, 0),
    })
    set_caption(root, GUI.focused_status_points, {
      "turret-xp.status-unspent",
      core_points,
      augment_points,
    })
    set_caption(root, GUI.focused_status_role, {
      "turret-xp.status-role",
      role_caption(state),
    })
    set_caption(root, GUI.focused_status_build, build_status_caption(state))
    set_progress(root, GUI.xp_bar, progress)
    return true
  end

  return service
end

return focused_panel_module
