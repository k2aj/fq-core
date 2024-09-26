local vec2 = require("__fq-core__/lib/vec2")
local text = require("__fq-core__/lib/text")

local premodifier = {}

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
    }
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
    }
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
    }
end

---@return UnaryModifier
premodifier.random_rotation = function() return {
    atype = "pre-random-rotation",
    next = nil
} end

return premodifier