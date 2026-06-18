local support = require("support")

local assert_eq = support.assert_eq
local assert_ge = support.assert_ge
local assert_gt = support.assert_gt
local assert_true = support.assert_true
local call = support.call

local tests = {}

function tests.run_world_runtime_pressure_test(surface)
  local sample = call("runtime_world_pressure_sample", surface, 221, 3)
  assert_true(sample ~= nil, "runtime world pressure sample returned nothing")
  assert_eq(sample.core_count, 221, "runtime pressure sample should match the reported turret count")
  assert_eq(sample.installed_core_count, 221, "runtime pressure sample did not install every test core")
  assert_eq(sample.storage_chip_count_delta, 221, "runtime pressure sample did not add the expected number of core profiles")
  assert_eq(sample.feeder_count_delta, 0, "named-only pressure sample should not create hidden feeders")
  assert_eq(sample.managed_inserter_count_delta, 0, "named-only pressure sample should not manage inserters")
  assert_eq(sample.status_effect_count_delta, 0, "named-only pressure sample should not schedule status effects")
  assert_eq(sample.pending_visual_count_delta, 0, "named-only pressure sample should not queue combat visuals")
  assert_gt(sample.initial_text_property_writes, 0, "runtime pressure sample did not exercise named core text renders")
  assert_gt(sample.initial_sprite_property_writes, 0, "runtime pressure sample did not exercise shield bar sprite renders")
  assert_eq(sample.passive_text_property_writes, 0, "221-core passive refresh should not rewrite unchanged text renders")
  assert_eq(sample.passive_sprite_property_writes, 0, "221-core passive refresh should not rewrite unchanged shield renders")
  assert_eq(sample.direct_refresh_text_property_writes, 0, "221-core direct refresh should not rewrite unchanged text renders")
  assert_eq(sample.direct_refresh_sprite_property_writes, 0, "221-core direct refresh should not rewrite unchanged shield renders")
  assert_ge(sample.repeat_updates, 3, "runtime pressure sample did not repeat enough passive refreshes")
end

return tests
