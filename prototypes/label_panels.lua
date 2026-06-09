return function(names)
  local label_panel_base = data.raw["display-panel"] and data.raw["display-panel"]["display-panel"]
  if not label_panel_base then
    return
  end

  local label_panels = {}

  local function add_label_panel(id, color)
    local panel = table.deepcopy(label_panel_base)
    panel.name = names.label_panel_prefix .. id
    panel.localised_name = { "entity-name." .. panel.name }
    panel.localised_description = { "entity-description.turret-xp-label-panel" }
    panel.hidden = true
    panel.hidden_in_factoriopedia = true
    panel.flags = { "placeable-off-grid", "not-blueprintable", "not-deconstructable", "not-on-map" }
    panel.selectable_in_game = false
    panel.minable = nil
    panel.collision_box = { { -0.05, -0.05 }, { 0.05, 0.05 } }
    panel.selection_box = { { -0.05, -0.05 }, { 0.05, 0.05 } }
    panel.collision_mask = { layers = {}, not_colliding_with_itself = true }
    panel.circuit_connector = nil
    panel.circuit_wire_max_distance = 0
    panel.draw_copper_wires = false
    panel.draw_circuit_wires = false
    panel.sprites = util.empty_sprite()
    panel.icon = "__core__/graphics/empty.png"
    panel.icon_size = 1
    panel.icons = nil
    panel.max_text_width = 360
    panel.text_shift = util.by_pixel(0, -62)
    panel.text_color = color
    panel.background_color = { 0, 0, 0, 0.38 }
    label_panels[#label_panels + 1] = panel
  end

  for _, preset in ipairs(names.label_presets) do
    add_label_panel(preset.id, preset.color)
  end

  for r = 0, 5 do
    for g = 0, 5 do
      for b = 0, 5 do
        add_label_panel(
          "custom-" .. tostring(r) .. "-" .. tostring(g) .. "-" .. tostring(b),
          { r / 5, g / 5, b / 5, 1 }
        )
      end
    end
  end

  data:extend(label_panels)
end
