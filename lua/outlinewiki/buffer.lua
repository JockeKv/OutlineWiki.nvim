local Config = require("outlinewiki.config")
local Documents = require("outlinewiki.documents")

local M = {}

-- Override the default LSP handler
--
if Config.lsp then
  require("outlinewiki.lsp")
end

-- Set TS Parser for 'outlinewiki'
if Config.integrations.treesitter then
  vim.treesitter.language.register('markdown', 'outlinewiki')  -- Use the markdown parser for OutlineWiki
end

if Config.integrations.luasnip then
  -- Create snippets for links.
  local ls = require("luasnip")
  -- TODO: By adding snippets this way, they can't be updated later.
  --       Think of a way to manage these better
  local snips = {}
  local comp = Documents:complete()
  for _, doc in ipairs(comp) do
    table.insert(snips, ls.snippet("["..doc.title.."]", { ls.text_node("["..doc.title.."]("..doc.url..")") }))
  end
  ls.add_snippets("outlinewiki", snips)

  -- INFO: These can be static if I can't think of a better way
  local snip_info = ls.snippet(":::info", { ls.text_node(":::info "), ls.insert_node(1,"My text here.."), ls.text_node(":::") })
  local snip_warn = ls.snippet(":::warning", { ls.text_node(":::warning "), ls.insert_node(1,"My text here.."), ls.text_node(":::") })
  local snip_tip = ls.snippet(":::tip", { ls.text_node(":::tip "), ls.insert_node(1,"My text here.."), ls.text_node(":::") })
  ls.add_snippets("outlinewiki", { snip_info, snip_tip, snip_warn })
end



return M
