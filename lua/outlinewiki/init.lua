local M = {}

M.setup = function (opts)
  require"outlinewiki.config".setup(opts)
end

return M

-- DEV RELOAD
-- local buf = vim.api.nvim_get_current_buf()
-- vim.api.nvim_create_autocmd({"BufWritePost"},{
--   group = vim.api.nvim_create_augroup("Run", { clear = true }),
--   pattern = "*",
--   desc = "Reload on save",
--   callback = function (opts)
--     if opts.buf == buf then
--       require("plenary.reload").reload_module("util.outline")
--       require("util.outline")
--     end
--   end
-- })
