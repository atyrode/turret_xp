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
  local ensure_evolution_state = deps.ensure_evolution_state
  local get_base_rank = deps.get_base_rank
  local get_augment_rank = deps.get_augment_rank
  local GATES = deps.GATES or {}
  local rich_specialization_caption = deps.rich_specialization_caption
  local format_number = deps.format_number
  local profile_automation = deps.profile_automation
  local get_turret_host = deps.get_turret_host
  local get_platform_hub_inventory = deps.get_platform_hub_inventory
  local core_requester = deps.core_requester
  local widgets = deps.widgets
  local core_label_controls = deps.core_label_controls
  local core_automation_controls = deps.core_automation_controls
  local add_stats_panel = deps.add_stats_panel
  local update_stats_panel = deps.update_stats_panel
  local add_evolution_panel = deps.add_evolution_panel
  local update_evolution_panel = deps.update_evolution_panel

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

  local function focused_content_key(view_id, state)
    if view_id == "overview" then
      local evolution = state and ensure_evolution_state and ensure_evolution_state(state) or {}
      return table.concat({
        "overview",
        tostring(state and state.level or 0),
        tostring(state and get_available_skill_points(state) or 0),
        tostring(state and get_available_augment_points(state) or 0),
        tostring(evolution.specialization or ""),
        tostring(evolution.sub_specialization or ""),
        tostring(evolution.elements and evolution.elements[1] or ""),
        tostring(evolution.elements and evolution.elements[2] or ""),
        tostring(state and state.show_name_label == true),
        tostring(state and state.show_label_level == true),
        tostring(state and state.show_unspent_label == true),
        tostring(state and get_base_rank and get_base_rank(state, "damage") or 0),
        tostring(state and get_base_rank and get_base_rank(state, "resistance") or 0),
        tostring(state and get_base_rank and get_base_rank(state, "ammo_regen") or 0),
        tostring(state and get_augment_rank and get_augment_rank(state, "siphon") or 0),
        tostring(state and get_augment_rank and get_augment_rank(state, "bounce") or 0),
      }, ":")
    end

    if view_id == "automation" then
      local target = profile_automation.target_model(state) or {}
      return table.concat({
        "automation",
        tostring(state and profile_automation.build_mode_active(state) == true),
        tostring(state and state.automation_enabled == true),
        tostring(target.level or ""),
        tostring(target.core or ""),
        tostring(target.augments or ""),
        tostring(target.choice or ""),
        tostring(target.elements or ""),
      }, ":")
    end

    return view_id or "overview"
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

  local function add_content_shell(parent, view_id, state)
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
      key = focused_content_key(view.id, state),
    }
    set_style(content, "horizontally_stretchable", true)
    set_style(content, "height", LAYOUT.focused_content_height)
    set_style(content, "maximal_height", LAYOUT.focused_content_height)
    set_style(content, "vertical_spacing", 8)
    return content, view
  end

  local function add_view_root(parent, view)
    local inner = parent.add({
      type = "flow",
      name = view.name,
      direction = "vertical",
    })
    inner.tags = {
      turret_xp_content_view = view.id,
    }
    set_style(inner, "horizontally_stretchable", true)
    set_style(inner, "vertical_spacing", 8)
    return inner
  end

  local function add_overview_card(parent, title_caption, body_caption, options)
    options = options or {}
    local card = parent.add({
      type = "frame",
      direction = "vertical",
      style = "inside_shallow_frame_with_padding",
    })
    set_style(card, "width", options.width or 350)
    set_style(card, "minimal_width", options.width or 350)
    set_style(card, "maximal_width", options.width or 350)
    set_style(card, "vertical_spacing", options.vertical_spacing or 4)

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

  local function next_goal_caption(state)
    if not state then
      return { "turret-xp.overview-next-live" }
    end

    local level = state.level or 0
    local core_points = get_available_skill_points(state) or 0
    local augment_points = get_available_augment_points(state) or 0
    if core_points > 0 or augment_points > 0 then
      return { "turret-xp.overview-next-spend", core_points, augment_points }
    end

    local evolution = ensure_evolution_state and ensure_evolution_state(state) or {}
    if GATES.specialization and level < GATES.specialization then
      return { "turret-xp.overview-next-gate", { "turret-xp.section-specialization" }, GATES.specialization }
    end
    if GATES.specialization and not evolution.specialization then
      return { "turret-xp.overview-next-choice", { "turret-xp.section-specialization" } }
    end
    if GATES.first_element and level < GATES.first_element then
      return { "turret-xp.overview-next-gate", { "turret-xp.section-first-element" }, GATES.first_element }
    end
    if GATES.first_element and not (evolution.elements and evolution.elements[1]) then
      return { "turret-xp.overview-next-choice", { "turret-xp.section-first-element" } }
    end
    if GATES.augments and level < GATES.augments then
      return { "turret-xp.overview-next-gate", { "turret-xp.section-augments" }, GATES.augments }
    end
    if GATES.sub_specialization and level < GATES.sub_specialization then
      return { "turret-xp.overview-next-gate", { "turret-xp.section-sub-specialization" }, GATES.sub_specialization }
    end
    if GATES.second_element and level < GATES.second_element then
      return { "turret-xp.overview-next-gate", { "turret-xp.section-second-element" }, GATES.second_element }
    end
    return { "turret-xp.overview-next-live" }
  end

  local function strength_caption(state)
    local parts = {}
    local function add_rank(label, rank)
      if rank and rank > 0 then
        parts[#parts + 1] = { "turret-xp.overview-rank-highlight", label, rank }
      end
    end

    add_rank({ "turret-xp.overview-highlight-damage" }, get_base_rank and get_base_rank(state, "damage") or 0)
    add_rank({ "turret-xp.overview-highlight-resistance" }, get_base_rank and get_base_rank(state, "resistance") or 0)
    add_rank({ "turret-xp.overview-highlight-ammo" }, get_base_rank and get_base_rank(state, "ammo_regen") or 0)
    add_rank({ "turret-xp.overview-highlight-shield" }, get_augment_rank and get_augment_rank(state, "siphon") or 0)
    add_rank({ "turret-xp.overview-highlight-bounce" }, get_augment_rank and get_augment_rank(state, "bounce") or 0)

    if #parts == 0 then
      return { "turret-xp.overview-no-highlights" }
    end

    local caption = { "" }
    for index, part in ipairs(parts) do
      if index > 1 then
        caption[#caption + 1] = "\n"
      end
      caption[#caption + 1] = part
    end
    return caption
  end

  local function add_overview_content(content, view, state)
    local inner = add_view_root(content, view)
    local title = inner.add({
      type = "label",
      caption = { "turret-xp.view-overview" },
      style = "heading_2_label",
    })
    set_style(title, "font", "default-bold")

    local rows = inner.add({
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
      profile_automation.build_mode_active(state) and { "turret-xp.overview-next-build" } or next_goal_caption(state),
    })
    add_overview_card(rows, { "turret-xp.overview-role" }, {
      "",
      role_caption(state),
      "\n",
      build_status_caption(state),
    })
    add_overview_card(rows, { "turret-xp.overview-strengths" }, strength_caption(state))
    add_overview_card(rows, { "turret-xp.overview-labels" }, {
      "turret-xp.overview-label-summary",
      on_off_caption(state.show_name_label == true),
      on_off_caption(state.show_label_level == true),
      on_off_caption(state.show_unspent_label == true),
    })

    if core_label_controls then
      core_label_controls.add(inner, state)
    end
  end

  local function add_progression_content(content, view)
    local inner = add_view_root(content, view)
    if not add_evolution_panel then
      return inner
    end

    add_evolution_panel(inner, {
      header_name = GUI.focused_progression_summary,
      scroll_name = GUI.focused_progression_scroll,
      width = LAYOUT.focused_detail_width,
      scroll_width = LAYOUT.focused_detail_width,
      height = LAYOUT.focused_content_height - 6,
      scroll_height = LAYOUT.focused_content_height - LAYOUT.evolution_header_height - 12,
    })
    return inner
  end

  local function add_stats_content(content, view)
    local inner = add_view_root(content, view)
    if not add_stats_panel then
      return inner
    end

    add_stats_panel(inner, {
      header_name = GUI.focused_stats_header,
      scroll_name = GUI.focused_stats_scroll,
      table_name = GUI.focused_stats_table,
      width = LAYOUT.focused_detail_width,
      scroll_width = LAYOUT.focused_detail_width,
      scroll_height = LAYOUT.focused_content_height - LAYOUT.stats_header_height - 16,
      build_scroll_height = LAYOUT.focused_content_height - LAYOUT.stats_header_height - 16,
    })
    return inner
  end

  local function add_automation_content(content, view, state)
    local inner = add_view_root(content, view)
    local title = inner.add({
      type = "label",
      caption = { "turret-xp.view-automation" },
      style = "heading_2_label",
    })
    set_style(title, "font", "default-bold")

    local summary = inner.add({
      type = "label",
      caption = { "turret-xp.automation-view-summary" },
      style = "caption_label",
    })
    set_style(summary, "font_color", COLOR.muted)
    set_style(summary, "single_line", false)
    set_style(summary, "maximal_width", LAYOUT.focused_detail_width)

    if core_automation_controls then
      core_automation_controls.add_installed(inner, state)
    end
    return inner
  end

  local function add_view_content(parent, view_id, state)
    local content, view = add_content_shell(parent, view_id, state)
    if view.id == "overview" then
      add_overview_content(content, view, state)
      return content
    end

    if view.id == "progression" then
      add_progression_content(content, view)
      return content
    end

    if view.id == "stats" then
      add_stats_content(content, view)
      return content
    end

    if view.id == "automation" then
      add_automation_content(content, view, state)
      return content
    end

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

  local function update_active_content(root, entity, context)
    local content = find_gui_element(root, GUI.focused_content)
    local active_view = content and content.tags and content.tags.turret_xp_active_view or nil
    local display_state = context and (context.state or context.live_state) or nil
    if active_view == "progression" and update_evolution_panel then
      update_evolution_panel(
        content,
        entity,
        display_state,
        context and context.ammo_name or nil,
        context and context.evolution_anchor or nil
      )
      return
    end

    if active_view == "stats" and update_stats_panel then
      update_stats_panel(
        content,
        entity,
        display_state,
        context and context.ammo_name or nil,
        context and context.ammo_count or nil,
        context and context.ammo_quality or nil,
        context and context.ammo_in_magazine or nil,
        context and context.ammo_magazine_size or nil,
        context and context.quality_name or nil,
        context and context.max_health or nil,
        context and context.health or nil
      )
    end
  end

  function service.add_installed_panel(parent, player, _entity, state)
    local selected_view = get_focused_gui_view(player)
    add_status_strip(parent, state)
    add_view_nav(parent, selected_view)
    add_view_content(parent, selected_view, state)
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

  function service.update_status(root, entity, context)
    local state = context and context.live_state or nil
    if not state then
      return false
    end

    local content = find_gui_element(root, GUI.focused_content)
    if not content or not content.tags or content.tags.turret_xp_active_view ~= get_focused_gui_view(context.player) then
      return false
    end
    if content.tags.key ~= focused_content_key(content.tags.turret_xp_active_view, context.state or state) then
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
    update_active_content(root, entity, context)
    return true
  end

  return service
end

return focused_panel_module
