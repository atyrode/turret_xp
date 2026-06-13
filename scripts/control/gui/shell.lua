local flib_gui = require("__flib__.gui")

local shell_module = {}

function shell_module.new(deps)
  local GUI = deps.GUI
  local LAYOUT = deps.LAYOUT
  local CHIP_NAME = deps.CHIP_NAME
  local set_style = deps.set_style

  local function panel_definition(anchor)
    local definition = {
      type = "frame",
      name = GUI.panel,
      direction = "vertical",
      children = {
        {
          type = "flow",
          name = GUI.panel_header,
          direction = "horizontal",
          style = "frame_header_flow",
          drag_target = GUI.panel,
          children = {
            {
              type = "sprite",
              name = GUI.panel_header_icon,
              sprite = "item/" .. CHIP_NAME,
              ignored_by_interaction = true,
            },
            {
              type = "label",
              name = GUI.panel_title,
              caption = { "turret-xp.panel-title" },
              style = "frame_title",
              ignored_by_interaction = true,
            },
            {
              type = "empty-widget",
              name = GUI.panel_header_drag_handle,
              style = "flib_titlebar_drag_handle",
              ignored_by_interaction = true,
            },
          },
        },
        {
          type = "flow",
          name = GUI.panel_columns,
          direction = "horizontal",
          children = {
            {
              type = "frame",
              name = GUI.panel_body,
              direction = "vertical",
              style = "inside_shallow_frame_with_padding",
            },
          },
        },
      },
    }

    if anchor then
      definition.anchor = {
        gui = defines.relative_gui_type.turret_gui,
        position = defines.relative_gui_position.right,
      }
    end

    return definition
  end

  local function normalize_mode(mode)
    return mode == "empty" and "empty" or "installed"
  end

  local function apply_layout(elems, frame, mode)
    mode = normalize_mode(mode)
    frame.tags = {
      turret_xp_mode = mode,
    }
    set_style(frame, "maximal_width", mode == "empty" and LAYOUT.empty_panel_max_width or LAYOUT.panel_max_width)

    local header = elems[GUI.panel_header]
    pcall(function()
      header.drag_target = frame
    end)
    set_style(header, "horizontally_stretchable", true)
    set_style(header, "vertical_align", "center")

    local icon = elems[GUI.panel_header_icon]
    set_style(icon, "size", 24)
    set_style(icon, "right_margin", 4)

    local title = elems[GUI.panel_title]
    set_style(title, "font", "default-bold")
    set_style(title, "right_margin", 8)

    local drag_handle = elems[GUI.panel_header_drag_handle]
    pcall(function()
      drag_handle.drag_target = frame
    end)
    set_style(drag_handle, "horizontally_stretchable", true)

    local columns = elems[GUI.panel_columns]
    set_style(columns, "horizontally_stretchable", true)
    set_style(columns, "vertical_align", "top")
    set_style(columns, "horizontal_spacing", LAYOUT.column_spacing)

    local body = elems[GUI.panel_body]
    local body_width = mode == "empty" and LAYOUT.empty_panel_width or LAYOUT.left_column_width
    set_style(body, "width", body_width)
    set_style(body, "minimal_width", body_width)
    set_style(body, "maximal_width", body_width)
  end

  local function create_relative(player)
    return flib_gui.add(player.gui.relative, panel_definition(true))
  end

  local function create_fallback(player)
    return flib_gui.add(player.gui.left, panel_definition(false))
  end

  local service = {}

  function service.build(player, mode)
    local ok, result = pcall(function()
      local elems, frame = create_relative(player)
      return {
        elems = elems,
        frame = frame,
      }
    end)

    if not ok or not result or not result.frame then
      ok, result = pcall(function()
        local elems, frame = create_fallback(player)
        return {
          elems = elems,
          frame = frame,
        }
      end)
    end

    if not ok or not result or not result.frame then
      return nil
    end

    apply_layout(result.elems, result.frame, mode)

    return {
      frame = result.frame,
      columns = result.elems[GUI.panel_columns],
      body = result.elems[GUI.panel_body],
      header = result.elems[GUI.panel_header],
    }
  end

  return service
end

return shell_module
