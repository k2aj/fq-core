local text = require("__fq-core__/lib/text")
local sha2 = require("__fq-core__/internal/sha2")

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

local STORAGE_ITEM_ID = "fqc-attack-registry-storage-IMPLEMENTATION-DEFINED-MAGIC-DO-NOT-TOUCH-OR-USE-IN-GAME-EVER"

local function DATA_get_attack_storage()
    local item = data.raw.ammo[STORAGE_ITEM_ID]
    if not item then
        item = util.table.deepcopy(data.raw.ammo["shotgun-shell"])
        item.name = STORAGE_ITEM_ID
        item.ammo_type.action = {{
            type = "direct",
            action_delivery = {{
                type = "instant",
                source_effects = {}
            }}
        }}
        item.subgroup = nil
        data:extend({item})
    end
    return item.ammo_type.action[1].action_delivery[1].source_effects
end

local registered_attack_hashes = {}

---@param attack Attack
---@return string
local function DATA_register_attack(attack)

    local attack_str = serpent.dump(attack)
    local effect_id = "fqca" .. sha2.md5(attack_str)

    if registered_attack_hashes[effect_id] then return effect_id end
    registered_attack_hashes[effect_id] = true

    local storage = DATA_get_attack_storage()
    storage[#storage+1] = {type = "script", effect_id = effect_id}
    storage[#storage+1] = {type = "script", effect_id = attack_str}
    return effect_id
end

---@return {[string]: Attack}
local function CONTROL_get_attack_registry()
    --log("THE ACTION IS: "..serpent.dump(game.item_prototypes[STORAGE_ITEM_ID].get_ammo_type().action))
    local storage = game.item_prototypes[STORAGE_ITEM_ID].get_ammo_type().action[1].action_delivery[1].source_effects
    local registry = {}
    if #storage % 2 ~= 0 then
        error("Corrupted attack storage: ", serpent.dump(storage))
    end
    for i = 1,#storage,2 do
        local effect_id = storage[i].effect_id
        local ok, attack = serpent.load(storage[i+1].effect_id)
        if ok then
            registry[effect_id] = attack
        else
            text.logof("Failed to deserialize attack from storage (id=",effect_id,"): ",storage[i+1].effect_id)
        end
    end
    return registry
end


return {
    is_attack = is_attack,
    is_unary_modifier = is_unary_modifier,
    is_leaf = is_leaf,
    DATA_register_attack = DATA_register_attack,
    CONTROL_get_attack_registry = CONTROL_get_attack_registry
}