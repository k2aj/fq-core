require("globals")

local atk = require("lib.attack.attack")
local pre = require("lib.attack.premodifier")
local post = require("lib.attack.postmodifier")
local pattern = require("lib.attack.pattern")
local atk_runtime = require("lib.attack.runtime")

if not FQC_TESTING_MODE then return end

atk_runtime.init{namespace = "fqc"}


local ammo = util.copy(data.raw.ammo["shotgun-shell"])
ammo.name = "custom-attack-shotgun-shell"
ammo.ammo_type.action = atk.to_trigger(atk.chain{

    pre.add_velocity{amount=30},
    pre.timer{period=1, moving = true, limit=30},
    pre.add_velocity{amount=-30},
    pre.pattern{velocities={{0,-5},{0,5}}, positions={{0,0.2},{0,-0.2}}},
    atk.projectile {name="shotgun-pellet", range=6},

    pre.add_velocity{amount=30},
    pre.timer{delay = 30, moving = true},
    pre.add_velocity{amount=-30},
    atk.chain{

        pre.timer{period = 5, limit = 80},
        pre.rotate{angle = 2*math.pi/10.5, pure=false},

        pre.pattern          {positions={{1,0}}},
        pre.add_velocity     {amount=10},
        --pre.add_velocity     {amount=30, randomness=0.2},
        pre.random_rotation  {},

        atk.random {
            atk.chain{
                pre.pattern {velocities = pattern.heart(64):scale(2)},
                atk.projectile {name="shotgun-pellet", range=40}
            },
            atk.chain{
                pre.pattern {velocities = pattern.star{ntips=5}:subdivide_loop(5):scale(2)},
                atk.projectile {name="shotgun-pellet", range=40}
            },
            atk.chain{
                pre.pattern {velocities = pattern.regular(64):scale(2)},
                atk.projectile {name="shotgun-pellet", range=40}
            },
            atk.chain{
                pre.pattern {velocities = pattern.regular(3):subdivide_loop(19):scale(2)},
                atk.projectile {name="shotgun-pellet", range=40}
            },
            atk.chain{
                pre.pattern {velocities = pattern.regular(4):subdivide_loop(19):scale(2)},
                atk.projectile {name="shotgun-pellet", range=40}
            }
        },

        
        pre.timer{delay=90, period=60, limit=7},
        pre.scope{name = "ring"},
        atk.chain{
            
            pre.rotate{angle=2*math.pi/64/2, pure=false},
            pre.timer{period=2,limit=6},
            pre.pattern{positions={{1,0}}, velocities = pattern.regular(64):scale(20)},
            atk.projectile {name="shotgun-pellet", range=40},

            pre.timer{delay=105},
            pre.fetch_source_position{},
            pre.at_source_position{},
            post.redirect{scope = "."}
        }
    },
})
data:extend({ammo})

local beam_test_ammo = util.copy(data.raw.ammo["shotgun-shell"])
beam_test_ammo.name = "beam-test-ammo"
beam_test_ammo.ammo_type.action = atk.to_trigger(atk.chain{

    pre.scope{name = "bullets"},
    pre.add_velocity{amount = 10},
    pre.pattern{positions = {{1,0}}},
    atk.projectile{name="shotgun-pellet", range=40},

    pre.timer{period = 10, limit = 40},
    pre.each{scope = "bullets"},
    pre.find_target{from="source", priority="random", range=10},
    atk.beam{name="electric-beam", duration=999, range=10, follow="both"},
})
data:extend({beam_test_ammo})