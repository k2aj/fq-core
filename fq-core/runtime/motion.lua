local exports = {}

local entity_dict = require("lib.entity_dict")

---@class MotionComponent
---@field vx number
---@field vy number

local vehicle_types = {
    ["car"] = true,
    ["spider-vehicle"] = true,
    ["artillery-wagon"] = true,
    ["cargo-wagon"] = true,
    ["fluid-wagon"] = true,
    ["locomotive"] = true
}

local function apply_recoil(event, amount)
    local source = event.source_entity
    if source == nil or not source.valid then return end

    local src_pos = source.position
    local tgt_pos
    if event.target_entity then
        -- Note: if target_entity ~= nil, then the event has no target_position
        tgt_pos = event.target_entity.position
    else
        tgt_pos = event.target_position
    end

    if src_pos.x == tgt_pos.x and src_pos.y == tgt_pos.y then
        --[[
            Someone didn't read the documentation and used recoil as a source_effect.
            (or didn't update past FQ Core 0.1.0)
            (or we just got extremely unlucky)

            The problem here is that tgt_pos == src_pos for source effects,
            so we can't use them to compute recoil direction.
        ]]--
        log(
            "DEPRECATION: Using trigger_effect.recoil as a source_effect is deprecated. " .. 
            "Use it as target_effect instead (recoil amount = "..(amount*60)..")"
        )
        --[[
            Workaround used in FQ Core 0.1.0.
            Only works on characters and vehicles in which the driver is shooting.
            Retained for backwards compatibility.

            TODO: remove this in FQ Core 1.0.0
        ]]--
        local shooting_state
        if source.type == "character" then 
            shooting_state = source.shooting_state
        elseif vehicle_types[source.type] then
            local driver = source.get_driver()
            if driver == nil then return end
            if driver.type ~= "character" then return end
            shooting_state = driver.shooting_state
        end
        if shooting_state == nil then return end
        tgt_pos = shooting_state.position
    end

    -- TL;DR: calculate displacement vector from target to source, 
    -- then scale its length to amount 
    local dx = src_pos.x - tgt_pos.x
    local dy = src_pos.y - tgt_pos.y
    local norm = (dx*dx + dy*dy)^0.5
    if norm < 0.001 then
        dx = 0
        dy = 0
    else
        dx = dx * amount / norm
        dy = dy * amount / norm
    end

    local motion = entity_dict.get(global.motion_components, source)
    if motion == nil then
        motion = {
            vx = dx,
            vy = dy
        }
        entity_dict.put(global.motion_components, source, motion)
    else
        motion.vx = motion.vx + dx
        motion.vy = motion.vy + dy
    end
end

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

    if id == "fqcr" then
        apply_recoil(event, tonumber(sufix))     
    end
end

return exports