local exports = {}

local entity_dict = require("lib.entity_dict")
local text = require("lib.text")

---@class MotionComponent
---@field vx number
---@field vy number

local function require_motion_component(entity)
    local motion = entity_dict.get(global.motion_components, entity)
    if motion == nil then
        motion = {
            vx = 0,
            vy = 0
        }
        entity_dict.put(global.motion_components, entity, motion)
    end
    return motion
end
exports.require_motion_component = require_motion_component

---@param entity LuaEntity?
---@param away_from LuaEntity|MapPosition
---@param speed number
---@param randomness number
local function apply_recoil(entity, away_from, speed, randomness)

    if entity == nil then return end
    if not entity.valid then return end
    if away_from.valid == false then return end

    local pos = entity.position
    if away_from.valid ~= nil then away_from = away_from.position end

    local dirX = pos.x - (away_from.x or away_from[1])
    local dirY = pos.y - (away_from.y or away_from[2])

    -- normalize [dirX, dirY]
    local norm2 = dirX*dirX + dirY*dirY
    if norm2 > 0.000001 then
        local norm = norm2 ^ 0.5
        dirX = dirX/norm
        dirY = dirY/norm
    else
        dirX = 0
        dirY = 0
    end

    if randomness ~= 0 then
        local arg = math.random() * 2 * math.pi
        local rnd_len = math.random()
        dirX = dirX*(1-randomness) + math.cos(arg)*rnd_len*randomness
        dirY = dirY*(1-randomness) + math.sin(arg)*rnd_len*randomness
    end

    local component = require_motion_component(entity)
    component.vx = component.vx + dirX * speed
    component.vy = component.vy + dirY * speed
end
exports.apply_recoil = apply_recoil

exports.on_init = function()
    global.motion_components = entity_dict.new()
end

local MAX_MOTION_STEP_DISTANCE = settings.startup["fqc-max-motion-step-distance"].value
local ENABLE_CRASH_DAMAGE = settings.startup["fqc-enable-crash-damage"].value
local CRASH_DAMAGE_TYPE = settings.startup["fqc-crash-damage-type"].value
local MAX_SAFE_MOTION_SPEED = settings.startup["fqc-max-safe-motion-speed"].value / 60
local CRASH_DAMAGE_PER_METER_PER_TICK = settings.startup["fqc-crash-damage-per-meter-per-second"].value * 60

exports.on_tick = function()
    entity_dict.foreach_filter_in_place(global.motion_components, function(entity, motion)

        local pos = entity.position
        local surface = entity.surface
        
        -- Since we're bypassing whatever the base game uses for movement,
        -- we need to apply speed modifiers from stickers (biter acid, etc.) manually
        local vehicle_mods = entity.sticker_vehicle_modifiers
        local motion_mult = (vehicle_mods and vehicle_mods.speed_modifier) or 1

        local dx = motion.vx*motion_mult
        local dy = motion.vy*motion_mult
        local speed = (dx*dx + dy*dy)^0.5
        local no_steps = math.max(1, math.ceil(speed / MAX_MOTION_STEP_DISTANCE))
        dx = dx/no_steps
        dy = dy/no_steps

        -- Do a raycast instead of simple position += velocity to prevent wallhacks
        for _=1,no_steps do
            local new_pos = {
                x = pos.x + dx,
                y = pos.y + dy
            }
            -- Ugly hack to work around find_non_colliding_position()
            -- thinking that the entity would collide with itself
            entity.teleport(100)
            new_pos = surface.find_non_colliding_position(
                entity.name,
                new_pos,
                0.2,
                0.1
            )
            if new_pos ~= nil then
                entity.teleport(new_pos)
            else 
                --we've just hit something
                entity.teleport(-100)
                if ENABLE_CRASH_DAMAGE and entity.is_entity_with_health then
                    local damage_amount = 
                        math.max(0, speed - MAX_SAFE_MOTION_SPEED) *
                        CRASH_DAMAGE_PER_METER_PER_TICK
                    entity.damage(damage_amount, "neutral", CRASH_DAMAGE_TYPE)
                end
                return false
            end
            pos = new_pos
        end

        motion.vx = motion.vx * 0.9
        motion.vy = motion.vy * 0.9

        return motion.vx^2 + motion.vy^2 > 0.001
    end)
end

exports.on_script_trigger_effect = function(event)

    local id = event.effect_id
    local id, sufix = string.sub(id, 1, 4), string.sub(id, 5)
    local args = text.split(sufix, ";")

    if id == "fqcr" then
        local amount, randomness = table.unpack(args)
        apply_recoil(
            event.source_entity, 
            event.target_entity or event.target_position, 
            tonumber(amount), 
            tonumber(randomness)
        )
    elseif id == "fqck" then
        local amount, randomness = table.unpack(args)
        apply_recoil(
            event.target_entity,
            event.source_entity or event.source_position,
            tonumber(amount), 
            tonumber(randomness)
        )
    end
end

return exports