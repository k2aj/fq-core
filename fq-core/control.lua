require("globals")
local motion = require("runtime.motion")
local attack = require("lib.attack.runtime")

if FQC_TESTING_MODE then
    attack.init{namespace = "fqc"}
end

script.on_init(function()
    motion.on_init()
    attack.on_init()
end)

script.on_event(defines.events.on_tick, function(event)
    motion.on_tick()
    attack.on_tick()
end)

script.on_event(defines.events.on_script_trigger_effect, function(event)
    motion.on_script_trigger_effect(event)
    if FQC_TESTING_MODE then
        attack.on_script_trigger_effect(event)
    end
end)

if FQC_TESTING_MODE then
    script.on_configuration_changed(function(event)
        attack.on_configuration_changed()
    end)
end

require("runtime.remote")