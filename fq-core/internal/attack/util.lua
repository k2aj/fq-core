local text = require("__fq-core__/lib/text")

---@class AttackArgs
---@field force ForceIdentification Force using the attack.
---@field surface LuaSurface 
---
---@field src LuaEntity? The attacker.
---@field sx number X coordinate of source position.
---@field sy number Y coordinate of source position.
---
---@field tgt LuaEntity? The target.
---@field tx number X coordinate of target position.
---@field ty number Y coordinate of target position
---
---@field ax number X coordinate of the attack's position.
---@field ay number Y coordinate of the attack's position.
---@field arx number X coordinate of the attack's rotation vector.
---@field ary number Y coordinate of the attack's rotation vector.
---@field avx number X coordinate of the attack velocity vector.
---@field avy number Y coordinate of the attack velocity vector.



---@class Attack
---@field atype string
---@field use fun(atk: Attack, args: AttackArgs)

---@class UnaryModifier: Attack
---@field next Attack?


local function is_attack(value)
    return type(value) == "table" and type(value.atype) == "string"
end

---@param attack Attack
---@return boolean # true if attack is a UnaryModifier
local function is_unary_modifier(attack)
    return is_attack(attack) and (
        text.starts_with(attack.atype, "pre-") or 
        text.starts_with(attack.atype, "post-")
    )
end

local function is_leaf(attack)
    return is_attack(attack) and text.starts_with(attack.atype, "atk-")
end

return {
    is_attack = is_attack,
    is_unary_modifier = is_unary_modifier,
    is_leaf = is_leaf
}