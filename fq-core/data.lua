local atk = require("lib.attack.attack")
local pre = require("lib.attack.premodifier")
local pattern = require("lib.attack.pattern")


local heart_curve = pattern.parametric_curve{
    domain = {0, 2*math.pi},
    nsteps = 64, 
    f = function(t) return {
        2*(-math.sin(t)^3 - math.sin(t)^2 + 2*math.sin(t) + 1), 
        2*(2^0.5 * math.cos(t)^3)
    } end
}

local ammo = util.copy(data.raw.ammo["shotgun-shell"])
ammo.name = "custom-attack-shotgun-shell"
ammo.ammo_type.action = atk.to_trigger(atk.chain(
    pre.pattern          {positions={{1,0}}},
    pre.add_velocity     {amount=30, randomness=0.2},
    pre.random_rotation  (),
    pre.pattern          {velocities = heart_curve},--pattern.circle{radius=2, count=16}},
    atk.spawn_projectile {name="shotgun-pellet", range=40}
))
data:extend({ammo})




