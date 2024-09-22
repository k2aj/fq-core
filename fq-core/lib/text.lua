local function is_identifier(str)
    return string.match(str, "^[%a_][%w_]*$") ~= nil
end 

local function repr_impl(accum, value)
    local t = type(value)
    if t == "nil" then 
        accum[#accum+1] = t
    elseif t == "number" or t == "boolean" then
        accum[#accum+1] = value
    elseif t == "string" then
        value = string.gsub(value, "\\", "\\\\")
        value = string.gsub(value, "\"", "\\\"")
        accum[#accum+1] = "\""
        accum[#accum+1] = value
        accum[#accum+1] = "\""
    elseif t == "table" then
        accum[#accum+1] = "{"
        local keys = {}
        local only_numeric_keys = true
        for key in pairs(value) do
            keys[#keys+1] = key
            if type(key) ~= "number" then
                only_numeric_keys = false
            end
        end
        if only_numeric_keys then
            table.sort(keys)
        else
            table.sort(keys, function(a,b) 
                return tostring(a) < tostring(b)
            end)
        end

        -- Array = all keys are consecutive ints and smallest key is 1
        local is_array = true
        for i = 1,#keys do
            if keys[i] ~= i then 
                is_array = false 
            end
        end

        for i, k in ipairs(keys) do
            if i > 1 then
                accum[#accum+1] = ", "
            end
            if not is_array then
                if is_identifier(k) then
                    accum[#accum+1] = k
                    accum[#accum+1] = "="
                else
                    accum[#accum+1] = "[" 
                    repr_impl(accum, k)
                    accum[#accum+1] = "]=" 
                end
            end
            repr_impl(accum, value[k])
        end

        accum[#accum+1] = "}"
    else
        accum[#accum+1] = "<"
        accum[#accum+1] = t 
        accum[#accum+1] = ">"
    end
    return accum
end

---Converts the argument to a Lua-like string representation.
---
---Useful for dumping tables etc. in logs.
---@param value any
---@return string
local function repr(value)
    return table.concat(repr_impl({}, value))
end

local function of_impl(accum, ...)

    for _, value in ipairs({...}) do
        local t = type(value)
        if t == "string" then 
            accum[#accum+1] = value
        else
            accum[#accum+1] = repr(value)
        end
    end

    return accum
end

---Converts all arguments to strings and returns their concatenation.
---
---Tables are converted using repr().
---
---Other values are converted to strings directly.
---@param ... any
---@return string
local function of(...)
    return table.concat(of_impl({}, ...))
end

---Shorthand for log(of(...))
---@param ... any
local function logof(...)
    log(of(...))
end

---Tests if a string starts with the given prefix.
---@param str string
---@param prefix string
---@return boolean
local function starts_with(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

---Tests if a string ends with the given sufix.
---@param str string
---@param sufix string
---@return boolean
local function ends_with(str, sufix)
    return string.sub(str, #str - #sufix + 1) == sufix
end

---Splits a string using the given separator.
---@param str string
---@param separator string
---@return string[]
local function split(str, separator)
    local parts = {}
    local pattern = "([^"..separator.."]+)"
    for x in string.gmatch(str, pattern) do
        parts[#parts+1] = x
    end
    return parts
end

return {
    repr = repr,
    of = of,
    logof = logof,
    starts_with = starts_with,
    ends_with = ends_with,
    split = split
}