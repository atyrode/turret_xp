local domain = require("scripts.domain")

local label_colors = {}

label_colors.presets = domain.label_color_presets

function label_colors.matches(color, preset_color)
  color = color or {}
  preset_color = preset_color or {}
  return math.abs((color[1] or 0) - (preset_color[1] or 0)) < 0.01
    and math.abs((color[2] or 0) - (preset_color[2] or 0)) < 0.01
    and math.abs((color[3] or 0) - (preset_color[3] or 0)) < 0.01
end

function label_colors.preset_by_id(id)
  for _, preset in ipairs(label_colors.presets) do
    if preset.id == id then
      return preset
    end
  end

  return nil
end

function label_colors.preset_from_color(color)
  for _, preset in ipairs(label_colors.presets) do
    if label_colors.matches(color, preset.color) then
      return preset
    end
  end

  return nil
end

return label_colors
