local suite = require("suite")

script.on_init(function()
  storage.turret_xp_headless_tests = {
    started_tick = game.tick,
    passed = false
  }
  suite.run_immediate_tests()
  log(suite.test_prefix .. "immediate assertions passed")
end)

script.on_event(defines.events.on_tick, function(event)
  local state = storage.turret_xp_headless_tests
  if not state or state.passed then
    return
  end

  if event.tick >= suite.pass_tick then
    suite.check_deferred_tests()
    state.passed = true
    log(suite.test_prefix .. "PASS")
  end
end)
