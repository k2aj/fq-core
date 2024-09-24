local vec2 = require("__fq-core__/lib/vec2")
local text = require("__fq-core__/lib/text")

local premodifier = {}

---@class PreRepeats: UnaryModifier
---@field atype "pre-repeats"
---@field min_count integer
---@field max_count integer
---@field use fun(atk: PreRepeats, args: AttackArgs)

---@param atk PreRepeats
---@param args AttackArgs
local function PreRepeats_impl(atk, args)
    local next = atk.next
    if next == nil then return end

    for _=1,math.random(atk.min_count, atk.max_count) do
        next.use(next, args)
    end
end

---Premodifier which repeats the next attack several times.
---
---You must provide either "count" or "min_count, max_count" in arguments.
---You can't provide both at the same time. 
---
---@param args table
---@param args.next Attack? Next attack used by this premodifier.
---@param args.count integer Number of repetitions.
---@param args.min_count integer Minimum number of repetitions.
---@param args.max_count integer Maximum number of repetitions.
---@return PreRepeats
premodifier.repeats = function(args)
    local next = args.next
    local min_count = args.count or args.min_count
    local max_count = args.max_count or min_count

    if args.count == nil and (args.min_count == nil or args.max_count == nil) then
        error("premodifier.repeats: insufficient arguments. You must provide either \"count\" or both \"min_count\" and \"max_count\"")
    end
    if args.count and (args.min_count or args.max_count) then
        error("premodifier.repeats: too many arguments. You must provide either \"count\" or both \"min_count\" and \"max_count\"")
    end
    if min_count > max_count then
        error("premodifier.repeats: min_times can't be greater than max_times")
    end

    return {
        atype = "pre-repeats",
        next = next,
        min_count = min_count,
        max_count = max_count,
        use = PreRepeats_impl
    }
end

---@class PreAddVelocity: UnaryModifier
---@field atype "pre-add-velocity"
---@field amount number
---@field randomness number
---@field use fun(atk: PreAddVelocity, args: AttackArgs)

---@param atk PreAddVelocity
---@param args AttackArgs
local function PreAddVelocity_impl(atk, args)
    local next = atk.next
    if next == nil then return end

    local old_avx, old_avy = args.avx, args.avy

    local davx, davy = vec2.mul(args.arx, args.ary, atk.amount, atk.amount)
    davx, davy = vec2.randomize(davx, davy, atk.randomness)

    args.avx, args.avy = vec2.add(
        old_avx, old_avy,
        davx, davy
    )
    next.use(next, args)
    args.avx, args.avy = old_avx, old_avy
end

---Premodifier which increases velocity of the next attack.
---
---Randomness parameter controls in which direction the velocity will be added:
--- - Randomness=0: velocity is added along the attack's rotation vector.
--- - Randomness=1: the added velocity vector is completely random, with length ≤ args.amount
--- - Other values give a linear combination of the above two options.
---@param args table
---@param args.next Attack? Next attack used by this premodifier.
---@param args.amount number How much velocity to add [m/s]
---@param args.randomness number? Controls direction of added velocity.
---@return PreAddVelocity
premodifier.add_velocity = function(args)
    local next = args.next
    local amount = args.amount/60 or 0
    local randomness = args.randomness or 0

    return {
        atype = "pre-add-velocity",
        next = next,
        amount = amount,
        randomness = randomness,
        use = PreAddVelocity_impl
    }
end



---@class PrePattern: UnaryModifier
---@field atype "pre-pattern"
---@field positions number[][]
---@field velocities number[][]
---@field use fun(atk: PrePattern, args: AttackArgs)

---@param atk PrePattern
---@param args AttackArgs
local function PrePattern_impl(atk, args)

    --text.logof("BRUH BRUH BRUH BRUH BRUH", serpent.line(atk))

    local next = atk.next
    if next == nil then return end

    local positions = atk.positions
    local velocities = atk.velocities

    text.logof(serpent.line(positions))
    text.logof(serpent.line(velocities))

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

        next.use(next, args)
    end

    args.arx = old_arx
    args.ary = old_ary
    args.avx = old_avx
    args.avy = old_avy
    args.ax = old_ax
    args.ay = old_ay
end

---Premodifier which arranges projectiles into a pattern.
---
---@param args table
---@param args.next Attack? Next attack used by this premodifier.
---@param args.positions number[][]?
---@param args.velocities number[][]?
---@return PrePattern
premodifier.pattern = function(args)
    local positions = args.positions or {}
    local velocities = args.velocities or {}
    local next = args.next
    return {
        atype = "pre-pattern",
        next = next,
        positions = positions,
        velocities = velocities,
        use = PrePattern_impl
    }
end

premodifier.random_rotation = {
    atype = "pre-random-rotation",
    next = nil,
    use = function(atk, args)
        if atk.next == nil then return end

        local old_arx = args.arx
        local old_ary = args.ary

        local drx, dry = vec2.polar(2*math.pi*math.random(), 1)
        args.arx, args.ary = vec2.cmul(drx, dry, old_arx, old_ary)

        atk.next.use(atk.next, args)

        args.arx = old_arx
        args.ary = old_ary
    end
}

return premodifier