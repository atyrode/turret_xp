local M = {}

require("scripts.control.config")(M)
require("scripts.control.storage")(M)
require("scripts.control.selection_proxy")(M)

local compat = require("scripts.control.compat")
M.compat = compat.new({
  diagnostics_enabled = function()
    return M.compat_diagnostics_enabled()
  end,
})
M.safe_read = function(object, property, fallback, context)
  return M.compat.safe_read(object, property, fallback, context)
end

require("scripts.control.progression")(M)
require("scripts.control.profiles")(M)
require("scripts.control.turret_bodies")(M)
require("scripts.control.gui_base")(M)
require("scripts.control.feeder")(M)
require("scripts.control.stats")(M)
require("scripts.control.selection_overlay")(M)
require("scripts.control.gui_panels")(M)
require("scripts.control.core_slot")(M)
require("scripts.control.actions")(M)
require("scripts.control.combat_effects")(M)
require("scripts.control.events")(M)
if script.active_mods["turret_xp_headless_tests"] then
  require("scripts.control.remote_test")(M)
end
require("scripts.control.commands")(M)

return M
