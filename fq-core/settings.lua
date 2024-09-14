data:extend({
    {
        type = "double-setting",
        setting_type = "startup",
        name = "fqc-max-motion-step-distance",
        order = "z[performance]-[motion-step-distance]",
        default_value = 0.5,
        minimum_value = 0.05,
        maximum_value = 10
    },
    {
        type = "bool-setting",
        setting_type = "startup",
        name = "fqc-enable-crash-damage",
        order = "a[motion]-a[crash-damage]-a[enable]",
        default_value = true
    },
    {
        type = "string-setting",
        setting_type = "startup",
        name = "fqc-crash-damage-type",
        order = "a[motion]-a[crash-damage]-b[type]",
        default_value = "physical",
        allowed_values = {"physical", "impact"}
    },
    {
        type = "double-setting",
        setting_type = "startup",
        name = "fqc-max-safe-motion-speed",
        order = "a[motion]-a[crash-damage]-c[max-safe-speed]",
        default_value = 80,
        minimum_value = 0
    },
    {
        type = "double-setting",
        setting_type = "startup",
        name = "fqc-crash-damage-per-meter-per-second",
        order = "a[motion]-a[crash-damage]-d[crash-damage-per-speed-unit]",
        default_value = 3,
        minimum_value = 0
    }
})