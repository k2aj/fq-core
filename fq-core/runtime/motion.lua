local exports = {}

local entity_dict = require("lib.entity_dict")
local text = require("lib.text")

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

---@param dirX number
---@param dirY number
---@param speed number
---@param randomness number
---@return number vx
---@return number vy
local function make_motion_vector(dirX, dirY, speed, randomness)
    
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

    return dirX*speed, dirY*speed
end

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

local function apply_recoil(event, amount, randomness)
    local source = event.source_entity
    if source == nil or not source.valid then return end

    local src_pos = source.position
    local tgt_pos = event.target_position or event.target_entity.position

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

    local vx, vy = make_motion_vector(
        src_pos.x - tgt_pos.x,
        src_pos.y - tgt_pos.y,
        amount, randomness
    )
    local motion = require_motion_component(source)
    motion.vx = motion.vx + vx
    motion.vy = motion.vy + vy
end

local function apply_knockback(event, amount, randomness)
    local target = event.target_entity
    if target == nil then return end

    local src_pos = event.source_position or event.source_entity.position
    local tgt_pos = target.position

    local vx, vy = make_motion_vector(
        tgt_pos.x - src_pos.x,
        tgt_pos.y - src_pos.y,
        amount, randomness
    )
    local motion = require_motion_component(target)
    motion.vx = motion.vx + vx
    motion.vy = motion.vy + vy
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
    local args = text.split(sufix, ";")

    if id == "fqcr" then
        local amount, randomness = table.unpack(args)
        apply_recoil(event, tonumber(amount), tonumber(randomness))     
    elseif id == "fqck" then
        local amount, randomness = table.unpack(args)
        apply_knockback(event, tonumber(amount), tonumber(randomness))
    end
end

return exports