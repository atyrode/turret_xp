local core_picker_table_module = {}

function core_picker_table_module.new(deps)
  local GUI = deps.GUI
  local COLOR = deps.COLOR
  local LAYOUT = deps.LAYOUT
  local CHIP_NAME = deps.CHIP_NAME
  local set_style = deps.set_style
  local set_element_style = deps.set_element_style
  local widgets = deps.widgets

  local service = {}

  local SORT_MODES = {
    { id = "level", caption = { "turret-xp.inventory-core-sort-level" }, tooltip = { "turret-xp.inventory-core-sort-level-tooltip" } },
    { id = "name", caption = { "turret-xp.inventory-core-sort-name" }, tooltip = { "turret-xp.inventory-core-sort-name-tooltip" } },
    {
      id = "specialization",
      caption = { "stat-specialization" },
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

  local function add_header_label_cell(parent, caption, width, align)
    local label = parent.add({
      type = "label",
      caption = caption,
      style = "caption_label",
    })
    set_cell_width(label, width)
    set_style(label, "font", "default-bold")
    set_style(label, "font_color", COLOR.caption)
    set_style(label, "height", 24)
    set_style(label, "horizontal_align", align or "right")
    set_style(label, "single_line", true)
    return label
  end

  local function add_sort_header_cell(parent, mode, current_sort, width, align)
    local field, direction = parse_sort(current_sort)
    local active = field == mode.id
    local arrow_width = LAYOUT.inventory_core_sort_arrow_slot_width
    local button_width = math.max(12, width - arrow_width - 2)

    local cell = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_cell_width(cell, width)
    set_style(cell, "height", 24)
    set_style(cell, "horizontal_spacing", 2)
    set_style(cell, "vertical_align", "center")

    local button = cell.add({
      type = "button",
      caption = mode.caption,
      style = "transparent_button",
      tooltip = mode.tooltip,
      mouse_button_filter = { "left" },
      tags = {
        turret_xp_action = "set-core-sort",
        sort = mode.id,
      },
    })
    set_cell_width(button, button_width)
    set_style(button, "height", 24)
    set_style(button, "padding", 0)
    set_style(button, "font", "default-bold")
    set_style(button, "font_color", active and COLOR.bonus or COLOR.caption)
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

  local function add_value_cell(parent, caption, width, align)
    local label = parent.add({
      type = "label",
      caption = caption,
      style = "caption_label",
    })
    set_cell_width(label, width)
    set_style(label, "horizontal_align", align or "right")
    set_style(label, "single_line", true)
    return label
  end

  local function add_icon_cell(parent, row)
    local cell = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_cell_width(cell, LAYOUT.empty_inventory_core_icon_width)
    set_style(cell, "horizontal_align", "center")
    set_style(cell, "vertical_align", "center")

    local icon = cell.add({
      type = "sprite-button",
      sprite = "item/" .. CHIP_NAME,
      quality = row.quality,
      number = row.level_number,
      tooltip = row.install_tooltip,
      elem_tooltip = row.elem_tooltip,
      tags = row.install_tags,
    })
    set_element_style(icon, "slot_button")
    set_style(icon, "size", 32)
  end

  local function add_action_cell(parent, row)
    local cell = parent.add({
      type = "flow",
      direction = "horizontal",
    })
    set_cell_width(cell, LAYOUT.empty_inventory_core_action_width)
    set_style(cell, "horizontal_align", "center")
    set_style(cell, "vertical_align", "center")

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

  function service.add(parent, current_sort)
    local table_element = parent.add({
      type = "table",
      column_count = LAYOUT.inventory_core_table_column_count,
      style = "turret_xp_inventory_core_table",
    })
    set_style(table_element, "horizontally_stretchable", true)
    set_cell_width(table_element, LAYOUT.empty_inventory_core_table_width)
    set_style(table_element, "horizontal_spacing", LAYOUT.inventory_core_table_spacing)
    set_style(table_element, "vertical_spacing", 0)
    pcall(function()
      for index = 1, LAYOUT.inventory_core_table_column_count do
        table_element.style.column_alignments[index] = index >= 4 and "right" or "left"
      end
      table_element.style.column_alignments[LAYOUT.inventory_core_table_column_count] = "center"
      table_element.draw_horizontal_lines = false
      table_element.draw_horizontal_line_after_headers = true
      table_element.draw_vertical_lines = false
    end)

    add_header_label_cell(table_element, "", LAYOUT.empty_inventory_core_icon_width, "left")
    add_sort_header_cell(table_element, sort_mode_by_id("name"), current_sort, LAYOUT.empty_inventory_core_name_width, "left")
    add_sort_header_cell(
      table_element,
      sort_mode_by_id("specialization"),
      current_sort,
      LAYOUT.empty_inventory_core_specialization_width,
      "left"
    )
    add_sort_header_cell(table_element, sort_mode_by_id("level"), current_sort, LAYOUT.empty_inventory_core_level_width, "right")
    add_sort_header_cell(table_element, sort_mode_by_id("hp"), current_sort, LAYOUT.empty_inventory_core_stat_width, "right")
    add_sort_header_cell(table_element, sort_mode_by_id("attack"), current_sort, LAYOUT.empty_inventory_core_attack_width, "right")
    add_sort_header_cell(table_element, sort_mode_by_id("range"), current_sort, LAYOUT.empty_inventory_core_stat_width, "right")
    add_header_label_cell(table_element, "", LAYOUT.empty_inventory_core_action_width)

    return table_element
  end

  function service.add_row(parent, row)
    add_icon_cell(parent, row)

    local details = parent.add({
      type = "flow",
      direction = "vertical",
    })
    set_cell_width(details, LAYOUT.empty_inventory_core_name_width)

    local name = details.add({
      type = "label",
      caption = row.name_caption,
      style = "caption_label",
    })
    set_style(name, "font", "default-bold")
    set_style(name, "single_line", false)
    set_style(name, "maximal_width", LAYOUT.empty_inventory_core_name_width)

    local specialization = add_value_cell(parent, row.specialization_caption, LAYOUT.empty_inventory_core_specialization_width, "left")
    set_style(specialization, "font_color", COLOR.muted)
    add_value_cell(parent, row.level_caption, LAYOUT.empty_inventory_core_level_width)
    add_value_cell(parent, row.hp_caption, LAYOUT.empty_inventory_core_stat_width)
    add_value_cell(parent, row.attack_caption, LAYOUT.empty_inventory_core_attack_width)
    add_value_cell(parent, row.range_caption, LAYOUT.empty_inventory_core_stat_width)
    add_action_cell(parent, row)
  end

  return service
end

return core_picker_table_module
