local stats_formatter = {}

function stats_formatter.new(deps)
  local service = {}
  local COLOR = deps.COLOR

  function service.format_number(value, decimals)
    if not value then
      return "-"
    end

    if math.abs(value - math.floor(value)) < 0.01 then
      return string.format("%d", math.floor(value + 0.5))
    end

    return string.format("%." .. tostring(decimals or 1) .. "f", value)
  end

  function service.format_colored_bonus(value, decimals, numeric_suffix)
    local formatted = service.format_number(math.abs(value), decimals)
    local sign = value < 0 and "- " or "+ "
    local color = value < 0 and COLOR.penalty or COLOR.bonus
    return "[color=" .. color[1] .. "," .. color[2] .. "," .. color[3] .. "]" .. sign .. formatted .. (numeric_suffix or "") .. "[/color]"
  end

  function service.format_base_plus_bonus(base, bonus, suffix, decimals)
    suffix = suffix or ""

    if not base then
      return "-"
    end

    if bonus and math.abs(bonus) >= 0.005 then
      local numeric_suffix = ""
      local text_suffix = suffix
      if string.sub(suffix, 1, 1) == "%" then
        numeric_suffix = "%"
        text_suffix = string.sub(suffix, 2)
      end
      return service.format_number(base, decimals) .. " " .. service.format_colored_bonus(bonus, decimals, numeric_suffix) .. text_suffix
    end

    return service.format_number(base, decimals) .. suffix
  end

  function service.format_colored_multiplier(multiplier)
    if not multiplier or math.abs(multiplier - 1) < 0.005 then
      return nil
    end

    local color = multiplier < 1 and COLOR.penalty or COLOR.bonus
    return "[color=" .. color[1] .. "," .. color[2] .. "," .. color[3] .. "]x" .. service.format_number(multiplier, 2) .. "[/color]"
  end

  function service.append_multiplier(caption, multiplier)
    local formatted = service.format_colored_multiplier(multiplier)
    if not formatted then
      return caption
    end

    return { "", caption, " ", formatted }
  end

  function service.format_stat_formula(base, additive, multiplier, total, suffix, decimals)
    if not total then
      return "-"
    end

    suffix = suffix or ""
    local numeric_suffix = ""
    local text_suffix = suffix
    if string.sub(suffix, 1, 1) == "%" then
      numeric_suffix = "%"
      text_suffix = string.sub(suffix, 2)
    end
    local has_additive = additive and math.abs(additive) >= 0.005
    local has_multiplier = multiplier and math.abs(multiplier - 1) >= 0.005
    if not has_additive and not has_multiplier then
      return service.format_number(total, decimals) .. suffix
    end

    local base_text = service.format_number(base or 0, decimals) .. numeric_suffix
    local total_text = service.format_number(total, decimals) .. numeric_suffix .. text_suffix
    if has_additive and has_multiplier then
      return {
        "",
        "(",
        base_text,
        " ",
        service.format_colored_bonus(additive, decimals, numeric_suffix),
        ") ",
        service.format_colored_multiplier(multiplier),
        " = ",
        total_text,
      }
    end

    if has_additive then
      return {
        "",
        base_text,
        " ",
        service.format_colored_bonus(additive, decimals, numeric_suffix),
        " = ",
        total_text,
      }
    end

    return {
      "",
      base_text,
      " ",
      service.format_colored_multiplier(multiplier),
      " = ",
      total_text,
    }
  end

  function service.format_estimated_dps_formula(values)
    if not values then
      return "-"
    end

    local expected = values.expected
    if expected.expected_bonus and expected.expected_bonus >= 0.005 then
      return {
        "",
        "(",
        service.format_number(expected.base, 1),
        " ",
        service.format_colored_bonus(expected.expected_bonus, 1),
        ") x ",
        service.format_number(values.speed, 2),
        "/s = ",
        service.format_number(values.total, 1),
        "/s",
      }
    end

    return service.format_number(expected.total, 1)
      .. " x "
      .. service.format_number(values.speed, 2)
      .. "/s = "
      .. service.format_number(values.total, 1)
      .. "/s"
  end

  function service.with_info_marker(caption, tooltip)
    if tooltip then
      return { "", caption, " [img=info]" }
    end

    return caption
  end

  function service.with_quality_marker(caption, tooltip)
    if tooltip then
      return { "", caption, " [img=quality_info]" }
    end

    return caption
  end

  return service
end

return stats_formatter
