local core_platform_controls_module = {}

function core_platform_controls_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local LAYOUT = deps.LAYOUT
  local CHIP_NAME = deps.CHIP_NAME
  local components = deps.components
  local set_style = deps.set_style
  local set_element_style = deps.set_element_style
  local get_platform_hub_inventory = deps.get_platform_hub_inventory
  local get_platform_core_options = deps.get_platform_core_options
  local create_blank_profile = deps.create_blank_profile
  local preview_stats = deps.preview_stats
  local specialization_caption = deps.specialization_caption
  local widgets = deps.widgets

  local service = {}

  local function plain_metric(label, value, suffix)
    return {
      "",
      label,
      " ",
      tostring(value or "-"),
      suffix or "",
    }
  end

  local function add_installed_core_row(frame)
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
    widgets.add_tool_button(flow, {
      sprite = "utility/export_slot",
      tooltip = { "turret-xp.platform-core-send-tooltip" },
      tags = {
        turret_xp_action = "platform-send-core",
      },
    })
  end

  local function add_empty_label(frame)
    local label = frame.add({
      type = "label",
      caption = { "turret-xp.platform-core-empty" },
      style = "caption_label",
    })
    set_style(label, "font_color", COLOR.muted)
    set_style(label, "single_line", false)
  end

  local function add_core_option_row(frame, entity, option)
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
    set_style(icon, "size", LAYOUT.platform_core_icon_size)

    local details = row.add({
      type = "flow",
      direction = "vertical",
    })
    set_style(details, "horizontally_stretchable", true)
    set_style(details, "width", LAYOUT.platform_core_row_detail_width)
    set_style(details, "minimal_width", LAYOUT.platform_core_row_detail_width)
    set_style(details, "maximal_width", LAYOUT.platform_core_row_detail_width)
    local core_name = profile.custom_name and profile.custom_name ~= "" and profile.custom_name or { "turret-xp.platform-core-unnamed" }
    local name = details.add({
      type = "label",
      caption = core_name,
      style = "caption_label",
    })
    set_style(name, "font", "default-bold")
    set_style(name, "single_line", false)
    set_style(name, "maximal_width", LAYOUT.platform_core_row_detail_width)
    local stats = preview_stats(entity, profile)
    local summary = details.add({
      type = "label",
      caption = { "turret-xp.platform-core-summary", tostring(profile.level or 0), specialization_caption(profile) },
      style = "caption_label",
    })
    set_style(summary, "font_color", COLOR.muted)
    set_style(summary, "single_line", false)
    set_style(summary, "maximal_width", LAYOUT.platform_core_row_detail_width)
    local stat_summary = details.add({
      type = "label",
      caption = {
        "turret-xp.inventory-core-compact-stats",
        plain_metric({ "turret-xp.inventory-core-stat-hp" }, stats.health),
        plain_metric({ "turret-xp.inventory-core-stat-attack" }, stats.speed, "/s"),
        plain_metric({ "turret-xp.inventory-core-stat-range" }, stats.range),
      },
      style = "caption_label",
    })
    set_style(stat_summary, "font_color", COLOR.muted)
    set_style(stat_summary, "single_line", false)
    set_style(stat_summary, "maximal_width", LAYOUT.platform_core_row_detail_width)

    widgets.add_tool_button(row, {
      sprite = "utility/import_slot",
      style = "flib_tool_button_light_green",
      tooltip = { "turret-xp.platform-core-install-tooltip" },
      tags = {
        turret_xp_action = "platform-install-core",
        slot = option.index,
      },
    })
  end

  function service.add_list(parent, entity, state)
    local hub_inventory = get_platform_hub_inventory(entity)
    if not hub_inventory then
      return
    end

    local options = get_platform_core_options(entity)
    local frame = components.add_section_frame(parent, {
      name = GUI.platform_cores,
      top_margin = 6,
      title = { "turret-xp.platform-core-title" },
      right_caption = not state and #options > 0 and { "turret-xp.inventory-core-count", #options } or nil,
    })

    if state then
      add_installed_core_row(frame)
      return
    end

    if #options == 0 then
      add_empty_label(frame)
      return
    end

    for index, option in ipairs(options) do
      if index > 1 then
        components.add_choice_delimiter(frame)
      end
      add_core_option_row(frame, entity, option)
    end
  end

  return service
end

return core_platform_controls_module
