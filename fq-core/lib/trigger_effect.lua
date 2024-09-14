local exports = {}

---@class TriggerEffectItem

---Applies recoil to the source entity.
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