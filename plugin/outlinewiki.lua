
if vim.g.loaded_outlinewiki == 1 then
  return
end
vim.g.loaded_outlinewiki = 1

local cmd = require("outlinewiki.command")

vim.api.nvim_create_user_command("OutlineWiki", function(opts)
  cmd.run(opts)
end, {
    nargs = "*",
    complete = cmd.complete,
  })
