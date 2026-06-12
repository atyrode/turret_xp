local gui_support = {}

function gui_support.new(deps)
  local service = {}

  function service.format_percent(value, decimals)
    return deps.format_number((value or 0) * 100, decimals or 1) .. "%"
  end

  function service.color_to_rich_string(color)
    local source = color or deps.COLOR.bonus
    if type(source) == "table" then
      return tostring(source[1]) .. "," .. tostring(source[2]) .. "," .. tostring(source[3])
    end

    return tostring(source)
  end

  function service.rich_color(color, text)
    return "[color=" .. color .. "]" .. tostring(text) .. "[/color]"
  end

  function service.rich_number(text, color)
    return service.rich_color(service.color_to_rich_string(color or deps.COLOR.bonus), text)
  end

  function service.rich_stat_text(text, color)
    if type(text) ~= "string" then
      return text
    end

    local color_string = service.color_to_rich_string(color or deps.COLOR.bonus)
    return string.gsub(text, "([%+%-]?x?%d+%.?%d*%%?)", function(token)
      return service.rich_color(color_string, token)
    end)
  end

  function service.set_evolution_content_width(element, inner)
    if not element then
      return
    end

    local width = inner and deps.LAYOUT.evolution_inner_width or deps.LAYOUT.evolution_section_width
    deps.set_style(element, "horizontally_stretchable", true)
    deps.set_style(element, "width", width)
    deps.set_style(element, "minimal_width", width)
    deps.set_style(element, "maximal_width", width)
  end

  function service.set_card_text_width(element)
    if not element then
      return
    end

    deps.set_style(element, "single_line", false)
    deps.set_style(element, "maximal_width", deps.LAYOUT.evolution_card_inner_width)
  end

  function service.set_evolution_card_child_width(element)
    if not element then
      return
    end

    deps.set_style(element, "horizontally_stretchable", true)
    deps.set_style(element, "width", deps.LAYOUT.evolution_card_inner_width)
    deps.set_style(element, "minimal_width", deps.LAYOUT.evolution_card_inner_width)
    deps.set_style(element, "maximal_width", deps.LAYOUT.evolution_card_inner_width)
  end

  return service
end

return gui_support
