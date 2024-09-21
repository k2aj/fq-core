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
---@param amount number Recoil speed [m/s]
---@return TriggerEffectItem
exports.recoil = function(amount)
    return {
        type = "script",
        effect_id = "fqcr" .. (amount/60)
    }
end

return exports