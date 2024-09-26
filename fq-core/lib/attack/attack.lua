local atk_util = require("__fq-core__.internal.attack.util")

local attack = {}

---@param args table
---@param args.name string Name of the projectile prototype.
---@param args.range number Range of the fired projectile.
---@return AtkSpawnProjectile
attack.spawn_projectile = function(args)
    local name = args.name or error("attack.spawn_projectile: missing argument \"name\"")
    local range = args.range or error("attack.spawn_projectile: missing argument \"range\"")
    return {
        atype = "atk-spawn-projectile",
        name = name,
        range = range,
    }
end

---Uses one of the child attacks, selected at random.
---@param children Attack[]
---@return AtkRandom
attack.random = function(children)
    return {
        atype = "atk-random",
        children = children
    }
end

---Combines multiple attacks and modifiers into one attack.
---@param attacks Attack[]
---@return Attack
attack.chain = function(attacks)
    local children = {}
    for i=#attacks,1,-1 do
        local attack = attacks[i]
        if atk_util.is_unary_modifier(attack) then
            local child = children[#children]
            if child == nil then 
                error("attack.chain: last attack in chain can't be a modifier")
            end
            attack.next = child
            children[#children] = attack
        elseif atk_util.is_attack(attack) then
            children[#children+1] = attack
        else
            error("attack.chain: non-attack value is not allowed: "..serpent.line(attack))
        end
    end
    for i=1,math.floor(#children/2) do
        local tmp = children[i]
        children[i] = children[#children+1-i]
        children[#children+1-i] = tmp
    end
    return {
        atype = "atk-composite",
        children = children,
    }
end

---Converts an Attack to a TriggerEffectItem.
---
---@param attack Attack
---@return TriggerEffectItem # Can only be used in target_effects
local function to_effect(attack)
    return {type = "script", effect_id = atk_util.DATA_register_attack(attack)}
end
attack.to_effect = to_effect

--- Converts an Attack to a TriggerItem
---@param attack Attack
---@return TriggerItem
attack.to_trigger = function(attack)
    return {
        type = "direct",
        action_delivery = {
            type = "instant",
            target_effects = to_effect(attack)
        }
    }
end

return attack