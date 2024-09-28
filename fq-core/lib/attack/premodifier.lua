local vec2 = require("__fq-core__/lib/vec2")
local text = require("__fq-core__/lib/text")
local atk_util = require("__fq-core__/internal/attack/util")

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

---Rotates the next attack's velocity and rotation vectors by a given angle.
---@param args {angle: number, pure: boolean?, next: Attack?}
---@param args.next Attack? Next attack used by this premodifier.
---@param args.angle number Rotation angle (clockwise) [rad]
---@param args.pure boolean?
---@return PreRotate
premodifier.rotate = function(args)
    local pure = args.pure
    if pure == nil then pure = true end
    return {
        atype = "pre-rotate",
        next = args.next,
        pure = pure,
        rx = math.cos(args.angle),
        ry = math.sin(args.angle)
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
premodifier.random_rotation = function(args) return {
    atype = "pre-random-rotation",
    next = args.next
} end

---Creates a scope, which captures any entities created by the modified attack.
---
---This scope can then be used to pass entities to postmodifiers.
---@param args table
---@param args.next Atack? Next attack used by this premodifier.
---@param args.name string Name of the created scope.
---@return PreScope
function premodifier.scope(args)
    local name = args.name or error("Missing required parameter: name")
    local ok, errmsg = atk_util.validate_scope_name(name)
    if not ok then
        error("Invalid scope name: "..errmsg)
    end
    return {
        atype = "pre-scope",
        name = name,
        next = nil
    } 
end

---Creates a standalone timer, which fires the next attack periodically.
---
---@param args {delay: integer?, period: integer?, limit: integer?, moving: boolean?, next: Attack?}
---@param args.delay  integer   Number of ticks before the first firing. Defaults to `period`.
---@param args.period integer   Number of ticks between each next firing.
---@param args.limit  integer   Maximum number of times the timer can fire. Defaults to `1` if period is not set.
---@param args.moving boolean   Does this timer move or stay in place?
---@return PreStandaloneTimer
function premodifier.timer(args)

    local period = args.period
    local limit = args.limit
    local delay = args.delay

    if not period and not delay then
        error("Missing required argument: 'period' or 'delay'")
    end

    if period and not limit then
        error("Periodic timer must have a limit.")
    end
    if limit and not period then
        error("Timer with a limit must have a period")
    end

    if period and period < 1 then
        error("Timer period can not be smaller than 1 tick")
    end
    if delay and delay < 0 then
        error("Timer delay can not be negative")
    end
    if limit and limit < 1 then
        error("Timer limit can not be smaller than 1")
    end

    if delay and not period and not limit then
        limit = 1
        period = 1
    end
    if period and not delay then
        delay = period
    end

    return {
        atype = "pre-standalone-timer",
        period = period,
        limit = limit,
        initial_delay = delay,
        moving = args.moving or false,
        next = args.next
    }
end

---Runs the next attack once for each consecutive pair of valid entities in the chosen scope.
---
---The first entity in the pair becomes the source of the attack.
---
---The second entity in the pair becomes the target of the attack.
---@param args {scope: string, loop: boolean?, next: Attack?}
---@return PreSlide
function premodifier.slide(args)
    local scope = args.scope or error("Missing required argument: 'scope'")
    local loop = args.loop or false

    local ok, errmsg = atk_util.validate_scope_name(scope)
    if not ok then
        error("Invalid scope name: "..errmsg)
    end

    return {
        atype = "pre-slide",
        scope = scope,
        loop = loop,
        next = args.next
    }
end

---Runs the next attack once for each entity in the selected scope.
---@param args {scope: string, next: Attack?}
---@return PreEach
function premodifier.each(args)
    local scope = args.scope or error("Missing required argument: 'scope'")
    local ok, errmsg = atk_util.validate_scope_name(scope)
    if not ok then
        error("Invalid scope name: "..errmsg)
    end

    return {
        atype = "pre-each",
        scope = scope,
        next = args.next
    }
end

---@param args {next: Attack?}
---@return PreFetchSourcePosition
function premodifier.fetch_source_position(args) return {
    atype = "pre-fetch-source-position",
    next = args.next
} end

---@param args {next: Attack?}
---@return PreFetchTargetPosition
function premodifier.fetch_target_position(args) return {
    atype = "pre-fetch-target-position",
    next = args.next
} end

---Runs the next attack at the cached position of source entity.
---@param args {next: Attack?}
---@return PreAtPosition
function premodifier.at_source_position(args) return {
    atype = "pre-at-position",
    entity = "source",
    next = args.next
} end

---Runs the next attack at the cached position of target entity.
---@param args {next: Attack?}
---@return PreAtPosition
function premodifier.at_target_position(args) return {
    atype = "pre-at-position",
    entity = "target",
    next = args.next
} end

---Selects a new target for the next attack.
---
---This is SLOW. Especially with a large `range`. Use sparingly.
---
---@param args {range: number, from: AttackReferencePoint, priority: TargetPriorityFunc, next: Attack?}
---@param args.from AttackReferencePoint Target will be looked for in a circle centered at this point.
---@param args.range number Radius of the target-searching circle.
---@param args.priority TargetPriorityFunc Decides which target is chosen if there are multiple potential targets.
---@param args.next Attack? The next attack to use.
---@return PreFindTarget
function premodifier.find_target(args) return {
    atype = "pre-find-target",
    range = args.range,
    from = args.from,
    priority = args.priority,
    next = args.next
} end

return premodifier