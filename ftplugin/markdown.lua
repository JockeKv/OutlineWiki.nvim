local document = require("outlinewiki.document")
local ls = require("luasnip")

local ok, id = pcall(vim.api.nvim_buf_get_var,0, "outline_id")

if not ok then
  local snips = {}
  local comp = document.complist()
  for _, doc in ipairs(comp) do
    table.insert(snips, ls.snippet(doc.title, {ls.text_node("["..doc.title.."]("..doc.url..")")}))
  end
  ls.add_snippets("all", snips)
end
