local text = require("__fq-core__/lib/text")
local sha2 = require("__fq-core__/internal/sha2")

---Stores entity references used by postmodifiers.
---@class AttackScope
---@field name string                       Name of the scope. Name "/" is reserved for root scope.
---@field parent AttackScope?               The parent scope.
---@field children {[string]: AttackScope}  The child scopes.
---@field entities LuaEntity[]              Entities captured by the scope.


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
---
---@field scope AttackScope Scope used for capturing entities.



---@class Attack
---@field atype string

---@class UnaryModifier: Attack
---@field next Attack?

---@alias AttackImpl fun(atk: Attack, args: AttackArgs)


local function is_attack(value)
    return type(value) == "table" and type(value.atype) == "string"
end

---@param attack Attack
---@return boolean # true if attack is a UnaryModifier
local function is_unary_modifier(attack)
    return is_attack(attack) and (
        text.starts_with(attack.atype, "pre-")
    )
end

local function is_leaf(attack)
    return is_attack(attack) and (
        text.starts_with(attack.atype, "atk-") or
        text.starts_with(attack.atype, "post-")
    )
end

-- NOTE: This must be global. Using `local` causes it to get set to nil for whatever reason.
-- Because who needs a proper module system when you can have TABLES.
-- I hate this language.
fqc_attack_namespace = nil

local function set_namespace(str)
    fqc_attack_namespace = str
end
local function get_effect_id_prefix()
    return "fqca-"..fqc_attack_namespace.."-"
end

local function get_storage_item_id()
    if fqc_attack_namespace == nil then
        error("Attack namespace not set. Did you forget to call __fq-core__.lib.attack.init()?")
    end
    return fqc_attack_namespace .. "-storage-IMPLEMENTATION-DEFINED-MAGIC-DO-NOT-TOUCH-OR-USE-IN-GAME-EVER"
end

local function DATA_get_attack_storage()
    local item = data.raw.ammo[get_storage_item_id()]
    if not item then
        item = util.table.deepcopy(data.raw.ammo["shotgun-shell"])
        item.name = get_storage_item_id()
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

    local attack_str = serpent.dump(attack, {valtypeignore = {["function"] = true}})
    local effect_id = get_effect_id_prefix() .. sha2.md5(attack_str)

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
    local storage = game.item_prototypes[get_storage_item_id()].get_ammo_type().action[1].action_delivery[1].source_effects
    local registry = {}
    if #storage % 2 ~= 0 then
        error("Corrupted attack storage: ", serpent.block(storage))
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

local function validate_scope_name(name)
    if #name == 0 then
        return false, "Scope name can not be empty"
    elseif name == "." or name == ".." then
        return false, "Scope can not use reserved name: `"..name..","
    elseif string.find(name, "/") then
        return false, "Scope name can not contain slashes"
    else
        return true, ""
    end
end

---@param scope AttackScope
---@return AttackScope
local function get_root_scope(scope)
    local parent = scope.parent
    if parent == nil then
        return scope
    else
        return get_root_scope(parent)
    end
end

---@param cur_scope AttackScope
---@param path string
---@return AttackScope?
local function get_scope_by_path(cur_scope, path)

    -- Probably most common case
    local child = cur_scope.children[path]
    if child then return child end

    if path == "." then return cur_scope end
    if path == ".." then return cur_scope.parent end

    -- Handle absolute paths
    if string.sub(path, 1, 1) == "/" then
        path = string.sub(path, 2)
        cur_scope = get_root_scope(cur_scope)
    end

    local parts = text.split(path, "/")
    for _, part in ipairs(parts) do
        if part == "." then 
            --no op
        elseif part == ".." then
            -- ".." stops at root (similar to how file systems work)
            cur_scope = cur_scope.parent or cur_scope
        else
            cur_scope = cur_scope.children[part]
        end
        if cur_scope == nil then return nil end
    end

    return cur_scope
end

return {
    is_attack = is_attack,
    is_unary_modifier = is_unary_modifier,
    is_leaf = is_leaf,
    set_namespace = set_namespace,
    get_effect_id_prefix = get_effect_id_prefix,
    get_scope_by_path = get_scope_by_path,
    validate_scope_name = validate_scope_name,
    DATA_register_attack = DATA_register_attack,
    CONTROL_get_attack_registry = CONTROL_get_attack_registry
}