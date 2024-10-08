local map = vim.keymap.set

local speed = 5

map({""}, "k", "j", { desc = "switch k j", remap = false, silent = true })
map({""}, "j", "h", { desc = "switch j h", remap = false, silent = true })
map({""}, "i", "k", { desc = "switch i k", remap = false, silent = true })

map({""}, "K", speed .. "j", { desc = "fast j", remap = false, silent = true })
map({""}, "J", speed .. "h", { desc = "fast h", remap = false, silent = true })
map({""}, "I", speed .. "k", { desc = "fast k", remap = false, silent = true })
map({""}, "L", speed .. "l", { desc = "fast l", remap = false, silent = true })

map({""}, "h", "i", { desc = "switch h i", remap = false, silent = true })

