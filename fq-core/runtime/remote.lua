local motion = require("runtime.motion")

local interface = {}

---Increases the velocity of the chosen entity.
---
---**Note:** this is pretty expensive for entities without a `unit_number`.
---Avoid using this function for many such entities.
---
---**Example usage:**
---```lua
---remote.call("fq-core", "add-velocity", {to=some_entity, velocity={0.2, 0.3}})
---```
---@param args {to: LuaEntity, velocity: Vector}
---@param args.to       #The affected entity
---@param args.velocity #Added velocity [tiles/tick]
interface["add-velocity"] = function(args)
    local entity = args.to or error("Missing argument: entity")
    local velocity = args.velocity or error("Missing argument: velocity")
    if not entity.valid then return end

    local mc = motion.require_motion_component(entity)
    mc.vx = mc.vx + (velocity.x or velocity[1])
    mc.vy = mc.vy + (velocity.y or velocity[2])
end

---Applies recoil to the chosen entity, pushing it away from a point on the map or from another entity.
---
---**Note:** this is pretty expensive for entities without a `unit_number`.
---Avoid using this function for many such entities.
---
---**Example usage:**
---```lua
---remote.call("fq-core", "apply-recoil", {to=some_entity, away_from=other_entity, speed=0.2})
---remote.call("fq-core", "apply-recoil", {to=some_entity, away_from={x=0, y=0}, speed=0.2})
---```
---@param args {to: LuaEntity, away_from: LuaEntity|MapPosition, speed: number, randomness: number?}
---@param args.to           #The affected entity
---@param args.away_from    #The affected entity will be pushed away from this entity/position
---@param args.speed        #How much speed is added to the affected entity [tiles/tick]
interface["apply-recoil"] = function(args)
    local entity = args.to or error("Missing argument: entity")
    local away_from = args.away_from or error("Missing argument: away_from")
    local speed = args.speed or error("Missing argument: speed")
    local randomness = args.randomness or 0

    motion.apply_recoil(entity, away_from, speed, randomness)
end

remote.add_interface("fq-core", interface)