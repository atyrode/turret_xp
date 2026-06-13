std = "lua52"
codes = true
max_line_length = false
unused_args = false

globals = {
  -- Factorio objects that mods are expected to mutate.
  "data",
  "settings",
  "storage",
}

read_globals = {
  -- Factorio runtime and data-stage globals that are read by this mod.
  "commands",
  "defines",
  "game",
  "helpers",
  "kg",
  "log",
  "mods",
  "prototypes",
  "remote",
  "rendering",
  "script",
  "serpent",
  "table.deepcopy",
  "table_size",
  "util",
}

legacy_control_module = {
  -- Current runtime modules in this list intentionally share an `_ENV` table.
  -- Until more of them migrate to explicit returned-table modules, global-family
  -- warnings are structural noise here rather than useful signal.
  ignore = { "111", "112", "113", "122", "211/_ENV" },
}

files["scripts/control/combat_effects.lua"] = legacy_control_module
files["scripts/control/config.lua"] = legacy_control_module
files["scripts/control/core_slot.lua"] = legacy_control_module
files["scripts/control/events.lua"] = legacy_control_module
files["scripts/control/gui_base.lua"] = legacy_control_module
files["scripts/control/gui_panels.lua"] = legacy_control_module
files["scripts/control/profiles.lua"] = legacy_control_module
files["scripts/control/progression.lua"] = legacy_control_module
files["scripts/control/remote_test.lua"] = legacy_control_module
files["scripts/control/storage.lua"] = legacy_control_module
files["scripts/control/turret_bodies.lua"] = legacy_control_module
