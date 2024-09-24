local motion = require("runtime.motion")

local text = require("lib.text")
local vec2 = require("lib.vec2")
local atk = require("lib.attack.attack")
local pre = require("lib.attack.premodifier")

script.on_init(function()
    motion.on_init()
end)

script.on_event(defines.events.on_tick, function(event)
    motion.on_tick()
end)

local function parametric_curve(t0, t1, n_steps, f)
    local result = {}
    local dt = (t1 - t0) / n_steps
    for i=1,n_steps do
        result[#result+1] = f(t0 + i*dt)
    end
    return result
end

local heart_curve = parametric_curve(0, 2*math.pi, 64, function(t)
    return {
        2*(-math.sin(t)^3 - math.sin(t)^2 + 2*math.sin(t) + 1), 
        2*(2^0.5 * math.cos(t)^3)
    }
end)

local custom_attack = atk.chain(
    pre.pattern          {positions={{1,0}}},
    pre.add_velocity     {amount=30, randomness=0.2},
    pre.random_rotation,
    pre.pattern          {velocities=heart_curve},
    atk.spawn_projectile {name="shotgun-pellet", range=40}
)

script.on_event(defines.events.on_script_trigger_effect, function(event)
    motion.on_script_trigger_effect(event)

    if event.effect_id == "custom-attack" then
        local src = event.source_entity
        local src_pos = event.source_position or src.position
        local tgt_pos = event.target_position or event.target_entity.position
        local dx, dy = vec2.sub(tgt_pos.x, tgt_pos.y, src_pos.x, src_pos.y)
        local arx, ary = vec2.normalize_or(dx,dy, 1,0)

        ---@type AttackArgs
        local args = {
            force = (src and src.force or "neutral"),
            surface = game.get_surface(event.surface_index),
            arx = arx, ary = ary,
            avx = 0, avy = 0,
            ax = src_pos.x, ay = src_pos.y,
            sx = src_pos.x, sy = src_pos.y,
            tx = tgt_pos.x, ty = tgt_pos.y,
            src = src,
            tgt = event.target_entity
        }
        custom_attack.use(custom_attack, args)
    end
end)
