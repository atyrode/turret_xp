local core_picker_table_module = {}

function core_picker_table_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local LAYOUT = deps.LAYOUT
  local set_style = deps.set_style
  local widgets = deps.widgets

  local service = {}

  local SORT_MODES = {
    { id = "level", caption = { "turret-xp.inventory-core-sort-level" }, tooltip = { "turret-xp.inventory-core-sort-level-tooltip" } },
    { id = "name", caption = { "turret-xp.inventory-core-sort-name" }, tooltip = { "turret-xp.inventory-core-sort-name-tooltip" } },
    {
      id = "specialization",
      caption = { "turret-xp.stat-specialization" },
      tooltip = { "turret-xp.inventory-core-sort-specialization-tooltip" },
    },
    { id = "hp", caption = { "turret-xp.inventory-core-stat-hp" }, tooltip = { "turret-xp.inventory-core-sort-hp-tooltip" } },
    { id = "attack", caption = { "turret-xp.inventory-core-stat-attack" }, tooltip = { "turret-xp.inventory-core-sort-attack-tooltip" } },
    { id = "range", caption = { "turret-xp.inventory-core-stat-range" }, tooltip = { "turret-xp.inventory-core-sort-range-tooltip" } },
  }

  local function set_cell_width(element, width)
    set_style(element, "width", width)
    set_style(element, "minimal_width", width)
    set_style(element, "maximal_width", width)
  end

  local function cell_content_width(width)
    return math.max(0, width - (LAYOUT.inventory_core_table_cell_horizontal_padding * 2))
  end

  local function sort_mode_by_id(id)
    for _, mode in ipairs(SORT_MODES) do
      if mode.id == id then
        return mode
      end
    end
    return nil
  end

  local function parse_sort(sort_mode)
    local field, direction = string.match(tostring(sort_mode or ""), "^([^:]+):([^:]+)$")
    if field ~= "level" and field ~= "name" and field ~= "specialization" and field ~= "hp" and field ~= "attack" and field ~= "range" then
      return nil, nil
    end
    if direction ~= "asc" and direction ~= "desc" then
      return nil, nil
    end

    return field, direction
  end

  local function add_cell(parent, width, height, align, style)
    local cell = parent.add({
      type = "flow",
      direction = "horizontal",
      style = style or "turret_xp_inventory_core_table_cell",
    })
    set_cell_width(cell, width)
    set_style(cell, "height", height)
    set_style(cell, "horizontal_align", align or "left")
    set_style(cell, "vertical_align", "center")
    return cell
  end

  local function add_header_label_cell(parent, caption, width, align)
    local cell = add_cell(parent, width, LAYOUT.inventory_core_table_header_height, align or "right")
    local label = cell.add({
      type = "label",
      caption = caption,
      style = "caption_label",
    })
    set_cell_width(label, cell_content_width(width))
    set_style(label, "font", "default-bold")
    set_style(label, "font_color", COLOR.caption)
    set_style(label, "height", LAYOUT.inventory_core_table_header_height)
    set_style(label, "horizontal_align", align or "right")
    set_style(label, "single_line", true)
    return cell
  end

  local function add_sort_header_cell(parent, mode, current_sort, width, align)
    local field, direction = parse_sort(current_sort)
    local active = field == mode.id
    local arrow_width = LAYOUT.inventory_core_sort_arrow_slot_width
    local button_width = math.max(12, cell_content_width(width) - arrow_width - 2)

    local cell = add_cell(parent, width, LAYOUT.inventory_core_table_header_height, align or "left")
    set_style(cell, "horizontal_spacing", 2)

    local button = cell.add({
      type = "button",
      caption = mode.caption,
      style = "turret_xp_table_header_button",
      tooltip = mode.tooltip,
      mouse_button_filter = { "left" },
      tags = {
        turret_xp_action = "set-core-sort",
        sort = mode.id,
      },
    })
    set_cell_width(button, button_width)
    set_style(button, "height", LAYOUT.inventory_core_table_header_height)
    set_style(button, "padding", 0)
    set_style(button, "font", "default-bold")
    set_style(button, "font_color", active and { 1, 1, 1 } or COLOR.caption)
    set_style(button, "horizontal_align", align or "left")
    set_style(button, "single_line", true)

    if active then
      local arrow = cell.add({
        type = "sprite",
        sprite = direction == "asc" and GUI.sort_arrow_up or GUI.sort_arrow_down,
        tooltip = mode.tooltip,
      })
      set_style(arrow, "width", 8)
      set_style(arrow, "height", 8)
      set_style(arrow, "stretch_image_to_widget_size", true)
      set_style(arrow, "right_margin", math.max(0, arrow_width - 8))
    else
      local spacer = cell.add({
        type = "empty-widget",
      })
      set_style(spacer, "width", arrow_width)
      set_style(spacer, "height", 8)
    end

    return cell
  end

  local function add_value_cell(parent, caption, width, align, font_color)
    local cell = add_cell(parent, width, LAYOUT.inventory_core_table_row_height, align or "right")
    local label = cell.add({
      type = "label",
      caption = caption,
      style = "caption_label",
    })
    set_cell_width(label, cell_content_width(width))
    set_style(label, "height", LAYOUT.inventory_core_table_row_height)
    set_style(label, "horizontal_align", align or "right")
    set_style(label, "single_line", true)
    if font_color then
      set_style(label, "font_color", font_color)
    end
    return label
  end

  local function add_action_cell(parent, row)
    local cell = add_cell(
      parent,
      LAYOUT.empty_inventory_core_action_width,
      LAYOUT.inventory_core_table_row_height,
      "center",
      "turret_xp_inventory_core_table_action_cell"
    )

    widgets.add_tool_button(cell, {
      sprite = "utility/add",
      style = "flib_tool_button_light_green",
      tooltip = row.install_tooltip,
      size = LAYOUT.empty_inventory_core_action_button_size,
      tags = row.install_tags,
    })
  end

  function service.parse_sort(sort_mode)
    return parse_sort(sort_mode)
  end

  function service.sort_mode_by_id(id)
    return sort_mode_by_id(id)
  end

  local function configure_table(table_element)
    set_style(table_element, "horizontally_stretchable", true)
    set_cell_width(table_element, LAYOUT.empty_inventory_core_table_width)
    set_style(table_element, "horizontal_spacing", LAYOUT.inventory_core_table_spacing)
    set_style(table_element, "vertical_spacing", 0)
    pcall(function()
      for index = 1, LAYOUT.inventory_core_table_column_count do
        table_element.style.column_alignments[index] = "center"
      end
      table_element.style.column_alignments[1] = "left"
      table_element.style.column_alignments[2] = "left"
      table_element.style.column_alignments[3] = "left"
      table_element.style.column_alignments[4] = "right"
      table_element.style.column_alignments[5] = "right"
      table_element.style.column_alignments[6] = "right"
      table_element.style.column_alignments[LAYOUT.inventory_core_table_column_count] = "center"
      table_element.draw_horizontal_lines = true
      table_element.draw_horizontal_line_after_headers = true
      table_element.draw_vertical_lines = true
    end)
  end

  local function add_table(parent)
    local table_element = parent.add({
      type = "table",
      column_count = LAYOUT.inventory_core_table_column_count,
      style = "turret_xp_inventory_core_table",
    })
    configure_table(table_element)
    return table_element
  end

  function service.add(parent, current_sort)
    local container = parent.add({
      type = "flow",
      direction = "vertical",
    })
    set_cell_width(container, LAYOUT.empty_inventory_core_table_width)
    set_style(container, "left_margin", LAYOUT.inventory_core_table_side_margin)
    set_style(container, "right_margin", LAYOUT.inventory_core_table_side_margin)
    set_style(container, "vertical_spacing", 0)

    local table_element = add_table(container)

    add_sort_header_cell(table_element, sort_mode_by_id("level"), current_sort, LAYOUT.empty_inventory_core_level_width, "left")
    add_sort_header_cell(table_element, sort_mode_by_id("name"), current_sort, LAYOUT.empty_inventory_core_name_width, "left")
    add_sort_header_cell(
      table_element,
      sort_mode_by_id("specialization"),
      current_sort,
      LAYOUT.empty_inventory_core_specialization_width,
      "left"
    )
    add_sort_header_cell(table_element, sort_mode_by_id("hp"), current_sort, LAYOUT.empty_inventory_core_stat_width, "right")
    add_sort_header_cell(table_element, sort_mode_by_id("attack"), current_sort, LAYOUT.empty_inventory_core_attack_width, "right")
    add_sort_header_cell(table_element, sort_mode_by_id("range"), current_sort, LAYOUT.empty_inventory_core_stat_width, "right")
    add_header_label_cell(table_element, "", LAYOUT.empty_inventory_core_action_width)

    return table_element
  end

  function service.add_row(parent, row)
    add_value_cell(parent, row.level_caption, LAYOUT.empty_inventory_core_level_width, "left")

    local name_cell = add_cell(parent, LAYOUT.empty_inventory_core_name_width, LAYOUT.inventory_core_table_row_height, "left")
    local name = name_cell.add({
      type = "label",
      caption = row.name_caption,
      style = "caption_label",
    })
    set_cell_width(name, cell_content_width(LAYOUT.empty_inventory_core_name_width))
    set_style(name, "font", "default-bold")
    set_style(name, "height", LAYOUT.inventory_core_table_row_height)
    set_style(name, "single_line", true)
    set_style(name, "maximal_width", cell_content_width(LAYOUT.empty_inventory_core_name_width))

    add_value_cell(parent, row.specialization_caption, LAYOUT.empty_inventory_core_specialization_width, "left", COLOR.muted)
    add_value_cell(parent, row.hp_caption, LAYOUT.empty_inventory_core_stat_width)
    add_value_cell(parent, row.attack_caption, LAYOUT.empty_inventory_core_attack_width)
    add_value_cell(parent, row.range_caption, LAYOUT.empty_inventory_core_stat_width)
    add_action_cell(parent, row)
  end

  return service
end

return core_picker_table_module
