# FQ Core

Utility library for some of my Factorio mods.

## Building, running etc. (Linux)

Requirements:
- Make
- jq
- zip

Open the `Makefile` and set the path to your Factorio installation's mod folder:
```Makefile
FACTORIO_MODS_FOLDER = ~/GOG\ Games/Factorio/game/mods
```

The `Makefile` contains some utilities which should help with mod development:
- `make link` creates a symlink to the mod in Factorio's mods folder.
- `make unlink` removes that symlink.
- `make package` creates a ZIP package for the mod.
- `make install` copies that ZIP package to Factorio's mods folder.
- `make uninstall` removes the ZIP package from the Factorio's mods folder.


## Credits

This project embeds the [pure_lua_SHA library](https://github.com/Egor-Skriptunoff/pure_lua_SHA) written by Egor Skriptunoff (sha2.lua file).