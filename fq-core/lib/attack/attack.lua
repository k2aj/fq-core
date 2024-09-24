local vec2 = require("__fq-core__.lib.vec2")
local atk_util = require("__fq-core__.internal.attack.util")

local text = require("__fq-core__.lib.text")

local attack = {}

---@class AtkSpawnProjectile: Attack
---@field atype "atk-spawn-projectile"
---@field name string Name of the projectile prototype to spawn
---@field range number Range of the projectile
---@field use fun(atk: AtkSpawnProjectile, args: AttackArgs)

---@param atk AtkSpawnProjectile
---@param args AttackArgs
local function AttackSpawnProjectile_impl(atk, args)
    local projectile = args.surface.create_entity{
        name = atk.name,
        position = {args.ax, args.ay},
        force = args.force,
        source = args.src or {args.sx, args.sy},
        target = args.tgt or {args.tx, args.ty},

        -- projectile-specific args
        speed = (args.avx^2 + args.avy^2)^0.5,
        max_range = atk.range
    }
    if projectile then
        projectile.orientation = vec2.rotvec_to_orientation(args.avx, args.avy)
        text.logof("args = ",serpent.line({args.avx, args.avy})," ",projectile.orientation)
    end
end

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
        use = AttackSpawnProjectile_impl
    }
end

---@class AtkComposite
---@field atype "atk-composite"
---@field children Attack[]
---@field use fun(atk: AtkComposite, args: AttackArgs)

---@param atk AtkComposite
---@param args AttackArgs
local function AtkComposite_impl(atk, args)
    for _, next in pairs(atk.children) do
        next.use(next, args)
    end
end



---Combines multiple attacks and modifiers into one attack.
---@param ... Attack
---@return Attack
attack.chain = function(...)
    local args = {...}
    local children = {}
    for i=#args,1,-1 do
        local attack = args[i]
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
    return {
        atype = "atk-composite",
        children = children,
        use = AtkComposite_impl
    }
end

return attack