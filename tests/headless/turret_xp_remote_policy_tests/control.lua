local TEST_PREFIX = "[turret_xp_remote_policy_tests] "

script.on_init(function()
  if remote.interfaces.turret_xp_test ~= nil then
    error(TEST_PREFIX .. "turret_xp_test remote interface is registered without the headless companion suite", 2)
  end

  log(TEST_PREFIX .. "PASS")
end)
