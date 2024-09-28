# FQ Core

Utility library for some of my Factorio mods.

## Features

### Custom trigger effects for applying recoil/knockback

```lua
local effect = require("__fq-core__/lib/trigger_effect")

-- later in code:
    ...
    action_delivery = {
        type = "instant",
        -- Applies recoil to the source entity,
        -- launching it away from the target entity/position
        target_effects = effect.recoil{amount = 10}}
    }
    ...
    action_delivery = {
        type = "instant",
        -- Applies knockback to the target entity,
        -- launching it away from the source entity/position
        target_effects = effect.knockback{amount = 10}}
    }
```

- Smooth motion (unlike builtin `PushbackTriggerEffectItem`)
- Entities knocked back / recoiled into obstacles will take impact damage above a certain speed (configurable)

### Attack abstraction (WIP)

```lua
local atk     = require("__fq-core__/lib/attack/attack")
local pre     = require("__fq-core__/lib/attack/premodifier")
local pattern = require("__fq-core__/lib/attack/pattern")

local ammo = util.copy(data.raw.ammo["shotgun-shell"])
ammo.name = "my-fancy-ammo"

ammo.ammo_type.action = atk.to_trigger(atk.chain(
    pre.pattern          { positions = {{1, 0}} },
    pre.add_velocity     { amount = 30, randomness = 0.2 },
    pre.pattern          { velocities = pattern.circle { radius = 2, count = 16 } },
    atk.spawn_projectile { name = "shotgun-pellet", range = 40 }
))
data:extend({ammo})
```

### Text processing utilities
```lua
local text = require("__fq-core__/lib/text")

text.starts_with("abcdefgh", "abcd") --true
text.ends_with("qwertyuiop", "xyzw") --false
text.split("a;b;c", ";")             --{"a", "b", "c"}
```

## Building, running etc. (Linux)

Requirements:
- Make
- jq
- zip

Open the `Makefile` and set the path to your Factorio installation folder:
```Makefile
FACTORIO_FOLDER = ~/GOG\ Games/Factorio
```

The `Makefile` contains some utilities which should help with mod development:
- `make link` creates a symlink to the mod in Factorio's mods folder.
- `make unlink` removes that symlink.
- `make package` creates a ZIP package for the mod.
- `make install` copies that ZIP package to Factorio's mods folder.
- `make uninstall` removes the ZIP package from the Factorio's mods folder.
- `make run` runs Factorio.


## Credits

This project embeds the [pure_lua_SHA library](https://github.com/Egor-Skriptunoff/pure_lua_SHA) written by Egor Skriptunoff (sha2.lua file).