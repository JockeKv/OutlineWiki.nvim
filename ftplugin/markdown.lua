local buffer = require("outlinewiki.buffer")

local ok, id = pcall(vim.api.nvim_buf_get_var,0, "outline_id")

vim.keymap.set("n", "q", buffer.gotoDoc)
