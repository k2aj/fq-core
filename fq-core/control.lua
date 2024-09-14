local motion = require("runtime.motion")

script.on_init(function()
    motion.on_init()
end)

script.on_event(defines.events.on_tick, function(event)
    motion.on_tick()
end)

script.on_event(defines.events.on_script_trigger_effect, function(event)
    motion.on_script_trigger_effect(event)
end)