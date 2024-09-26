require("globals")

local atk = require("lib.attack.attack")
local pre = require("lib.attack.premodifier")
local pattern = require("lib.attack.pattern")
local atk_runtime = require("lib.attack.runtime")

if not FQC_TESTING_MODE then return end

atk_runtime.init{namespace = "fqc"}


local ammo = util.copy(data.raw.ammo["shotgun-shell"])
ammo.name = "custom-attack-shotgun-shell"
ammo.ammo_type.action = atk.to_trigger(atk.chain(
    pre.pattern          {positions={{1,0}}},
    pre.add_velocity     {amount=30, randomness=0.2},
    pre.random_rotation  (),
    atk.random {
        atk.chain(
            pre.pattern {velocities = pattern.heart(64):scale(5)},
            atk.spawn_projectile {name="shotgun-pellet", range=40}
        ),
        atk.chain(
            pre.pattern {velocities = pattern.star{ntips=5}:subdivide_loop(5):scale(5)},
            atk.spawn_projectile {name="shotgun-pellet", range=40}
        ),
        atk.chain(
            pre.pattern {velocities = pattern.regular(64):scale(5)},
            atk.spawn_projectile {name="shotgun-pellet", range=40}
        ),
        atk.chain(
            pre.pattern {velocities = pattern.regular(3):subdivide_loop(19):scale(5)},
            atk.spawn_projectile {name="shotgun-pellet", range=40}
        ),
        atk.chain(
            pre.pattern {velocities = pattern.regular(4):subdivide_loop(19):scale(5)},
            atk.spawn_projectile {name="shotgun-pellet", range=40}
        )
    }
    
))
data:extend({ammo})



