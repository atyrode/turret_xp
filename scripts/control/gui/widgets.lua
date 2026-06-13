local widgets_module = {}

function widgets_module.new(deps)
  local set_style = deps.set_style

  local service = {}

  function service.add_tool_button(parent, options)
    local definition = {
      type = "sprite-button",
      sprite = options.sprite,
      style = options.style or "tool_button",
      tooltip = options.tooltip,
      tags = options.tags,
      mouse_button_filter = options.mouse_button_filter or { "left" },
    }
    if options.name then
      definition.name = options.name
    end
    if options.enabled ~= nil then
      definition.enabled = options.enabled
    end

    local button = parent.add(definition)
    local size = options.size or 28
    set_style(button, "width", size)
    set_style(button, "height", size)
    set_style(button, "minimal_width", size)
    set_style(button, "minimal_height", size)
    set_style(button, "maximal_width", size)
    set_style(button, "maximal_height", size)

    return button
  end

  return service
end

return widgets_module
