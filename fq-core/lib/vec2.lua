local vec2 = {}

--[[ TODO: GET RID OF THIS HORRIBLE SHIT

    No multiple returns allowed.
]]--

vec2.add = function(x1, y1, x2, y2)
    return x1+x2, y1+y2
end

vec2.sub = function(x1, y1, x2, y2)
    return x1-x2, y1-y2
end

vec2.mul = function(x1, y1, x2, y2)
    return x1*x2, y1*y2
end

vec2.cmul = function(x1, y1, x2, y2)
    return x1*x2 - y1*y2, x1*y2 + y1*x2
end

vec2.cdiv = function(x1, y1, x2, y2)
    local k = vec2.norm2(x2,y2)
    return (x1*x2 + y1*y2)/k, (y1*x2 - x1*y2)/k
end

vec2.norm2 = function(x, y)
    return x*x + y*y
end

vec2.norm = function(x, y)
    return (x*x + y*y)^0.5
end

vec2.normalize_or = function(x, y, default_x, default_y)
    local norm2 = x*x + y*y
    if norm2 < 0.00001 then
        return default_x, default_y
    else
        local norm = norm2^0.5
        return x/norm, y/norm
    end
end

vec2.mix = function(x1, y1, x2, y2, k)
    return (1-k)*x1 + k*x2, (1-k)*y1 + k*y2
end

vec2.polar = function(arg, norm)
    return math.cos(arg)*norm, math.sin(arg)*norm
end

vec2.randomize = function(x, y, randomness)
    local rx, ry = vec2.polar(2*math.pi*math.random(), math.random())
    rx, ry = vec2.cmul(x,y, rx,ry)

    return vec2.mix(
        x,y,
        rx,ry,
        randomness
    )
end

vec2.rotvec_to_orientation = function(x, y)
    local result = math.atan2(y, x) / (2*math.pi) + 0.25
    if result < 0 then
        return result + 1
    else
        return result
    end
end

vec2.orientation_to_rotvec = function(orientation)
    local arg = (orientation - 0.25) * 2*math.pi
    return math.cos(arg), math.sin(arg)
end

return vec2