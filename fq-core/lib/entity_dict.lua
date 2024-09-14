local exports = {}

--[[ EntityDict is a dictionary mapping entities to arbitrary values.

    Features:
    - O(1) insertion/lookup/removal for entities with a unit_number
    - O(m) insertion/lookup/removal for entities without unit_number 
        (where m=number of such entities; entities with unit_number don't count for this!)
    - O(n) bulk iteration of all stored entities + values
        - Allows removal of currently iterated entity/value
        - Invalid entities are automatically skipped and removed during bulk iteration
        - Deterministic iteration order (so hopefully no desyncs)
]]--

---@class EntityDict
---@field dense_entities    LuaEntity[]
---@field dense_entries     any[]
---@field sparse            integer[]
---@field inverse_sparse    integer[]
---@field aside_entities    LuaEntity[]
---@field aside_entries     any[]

---Creates an empty EntityDict
---@return EntityDict
exports.new = function()
    ---@type EntityDict
    return {
        -- Sparse set for entities with unit_number
        dense_entities = {},
        dense_entries = {},
        sparse = {},
        inverse_sparse = {},

        -- Fallback dumb array with linear search for entities without unit_number
        aside_entities = {},
        aside_entries = {}
    }
end

---@param dict EntityDict
---@param entity LuaEntity
---@return integer|nil
local function find_aside_index(dict, entity)
    for i, e in pairs(dict.aside_entities) do
        if e == entity then return i end
    end
    return nil
end

---Checks if an EntityDict contains an entity.
---
---MUST NOT be used with invalid entities.
---@param dict EntityDict
---@param entity LuaEntity
---@return boolean
exports.contains = function(dict, entity)
    if not entity.valid then 
        -- So the problem here is that you can't fetch unit_number
        -- from an invalid entity reference
        error("Attempted to lookup invalid entity in entity_dict") 
    end

    local unum = entity.unit_number
    if unum == nil then
        return find_aside_index(dict, entity) ~= nil
    else
        return dict.sparse[unum] ~= nil
    end
end

---Returns the data associated with an entity in an EntityDict.
---
---MUST NOT be used with invalid entities.
---@param dict EntityDict
---@param entity LuaEntity
---@return any|nil
exports.get = function(dict, entity)
    if not entity.valid then 
        error("Attempted to lookup invalid entity in entity_dict") 
    end

    local unum = entity.unit_number
    if unum == nil then
        local i = find_aside_index(dict, entity)
        return i and dict.aside_entries[i]
    else
        local i = dict.sparse[unum]
        return i and dict.dense_entries[i]
    end
end

---Inserts an entity and an associated piece of data into this EntityDict.
---
---MUST NOT be used with invalid entities.
---@param dict EntityDict
---@param entity LuaEntity
---@param entry any
exports.put = function(dict, entity, entry)
    if not entity.valid then 
        error("Attempted to store invalid entity in entity_dict") 
    end
    
    local unum = entity.unit_number
    if unum == nil then
        local i = find_aside_index(dict, entity)
        if i == nil then
            dict.aside_entries[#dict.aside_entries+1] = entry
            dict.aside_entities[#dict.aside_entities+1] = entity
        else
            dict.aside_entries[i] = entry
        end

    else
        local i = dict.sparse[unum]
        if i == nil then
            dict.dense_entities[#dict.dense_entities+1] = entity
            dict.dense_entries[#dict.dense_entries+1] = entry
            dict.sparse[unum] = #dict.dense_entries
            dict.inverse_sparse[#dict.dense_entries] = unum
        else
            dict.dense_entries[i] = entry
        end
    end
end

---Removes an entity and its associated data from this EntityDict.
---
---Can be used for removing invalid entities.
---@param dict EntityDict
---@param unum integer Unit number of the removed entity.
exports.remove_by_unit_number = function(dict, unum)
    local i = dict.sparse[unum]
    if i == nil then return end
    local j = #dict.dense_entries

    if i ~= j then
        local junum = dict.inverse_sparse[j]
        dict.dense_entries[i] = dict.dense_entries[j]
        dict.dense_entities[i] = dict.dense_entities[j]
        dict.sparse[junum] = i
        dict.inverse_sparse[i] = junum
    end
    dict.dense_entries[j] = nil
    dict.dense_entities[j] = nil
    dict.sparse[unum] = nil
    dict.inverse_sparse[j] = nil
end

---Removes an entity and its associated data from this EntityDict
---
---MUST NOT be used for invalid entities.
---@param dict EntityDict
---@param entity LuaEntity
exports.remove = function(dict, entity)
    if not entity.valid then 
        error("Attempted to remove invalid entity from entity_dict.")
    end

    local unum = entity.unit_number
    if unum == nil then 
        local i = find_aside_index(dict, entity)
        if i == nil then return end
        table.remove(dict.aside_entities, i)
        table.remove(dict.aside_entries, i)
    else
        exports.remove_by_unit_number(dict, unum)
    end
end

---Iterates over all entities and their associated data entries.
---
---Calls callback(entity, entry) for each valid entity.
---If the callback returns a falsy value, the entity is removed from the EntityDict.
---@param dict EntityDict
---@param callback fun(entity: LuaEntity, entry: any): boolean
exports.foreach_filter_in_place = function(dict, callback)

    local aside_entities = dict.aside_entities
    local aside_entries = dict.aside_entries
    for i = #aside_entities,1,-1 do
        local entity = aside_entities[i]
        local entry = aside_entries[i]
        local keep = entity.valid
        if keep then
            keep = callback(entity, entry)
        end
        if not keep then
            aside_entities[i] = nil
            aside_entries[i] = nil
        end
    end

    local dense_entities = dict.dense_entities
    local dense_entries = dict.dense_entries
    local inverse_sparse = dict.inverse_sparse
    for i = #dense_entities,1,-1 do
        local entity = dense_entities[i]
        local entry = dense_entries[i]
        local keep = entity.valid
        if keep then
            keep = callback(entity, entry)
        end
        if not keep then
            exports.remove_by_unit_number(dict, inverse_sparse[i])
        end
    end
end

---Removes all invalid entities from an EntityDict
---@param dict EntityDict
exports.remove_invalid_entities = function(dict)
    local aside_entities = dict.aside_entities
    local aside_entries = dict.aside_entries
    for i = #aside_entities,1,-1 do
        if not aside_entities[i].valid then
            aside_entities[i] = nil
            aside_entries[i] = nil
        end
    end
    local dense_entities = dict.dense_entities
    local inverse_sparse = dict.inverse_sparse
    for i = #dense_entities,1,-1 do
        if not dense_entities[i].valid then
            exports.remove_by_unit_number(dict, inverse_sparse[i])
        end
    end
end

return exports