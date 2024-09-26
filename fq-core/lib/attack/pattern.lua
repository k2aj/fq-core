local exports = {}

---@class Point: {[1]:number, [2]:number}
---@alias Dimensions number|{[1]:number, [2]:number}

---@class Pattern
local Pattern = {}

---@return Pattern
function Pattern.new()
    local result = {}
    for k,v in pairs(Pattern) do
        if k ~= "new" then
            result[k] = v
        end
    end
    result.points = {}
    return result
end

---@param pattern Pattern
---@param p1 Point
---@param p2 Point
---@param npoints integer
local function add_inbetweens(pattern, p1, p2, npoints)
    local x1 = p1[1]
    local y1 = p1[2]
    local x2 = p2[1]
    local y2 = p2[2]
    local dx = (x2-x1)/(npoints+1)
    local dy = (y2-y1)/(npoints+1)
    for i=1,npoints do
        pattern[#pattern+1] = {
            x1 + i*dx,
            y1 + i*dy
        }
    end
end

---@param self Pattern
---@param npoints integer
---@return Pattern
function Pattern.subdivide_line(self, npoints)
    if #self <= 1 then return self:dup() end
    local result = Pattern.new()
    for i=1,#self-1 do
        result[#result+1] = self[i]
        add_inbetweens(result, self[i], self[i+1], npoints)
    end
    result[#result+1] = self[#self]
    return result
end

---@param self Pattern
---@param npoints integer
---@return Pattern
function Pattern.subdivide_loop(self, npoints)
    if #self <= 1 then return self:dup() end
    local result = self:subdivide_line(npoints)
    if #self >= 3 then
        add_inbetweens(result, self[#self], self[1], npoints)
    end
    return result
end

---Creates a new pattern by applying function `f` to each point in the pattern.
---@param self Pattern
---@param f fun(p:Point):Point
---@return Pattern
function Pattern.map(self, f)
    local result = Pattern.new()
    for _,point in ipairs(self) do
        result[#result+1] = f(point)
    end
    return result
end

---Creates a copy of the pattern.
---@param self Pattern
---@return Pattern
function Pattern.dup(self)
    return self:map(function(x) return x end)
end

---@param self Pattern
---@param scale {[1]: number, [2]: number}|number
---@return Pattern
function Pattern.scale(self, scale)
    if type(scale) == "number" then scale = {scale, scale} end
    return self:map(function(point) return {point[1]*scale[1], point[2]*scale[2]} end)
end

---@param self Pattern
---@param translation {[1]: number, [2]: number}
---@return Pattern
function Pattern.move(self, translation)
    return self:map(function(point) return {point[1]+translation[1], point[2]+translation[2]} end)
end

---Rotates the pattern around the origin `{0,0}`
---@param self Pattern
---@param angle number
---@return Pattern
function Pattern.rotate(self, angle)
    local rx = math.cos(angle)
    local ry = math.sin(angle)
    return self:map(function(point) return {
        rx*point[1] - ry*point[2],
        ry*point[1] + rx*point[2]
    } end)
end

---@param self Pattern
---@return {[1]: Point, [2]: Point} #The bounding box of the pattern.
function Pattern.bounding_box(self)
    if #self == 0 then return {{0,0}, {0,0}} end
    local x0 = self[1][1]
    local x1 = x0
    local y0 = self[1][2]
    local y1 = y0
    for _, point in ipairs(self) do
        x0 = math.min(x0, point[1])
        x1 = math.max(x1, point[1])
        y0 = math.min(y0, point[2])
        y1 = math.max(y1, point[2])
    end
    return {{x0,y0}, {x1,y1}}
end

---Centers a pattern around the origin `{0,0}`
---@param self Pattern
---@param method "bounding-box"|"mean"|nil
function Pattern.center(self, method)
    if #self == 0 then self:dup() end

    local center
    if method == nil or method == "bounding-box" then
        local lo, hi = table.unpack(self:bounding_box())
        center = {(lo[1]+hi[1])/2, (lo[2]+hi[2])/2}
    elseif method == "mean" then
        local sx,sy = 0,0
        for _, point in ipairs(self) do
            sx = sx + point[1]
            sy = sy + point[2]
        end
        center = {sx/#self, sy/#self}
    else 
        error("Unknown pattern centering method:"..method)
    end
    return self:move{-center[1], -center[2]}
end

local text = require("lib.text")

---Moves and scales the pattern to fit it in a rectangle of the specified size.
---@param self Pattern
---@param size Dimensions Dimensions of the rectangle in which to fit the pattern.
---@return Pattern
function Pattern.fit(self, size)
    if size == nil then size = {1,1} end
    if type(size) == "number" then size = {size, size} end

    local result = self:center("bounding-box")
    if #result == 1 then return result end
    local _, hi = table.unpack(result:bounding_box())

    for i,p in ipairs(result) do
        result[i] = {p[1]*size[1]/(2*hi[1]), p[2]*size[2]/(2*hi[2])}
    end
    return result
end

---Creates a pattern by evaluating a parametric function `f` over a given domain.
---@param args {domain: {[1]:number, [2]:number}, npoints: integer, f: fun(t:number): Point}
---@return Pattern
function exports.parametric_curve(args)
    local domain = args.domain or error("Missing argument: interval")
    local npoints = args.npoints or error("Missing argument: npoints")
    local f = args.f or error("Missing argument: f")

    local t0, t1 = table.unpack(domain)
    local result = Pattern.new()
    local dt = (t1 - t0) / npoints
    for i=1,npoints do
        result[#result+1] = f(t0 + i*dt)
    end
    return result
end

---Creates regular polygon-shaped pattern.
---@param npoints integer Number of vertices in the polygon.
---@return Pattern
function exports.regular(npoints)
    return exports.parametric_curve{
        domain = {0, 2*math.pi},
        npoints = npoints,
        f = function(t) return {0.5*math.cos(t), 0.5*math.sin(t)} end
    }
end

---Creates a heart-shaped pattern.
---@param npoints number Number of points used to represent the heart.
---@return Pattern
function exports.heart(npoints)
    return exports.parametric_curve{
        domain = {0, 2*math.pi},
        npoints = npoints, 
        f = function(t) return {
            2*(-math.sin(t)^3 - math.sin(t)^2 + 2*math.sin(t) + 1), 
            2*(2^0.5 * math.cos(t)^3)
        } end
    }:fit{1,1}
end

---Creates a star-shaped pattern.
---@param args {ntips: number, ratio: number?}
---@return Pattern
function exports.star(args)
    local ntips = args.ntips or error("Missing argument: ntips")
    local ratio = args.ratio or 0.5
    
    local outer = exports.regular(ntips)
    local inner = outer:rotate(math.pi/ntips):scale(ratio)
    local result = Pattern.new()

    for i=1,#outer do
        result[#result+1] = outer[i]
        result[#result+1] = inner[i]
    end
    return result
end

---Merges multiple patterns into a single pattern by concatenating their points together.
---@param patterns Pattern[]
---@return Pattern
function exports.concat(patterns)
    local result = Pattern.new()
    for _, pattern in ipairs(patterns) do
        for _, point in ipairs(pattern) do
            result[#result+1] = point
        end
    end
    return result
end

return exports