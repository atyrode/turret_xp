local support = require("support")

local assert_eq = support.assert_eq
local create_turret = support.create_turret
local call = support.call

local tests = {}
function tests.run_compat_samples_test(surface)
  local turret = create_turret(surface, { -8, 0 }, 0)
  local samples = call("compat_samples", turret)
  assert_eq(samples.nil_read_fallback, "fallback", "compat safe_read fallback changed")
  assert_eq(samples.entity_quality, "normal", "compat quality read changed")
  assert_eq(samples.inventory_valid, true, "compat inventory read did not return the turret ammo inventory")
  assert_eq(samples.platform_inventory_present, false, "non-platform turret unexpectedly exposed a platform inventory")
  assert_eq(samples.base_prototype_exists, true, "compat prototype existence check missed the base turret")
  assert_eq(samples.missing_prototype_exists, false, "compat prototype existence check accepted a missing prototype")
  assert_eq(samples.diagnostics_enabled, true, "headless tests should run with compatibility diagnostics enabled")
end

return tests
