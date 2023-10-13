local split = require("outlinewiki.ui.split")
local document = require("outlinewiki.document")

local UI = {
}

local function get_tab()
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in pairs(tabs) do
    local ok, tabname = pcall(vim.api.nvim_tabpage_get_var,tab, "tabname")
    if ok and (tabname == "OutlineWiki") then return tab end
  end
end


local function is_open()
  local tab = vim.api.nvim_get_current_tabpage()
  local wins = vim.api.nvim_tabpage_list_wins(tab)
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
    if (ft == "OutlineMenu") then return win end
  end
end

UI.open = function ()
  local win = is_open()
  if win then
    vim.api.nvim_set_current_win(win)
    return
  end
  win = vim.api.nvim_get_current_win()
  split(win)
end

UI.tab_open = function ()
  local tab = get_tab()
  if tab then
    vim.cmd("tabn".." "..tab)
    return
  end
  vim.cmd[[tabnew]]
  vim.api.nvim_tabpage_set_var(0, "tabname", "OutlineWiki")
  local win = vim.api.nvim_get_current_win()
  split(win)
  document.open("home", win)
end

return UI
