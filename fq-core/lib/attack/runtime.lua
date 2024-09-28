local atk_util = require("__fq-core__/internal/attack/util")
local text = require("__fq-core__/lib/text")
local vec2 = require("__fq-core__/lib/vec2")

--[[ How to integrate the attack system into your mod:

    1. Call `.init{namespace = "..."}` once at the beginning of `data.lua` and `control.lua`
    2. Forward events received in `control.lua` to event handlers exported by this module (any function that starts with `on_`)
]]--

local exports = {}

---@type {[string]: AttackImpl}
local attack_impl = {}

---@param atk Attack
---@param args AttackArgs
local function use_attack(atk, args)
    local impl = attack_impl[atk.atype]
    if impl == nil then
        text.logof("Missing attack implementation for ",atk.atype)
    else
        impl(atk, args)
    end
end
exports.use_attack = use_attack

--#region Builtin attack implementations

--#region Primary/leaf attacks

---@class AtkProjectile: Attack
---@field atype "atk-projectile"
---@field name string Name of the projectile prototype to spawn
---@field range number Range of the projectile

---@param atk AtkProjectile
---@param args AttackArgs
attack_impl["atk-projectile"] = function(atk, args)

    -- This check is needed because the attack 
    -- could be fired after source/target already died.
    -- (e.g. due to attack firing on a timer)
    
    local src = args.src
    if src and not src.valid then src = nil end

    local tgt = args.tgt
    if tgt and not tgt.valid then tgt = nil end

    local projectile = args.surface.create_entity{
        name = atk.name,
        position = {args.ax, args.ay},
        force = args.force,
        source = src or {args.sx, args.sy},
        target = tgt or {args.tx, args.ty},

        -- projectile-specific args
        speed = vec2.norm(args.avx, args.avy),
        max_range = atk.range
    }
    if projectile then
        projectile.orientation = vec2.rotvec_to_orientation(args.avx, args.avy)
        local entities = args.scope.entities
        entities[#entities+1] = projectile
    end
end

---@class AtkBeam: Attack
---@field atype "atk-beam"
---@field name string Name of the beam prototype to spawn.
---@field range number? Maximum length of the beam [tiles].
---@field duration number Maximum duration of the beam [ticks].
---@field follow_source boolean
---@field follow_target boolean

---@param atk AtkBeam
---@param args AttackArgs
attack_impl["atk-beam"] = function(atk, args)

    local beam_src = (atk.follow_source and args.src) or {args.sx, args.sy}
    local beam_tgt = (atk.follow_target and args.tgt) or {args.tx, args.ty}

    if beam_src.valid == false then return end
    if beam_tgt.valid == false then return end

    -- Trying to attach a beam to an entity without health throws an error
    if beam_tgt.valid == true and beam_tgt.health == nil then
        return
    end

    local beam = args.surface.create_entity{
        name = atk.name,
        position = {args.ax, args.ay},
        force = args.force,
        source = beam_src,
        target = beam_tgt,

        -- beam-specific args
        max_length = atk.range,
        duration = atk.duration
    }
    if beam then
        local entities = args.scope.entities
        entities[#entities+1] = beam
    end
end

--#endregion

--#region Composites etc.

---@class AtkComposite
---@field atype "atk-composite"
---@field children Attack[]

---@param atk AtkComposite
---@param args AttackArgs
attack_impl["atk-composite"] = function(atk, args)
    for _, next in ipairs(atk.children) do
        use_attack(next, args)
    end
end

---@class AtkRandom: Attack
---@field atype "atk-random"
---@field children Attack[]

---@param atk AtkRandom
---@param args AttackArgs
attack_impl["atk-random"] = function(atk, args)
    use_attack(atk.children[math.random(1, #atk.children)], args)
end

--#endregion

--#region Premodifiers

---@class PreRepeats: UnaryModifier
---@field atype "pre-repeats"
---@field min_count integer
---@field max_count integer

---@param atk PreRepeats
---@param args AttackArgs
attack_impl["pre-repeats"] = function(atk, args)
    for _=1,math.random(atk.min_count, atk.max_count) do
        use_attack(atk.next, args)
    end
end

---@class PreAddVelocity: UnaryModifier
---@field atype "pre-add-velocity"
---@field amount number
---@field randomness number

---@param atk PreAddVelocity
---@param args AttackArgs
attack_impl["pre-add-velocity"] = function(atk, args)
    local old_avx, old_avy = args.avx, args.avy
    local davx, davy = vec2.mul(args.arx, args.ary, atk.amount, atk.amount)
    davx, davy = vec2.randomize(davx, davy, atk.randomness)
    args.avx, args.avy = vec2.add(
        old_avx, old_avy,
        davx, davy
    )
    use_attack(atk.next, args)
    args.avx, args.avy = old_avx, old_avy
end

---@class PreRotate: UnaryModifier
---@field atype "pre-rotate"
---@field rx number
---@field ry number
---@field pure boolean

---@param atk PreRotate
---@param args AttackArgs
attack_impl["pre-rotate"] = function(atk, args)
    local rx, ry = atk.rx, atk.ry
    args.arx, args.ary = vec2.cmul(args.arx, args.ary, rx, ry)
    args.avx, args.avy = vec2.cmul(args.avx, args.avy, rx, ry)
    use_attack(atk.next, args)
    if atk.pure then
        args.arx, args.ary = vec2.cmul(args.arx, args.ary, rx, -ry)
        args.avx, args.avy = vec2.cmul(args.avx, args.avy, rx, -ry)
    end
end

---@class PrePattern: UnaryModifier
---@field atype "pre-pattern"
---@field positions number[][]
---@field velocities number[][]

---@param atk PrePattern
---@param args AttackArgs
attack_impl["pre-pattern"] = function(atk, args)

    local positions = atk.positions
    local velocities = atk.velocities

    local old_arx = args.arx
    local old_ary = args.ary
    local old_avx = args.avx
    local old_avy = args.avy
    local old_ax = args.ax
    local old_ay = args.ay


    for i=1,math.max(#positions, #velocities) do
        local dpos = positions[i] or positions[1] or {0,0}
        local dvel = velocities[i] or velocities[1] or {0,0}
        dpos = table.pack(vec2.cmul(args.arx, args.ary, dpos[1], dpos[2]))
        dvel = table.pack(vec2.cmul(args.arx, args.ary, dvel[1], dvel[2]))
        --local darx, dary = vec2.normalize_or(dvel[1], dvel[2], 1, 0)

        args.ax, args.ay = vec2.add(old_ax, old_ay, dpos[1], dpos[2])
        args.avx, args.avy = vec2.add(old_avx, old_avy, dvel[1]/60, dvel[2]/60)
        --args.arx, args.ary = vec2.cmul(old_arx, old_ary, darx, dary)

        use_attack(atk.next, args)
    end

    args.arx = old_arx
    args.ary = old_ary
    args.avx = old_avx
    args.avy = old_avy
    args.ax = old_ax
    args.ay = old_ay
end

---@param atk UnaryModifier
---@param args AttackArgs
attack_impl["pre-random-rotation"] = function(atk, args)
    local old_arx = args.arx
    local old_ary = args.ary

    local drx, dry = vec2.polar(2*math.pi*math.random(), 1)
    args.arx, args.ary = vec2.cmul(drx, dry, old_arx, old_ary)

    use_attack(atk.next, args)

    args.arx = old_arx
    args.ary = old_ary
end


---@class PreScope: UnaryModifier
---@field atype "pre-scope"
---@field name string

---@param atk PreScope
---@param args AttackArgs
attack_impl["pre-scope"] = function(atk, args)

    local old_scope = args.scope

    ---@type AttackScope
    local new_scope = {
        name = atk.name,
        parent = old_scope,
        children = {},
        entities = {}
    }
    --[[
        Any sibling scope with the same name will get shadowed.
        IMHO this is the most sane behavior in case of scope collisions.
    ]]--
    old_scope.children[new_scope.name] = new_scope
    
    args.scope = new_scope
    use_attack(atk.next, args)
    args.scope = old_scope
end

---@class StandaloneTimer
---@field period integer    Number of ticks between timer firing.
---@field limit integer     How many times the timer can fire.
---@field cycle integer     1 for first firing, `limit` for last firing. Increments after firing.
---@field next_tick integer Next tick when this timer will fire.
---@field moving boolean    Does this timer move or stay in place?
---@field attack Attack     Attack fired by the timer.
---@field args AttackArgs   Args passed to `attack`. The timer injects additional field named `timer` into `args`.

local function update_standalone_timers()

    ---@type StandaloneTimer[]
    local timers = global.standalone_timers
    local t = game.tick

    local n_remaining = 0
    for _, timer in ipairs(timers) do
        if timer.next_tick <= t then
            use_attack(timer.attack, timer.args)

            timer.cycle = timer.cycle+1
            if timer.cycle > timer.limit then
                goto continue    
            end
            
            local args = timer.args
            local period = timer.period
            timer.next_tick = timer.next_tick + period
            if timer.moving then
                args.ax = args.ax + args.avx * period
                args.ay = args.ay + args.avy * period
            end
        end
        
        n_remaining = n_remaining+1
        timers[n_remaining] = timer

        ::continue::
    end
    for i=#timers,n_remaining+1,-1 do
        timers[i] = nil
    end
end

---@class PreStandaloneTimer: UnaryModifier
---@field atype "pre-standalone-timer"
---@field period integer            Number of ticks between timer firing.
---@field limit integer             How many times the timer can fire.
---@field initial_delay integer     Initial delay before first firing.
---@field moving boolean            Does this timer move or stay in place?

---@param atk PreStandaloneTimer
---@param args AttackArgs
attack_impl["pre-standalone-timer"] = function(atk, args)

    args = atk_util.copy_args(args)

    if atk.moving then
        args.ax = args.ax + args.avx * atk.initial_delay
        args.ay = args.ay + args.avy * atk.initial_delay
    end

    ---@type StandaloneTimer
    local timer = {
        period = atk.period,
        limit = atk.limit,
        cycle = 1,
        next_tick = game.tick + atk.initial_delay,
        moving = atk.moving,
        attack = atk.next,
        args = args
    }
    timer.args.timer = timer

    table.insert(global.standalone_timers, timer)
end

--#endregion

--#region Postmodifiers

---@class PostLogEntityCount
---@field scope string Path to the used scope

---@param atk PostLogEntityCount
---@param args AttackArgs
attack_impl["post-log-entity-count"] = function(atk, args)
    local scope = atk_util.get_scope_by_path(args.scope, atk.scope)
    local n = 0
    if scope ~= nil then n = #scope.entities end
    text.logof("Found ",n," entities")
end

--#endregion

--#endregion

---@type string
local attack_effect_id_prefix = nil

---Initializes the attack system.
---
---Must be called once at the beginning of:
--- - `data.lua` before any attacks are created.
--- - `control.lua` before any attacks are used.
--- 
---The `namespace` argument should be different for each mod using the attack system.
---Namespace collisions are likely to cause bad things to happen.
---Consider using the ID of your mod as the namespace.
--- 
---@param args table
---@param args.namespace string Attack namespace used by your mod.
---@param args.extensions {[string]: AttackImpl}[]? Lua modules containing attack extensions you want to use. 
exports.init = function(args)
    local namespace = args.namespace or error("Missing required argument: 'namespace'")
    local extensions = args.extensions or {}

    atk_util.set_namespace(namespace)

    attack_effect_id_prefix = atk_util.get_effect_id_prefix()

    for _, extension in ipairs(extensions) do
        for atype, impl in pairs(extension) do
            attack_impl[atype] = impl
        end
    end
end

--#region Event handlers

function exports.on_init()
    global.standalone_timers = {}
end

function exports.on_tick()
    update_standalone_timers()
end

local attack_registry
local function get_attack_registry()
    if not attack_registry then 
        attack_registry = global.attack_registry 
    end
    if not attack_registry then 
        attack_registry = atk_util.CONTROL_get_attack_registry()
        global.attack_registry = attack_registry
    end
    return attack_registry
end

exports.on_configuration_changed = function()
    attack_registry = nil
    global.attack_registry = nil
end

exports.on_script_trigger_effect = function(event)
    if not text.starts_with(event.effect_id, attack_effect_id_prefix) then return end

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
        tgt = event.target_entity,
        scope = {
            name = "/",
            children = {},
            entities = {}
        }
    }

    use_attack(
        get_attack_registry()[event.effect_id],
        args
    )
end

--#endregion

return exports