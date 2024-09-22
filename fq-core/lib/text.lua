

---Converts all arguments to strings and returns their concatenation.
---
---Tables are converted using serpent.line()
---
---Other values are converted to strings directly.
---@param ... any
---@return string
local function of(...)
    local parts = {}
    for _, value in ipairs({...}) do
        local t = type(value)
        if t == "number" or t == "boolean"
            then parts[#parts+1] = tostring(value)
        elseif t =="string" then 
            parts[#parts+1] = value
        elseif t == "table" then 
            parts[#parts+1] = serpent.line(value)
        else 
            parts[#parts+1] = "<"..t..">" 
        end
    end
    return table.concat(parts)
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
    of = of,
    logof = logof,
    starts_with = starts_with,
    ends_with = ends_with,
    split = split
}