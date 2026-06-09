local turret = data.raw["ammo-turret"] and data.raw["ammo-turret"]["gun-turret"]
if turret and turret.attack_parameters then
  turret.attack_parameters.range = 25
end
