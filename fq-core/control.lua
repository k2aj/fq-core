local motion = require("runtime.motion")
local attack = require("runtime.attack")

script.on_init(function()
    motion.on_init()
end)

script.on_event(defines.events.on_tick, function(event)
    motion.on_tick()
end)

script.on_event(defines.events.on_script_trigger_effect, function(event)
    motion.on_script_trigger_effect(event)
    attack.on_script_trigger_effect(event)
end)

script.on_configuration_changed(function(event)
    attack.on_configuration_changed()
end)