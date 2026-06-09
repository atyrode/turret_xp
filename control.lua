local M = {}

require("scripts.control.config")(M)
require("scripts.control.storage")(M)
require("scripts.control.progression")(M)
require("scripts.control.profiles")(M)
require("scripts.control.turret_bodies")(M)
require("scripts.control.gui_base")(M)
require("scripts.control.feeder")(M)
require("scripts.control.stats")(M)
require("scripts.control.gui_panels")(M)
require("scripts.control.core_slot")(M)
require("scripts.control.actions")(M)
require("scripts.control.combat_effects")(M)
require("scripts.control.events")(M)
require("scripts.control.remote_test")(M)
require("scripts.control.commands")(M)

return M
