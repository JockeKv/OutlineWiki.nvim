local ls = require("luasnip")
local ts_utils = require("nvim-treesitter.ts_utils")

local documents = require("outlinewiki.documents")

local M = {}

---Open the document linked under the cursor
M.gotoDoc = function ()
  -- Check that the buffer contains a OutlineWiki Document
  local ok, _ = pcall(vim.api.nvim_buf_get_var,0, "outline_id")
  if not ok then
    return
  end

  local node = ts_utils.get_node_at_cursor()
  local link_node = nil
  if node:type() == "inline_link" then
    link_node = node
  elseif (node:type() == "link_text") or (node:type() == "link_destination") then
    link_node = node:parent()
  else
    return
  end

  local dest = ""
  for child, _ in link_node:iter_children() do
    if child:type() == "link_destination" then
      dest = vim.treesitter.get_node_text(child, vim.api.nvim_get_current_buf())
    end
  end

  if not (dest == "") then
    if dest:find("/doc/") then
      documents.open(dest:gsub("/doc/", ""), vim.api.nvim_get_current_win())
    end
  end
end

-- Create snippets for links.
-- TODO: By adding snippets this way, they can't be updated later.
--       Think of a way to manage these better
local snips = {}
local comp = documents.complist()
for _, doc in ipairs(comp) do
  table.insert(snips, ls.snippet("["..doc.title.."]", { ls.text_node("["..doc.title.."]("..doc.url..")") }))
end
ls.add_snippets("markdown", snips)

local snip_info = ls.snippet(":::info", { ls.text_node(":::info "), ls.insert_node(1,"My text here.."), ls.text_node(":::") })
local snip_warn = ls.snippet(":::warning", { ls.text_node(":::warning "), ls.insert_node(1,"My text here.."), ls.text_node(":::") })
local snip_tip = ls.snippet(":::tip", { ls.text_node(":::tip "), ls.insert_node(1,"My text here.."), ls.text_node(":::") })
ls.add_snippets("markdown", { snip_info, snip_tip, snip_warn })

return M

-- Override the default LSP handler
--
-- nvim_lsp.clangd.setup{
--  on_attach = function(client)
--    local orig_rpc_request = client.rpc.request
--    function client.rpc.request(method, params, handler, ...)
--      local orig_handler = handler
--      if method == 'textDocument/completion' then
--      handler = function(...)
--        local err, result = ...
--          if not err and result then
--            local items = result.items or result
--            for _, item in ipairs(items) do
--            end
--          end
--          return orig_handler(...)
--        end
--      end
--      return orig_rpc_request(method, params, handler, ...)
--    end
--  end
-- }
