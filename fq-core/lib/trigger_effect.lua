local exports = {}

---@class TriggerEffectItem

---Applies recoil to the source entity.
---
---!!! MUST BE USED AS A TARGET_EFFECT !!!
---(Yes, even though it applies to the source entity. It's confusing, I know.)
---
---This is an expensive operation in terms of UPS.
---Avoid using it for many different entities.
---
---@param args table
---@param args.amount     number? Recoil speed [m/s]
---@param args.randomness number? 0 = recoil away from target. 1 = in random direction. Values inbetween = combination of the two.
---@return TriggerEffectItem
exports.recoil = function(args)

    -- For backwards compatibility with FQ Core 0.1.0
    -- TODO: remove this in FQ Core 1.0.0
    if type(args) == "number" then
        return {
            type = "script",
            effect_id = "fqcr" .. (args/60) .. ";0"
        }
    end

    local amount = args.amount or 15
    local randomness = args.randomness or 0.1
    return {
        type = "script",
        effect_id = "fqcr" .. (amount/60) .. ";" .. randomness
    }
end

---Applies knockback to the target entity.
---@param args table
---@param args.amount number? Knockback speed [m/s]
---@param randomness  number? 0 = knockback away from source. 1 = in random direction. Values inbetween = combination of the two.
---@return table
exports.knockback = function(args)
    local amount = args.amount or 15
    local randomness = args.randomness or 0.1
    return {
        type = "script",
        effect_id = "fqck" .. (amount/60) .. ";" .. randomness
    }
end

return exports