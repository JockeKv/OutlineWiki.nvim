local split = require("outlinewiki.ui.split")
local document = require"outlinewiki.document"

local UI = {
}

UI.open = function ()
  local win = vim.api.nvim_get_current_win()
  split(win)
end

UI.tab_open = function ()
  vim.cmd[[tab split]]
  local win = vim.api.nvim_get_current_win()
  split(win)
  document.open("home", win)
end

return UI
