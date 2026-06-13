local gui_components = {}

function gui_components.new(deps)
  local service = {}

  function service.add_stat_row(parent, label, element_name, options)
    options = options or {}

    if #(parent.children or {}) > 0 then
      local delimiter = parent.add({
        type = "line",
        direction = "horizontal",
      })
      deps.set_style(delimiter, "horizontally_stretchable", true)
    end

    local row = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    deps.set_style(row, "horizontally_stretchable", true)
    deps.set_style(row, "width", deps.LAYOUT.stats_content_width)
    deps.set_style(row, "minimal_width", deps.LAYOUT.stats_content_width)
    deps.set_style(row, "maximal_width", deps.LAYOUT.stats_content_width)
    deps.set_style(row, "horizontal_spacing", 8)
    deps.set_style(row, "vertical_align", "center")

    local label_element = row.add({
      type = "label",
      caption = deps.with_info_marker(label, options.info_tooltip),
      tooltip = options.info_tooltip,
      style = "caption_label",
    })
    deps.set_style(label_element, "font_color", deps.COLOR.caption)
    deps.set_style(label_element, "single_line", false)
    deps.set_style(label_element, "maximal_width", deps.LAYOUT.stats_label_width)

    row.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    local value_flow_definition = {
      type = "flow",
      direction = "horizontal",
    }
    if options.flow_name then
      value_flow_definition.name = options.flow_name
    end
    local value_flow = row.add(value_flow_definition)
    deps.set_style(value_flow, "horizontal_align", "right")
    deps.set_style(value_flow, "width", deps.LAYOUT.stats_value_width)
    deps.set_style(value_flow, "minimal_width", deps.LAYOUT.stats_value_width)
    deps.set_style(value_flow, "maximal_width", deps.LAYOUT.stats_value_width)
    if options.flow_only then
      return label_element, value_flow
    end

    local value_element = value_flow.add({
      type = "label",
      name = element_name,
      caption = "-",
      style = options.value_style or "label",
    })
    deps.set_style(value_element, "horizontal_align", "right")
    deps.set_style(value_element, "single_line", false)
    deps.set_style(value_element, "width", options.maximal_width or deps.LAYOUT.stats_value_width)
    deps.set_style(value_element, "maximal_width", options.maximal_width or deps.LAYOUT.stats_value_width)

    return label_element, value_element
  end

  function service.make_stats_table(parent, name)
    local stat_table = parent.add({
      type = "flow",
      name = name,
      direction = "vertical",
    })
    deps.set_style(stat_table, "horizontally_stretchable", true)
    deps.set_style(stat_table, "width", deps.LAYOUT.stats_content_width)
    deps.set_style(stat_table, "minimal_width", deps.LAYOUT.stats_content_width)
    deps.set_style(stat_table, "maximal_width", deps.LAYOUT.stats_content_width)
    deps.set_style(stat_table, "vertical_spacing", 2)
    return stat_table
  end

  function service.add_summary_label(parent, title, value, value_color)
    local formatted_value = type(value) == "table" and value or deps.rich_color(value_color or "0.58,0.82,0.38", value)
    local caption = {
      "",
      title,
      ": ",
      formatted_value,
    }
    local label = parent.add({
      type = "label",
      caption = caption,
      style = "caption_label",
    })
    deps.set_style(label, "font_color", deps.COLOR.muted)
    deps.set_style(label, "single_line", true)
    deps.set_style(label, "left_margin", 8)
    return label
  end

  function service.add_choice_delimiter(parent)
    local delimiter = parent.add({
      type = "line",
      direction = "horizontal",
    })
    deps.set_style(delimiter, "horizontally_stretchable", true)
    deps.set_style(delimiter, "top_margin", 4)
    deps.set_style(delimiter, "bottom_margin", 4)
    return delimiter
  end

  function service.add_choice_row(parent, sprite, name, detail, right_caption, tags, enabled, row_name)
    local row_definition = {
      type = "table",
      column_count = 3,
    }
    if row_name then
      row_definition.name = row_name
    end
    local row = parent.add(row_definition)
    deps.set_evolution_content_width(row, true)
    deps.set_style(row, "horizontal_spacing", 8)
    deps.set_style(row, "vertical_spacing", 2)
    pcall(function()
      row.style.column_alignments[1] = "left"
      row.style.column_alignments[2] = "left"
      row.style.column_alignments[3] = "right"
    end)

    local icon = row.add({
      type = "sprite",
      sprite = sprite,
    })
    deps.set_style(icon, "size", 28)

    local details = row.add({
      type = "flow",
      direction = "vertical",
    })
    deps.set_style(details, "horizontally_stretchable", true)

    local title = details.add({
      type = "label",
      caption = name,
      style = "caption_label",
    })
    deps.set_style(title, "font", "default-bold")

    if detail and detail ~= "" then
      local desc = details.add({
        type = "label",
        caption = detail,
        style = "caption_label",
      })
      deps.set_style(desc, "font_color", deps.COLOR.muted)
      deps.set_style(desc, "single_line", false)
      deps.set_style(desc, "maximal_width", deps.LAYOUT.evolution_detail_width)
    end

    if tags then
      local button = row.add({
        type = "button",
        caption = right_caption,
        tags = tags,
        enabled = enabled,
      })
      deps.set_style(button, "minimal_width", 72)
      return button
    end

    local value = row.add({
      type = "label",
      caption = right_caption or "",
      style = "caption_label",
    })
    deps.set_style(value, "font_color", deps.COLOR.muted)
    return value
  end

  function service.add_evolution_section(parent, options)
    options = options or {}
    local section = parent.add({
      type = "frame",
      direction = "vertical",
      style = "deep_frame_in_shallow_frame",
    })
    deps.set_evolution_content_width(section)
    deps.set_style(section, "top_margin", 6)
    deps.set_style(section, "bottom_margin", 6)
    deps.set_style(section, "left_margin", deps.LAYOUT.evolution_section_margin)
    deps.set_style(section, "right_margin", deps.LAYOUT.evolution_section_margin)
    deps.set_style(section, "padding", { 6, 6, 6, 6 })

    if not options.unlocked then
      deps.set_style(section, "height", 70)
      deps.set_style(section, "vertical_align", "center")
      local locked = section.add({
        type = "label",
        caption = options.locked_caption,
        style = "caption_label",
      })
      deps.set_style(locked, "font", "default-bold")
      deps.set_style(locked, "horizontally_stretchable", true)
      deps.set_style(locked, "horizontal_align", "center")
      return section
    end

    if not options.title or options.title == "" then
      return section
    end

    local header = section.add({
      type = "flow",
      direction = "horizontal",
    })
    deps.set_evolution_content_width(header, true)
    deps.set_style(header, "horizontally_stretchable", true)
    deps.set_style(header, "vertical_align", "center")
    deps.set_style(header, "bottom_margin", 6)

    local title_label = header.add({
      type = "label",
      caption = options.title,
      style = "caption_label",
    })
    deps.set_style(title_label, "font", "default-bold")

    header.add({
      type = "empty-widget",
      style = "flib_horizontal_pusher",
    })

    if options.right_caption and options.right_caption ~= "" and not options.action_caption then
      local right = header.add({
        type = "label",
        caption = options.right_caption,
        style = "caption_label",
      })
      deps.set_style(right, "font_color", deps.COLOR.muted)
      deps.set_style(right, "right_margin", options.action_caption and 6 or 0)
    end

    if options.action_caption and options.action_tags then
      local button = header.add({
        type = "button",
        caption = options.action_caption,
        tooltip = options.action_tooltip,
        enabled = options.action_enabled ~= false,
        tags = options.action_tags,
      })
      deps.set_style(button, "minimal_width", 56)
    end

    if options.right_caption and options.right_caption ~= "" and options.action_caption then
      local right = section.add({
        type = "label",
        caption = options.right_caption,
        style = "caption_label",
      })
      deps.set_style(right, "font_color", deps.COLOR.muted)
      deps.set_style(right, "single_line", false)
      deps.set_style(right, "maximal_width", deps.LAYOUT.evolution_inner_width)
      deps.set_style(right, "top_margin", 2)
    end

    return section
  end

  return service
end

return gui_components
