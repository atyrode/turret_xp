local IFACE = "turret_xp_screenshot"
local TEST_PREFIX = "[turret_xp_gui_screenshotter] "
local OUTPUT_DIR = "turret-xp-gui-screenshots"

local scenes = {
  {
    name = "01_anchored_turret_panel",
    level = 54,
    custom_name = "Aegis North",
    position = { x = 0, y = 0 },
  },
}

local steps = {
  function(state, scene)
    local result = remote.call(IFACE, "open_panel", 1, scene)
    state.metadata.scenes[scene.name] = result or { valid = false }
    if not result or not result.panel or not result.panel.valid then
      error(TEST_PREFIX .. "failed to open " .. scene.name, 2)
    end
  end,
  function(_, scene)
    game.take_screenshot({
      path = OUTPUT_DIR .. "/" .. scene.name .. ".png",
      show_gui = true,
      zoom = 1,
    })
  end,
  function(state, scene)
    local panel = remote.call(IFACE, "panel_metadata", 1)
    state.metadata.scenes[scene.name].panel_after_screenshot = panel
  end,
}

local function write_metadata(state)
  helpers.write_file(OUTPUT_DIR .. "/metadata.json", helpers.table_to_json(state.metadata))
end

script.on_init(function()
  storage.turret_xp_gui_screenshotter = {
    scene = 1,
    step = 1,
    metadata = {
      scenes = {},
    },
  }
end)

script.on_nth_tick(15, function()
  local state = storage.turret_xp_gui_screenshotter
  if not state or state.done then
    return
  end

  if not remote.interfaces[IFACE] then
    error(TEST_PREFIX .. "missing " .. IFACE .. " interface", 2)
  end

  local scene = scenes[state.scene]
  if not scene then
    write_metadata(state)
    state.done = true
    log(TEST_PREFIX .. "DONE")
    return
  end

  steps[state.step](state, scene)

  state.step = state.step + 1
  if state.step > #steps then
    state.step = 1
    state.scene = state.scene + 1
  end
end)
