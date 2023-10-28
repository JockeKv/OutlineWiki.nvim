
if vim.g.loaded_outlinewiki == 1 then
  return
end
vim.g.loaded_outlinewiki = 1

local cmd = require("outlinewiki.command")
local Documents = require("outlinewiki.documents")

vim.api.nvim_create_user_command("OutlineWiki", function(opts)
  cmd.run(opts)
end, {
    nargs = "*",
    complete = cmd.complete,
  })

vim.api.nvim_create_autocmd("BufReadCmd", {
  group = vim.api.nvim_create_augroup("outlinewiki", { clear = true }),
  pattern = { "outlinewiki://*" },
  callback = function(event)
    local buf = vim.fn.expand("<amatch>") --[[@as string]]
    local url = buf:gsub("outlinewiki://", "")
    local doc = Documents:get_by_url(url)
    if doc then
      doc:open(vim.api.nvim_get_current_win())
    end
  end,
  desc = "OutlineWiki protocol handler",
})
