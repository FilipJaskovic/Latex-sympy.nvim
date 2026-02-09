--- Run busted specs inside headless Neovim so `vim` APIs are available.
---
--- e.g. `nvim -u NONE -U NONE -N -i NONE --headless -c "luafile scripts/run_busted.lua" -c "quit"`
---

dofile("spec/minimal_init.lua")

_G.arg = { "spec", [0] = "busted" }
require("busted.runner")({ standalone = false })
