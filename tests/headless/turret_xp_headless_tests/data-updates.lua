local turret = data.raw["ammo-turret"] and data.raw["ammo-turret"]["gun-turret"]
if turret and turret.attack_parameters then
  turret.attack_parameters.range = 25
end

data:extend({
  {
    type = "projectile",
    name = "turret-xp-headless-test-bullet",
    flags = { "not-on-map" },
    hidden = true,
    collision_box = { { -0.05, -0.05 }, { 0.05, 0.05 } },
    acceleration = 0,
    action = {
      type = "direct",
      action_delivery = {
        type = "instant",
        target_effects = {
          {
            type = "damage",
            damage = { amount = 5, type = "physical" }
          }
        }
      }
    },
    animation = {
      filename = "__core__/graphics/empty.png",
      width = 1,
      height = 1,
      frame_count = 1
    }
  }
})

local firearm_magazine = data.raw.ammo and data.raw.ammo["firearm-magazine"]
if firearm_magazine then
  firearm_magazine.ammo_type = {
    target_type = "entity",
    action = {
      {
        type = "direct",
        action_delivery = {
          {
            type = "projectile",
            projectile = "turret-xp-headless-test-bullet",
            starting_speed = 1.5,
            range_deviation = 0.15,
            max_range = 30
          }
        }
      }
    }
  }
end
