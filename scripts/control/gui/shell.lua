local flib_gui = require("__flib__.gui")

local shell_module = {}

function shell_module.new(deps)
  local GUI = deps.GUI
  local LAYOUT = deps.LAYOUT
  local set_style = deps.set_style

  local function panel_definition(anchor)
    local definition = {
      type = "frame",
      name = GUI.panel,
      direction = "vertical",
      caption = { "turret-xp.panel-title" },
      children = {
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

  local function destroy_partial(root)
    local panel = root and root[GUI.panel] or nil
    if panel and panel.valid then
      panel.destroy()
    end
  end

  local function log_build_error(root_name, err)
    if log then
      log("[turret-xp] GUI shell build failed in " .. root_name .. ": " .. tostring(err))
    end
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
      log_build_error("player.gui.relative", result)
      destroy_partial(player.gui.relative)
      ok, result = pcall(function()
        local elems, frame = create_fallback(player)
        return {
          elems = elems,
          frame = frame,
        }
      end)
      if not ok or not result or not result.frame then
        log_build_error("player.gui.left", result)
      end
    end

    if not ok or not result or not result.frame then
      destroy_partial(player.gui.relative)
      destroy_partial(player.gui.left)
      return nil
    end

    apply_layout(result.elems, result.frame, mode)

    return {
      frame = result.frame,
      columns = result.elems[GUI.panel_columns],
      body = result.elems[GUI.panel_body],
    }
  end

  return service
end

return shell_module
