local ls = require("luasnip")
local ts_utils = require("nvim-treesitter.ts_utils")

local Documents = require("outlinewiki.documents")

local M = {}

local function getCursorDoc()
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
    return nil
  end

  local dest = ""
  for child, _ in link_node:iter_children() do
    if child:type() == "link_destination" then
      dest = vim.treesitter.get_node_text(child, vim.api.nvim_get_current_buf())
    end
  end

  if not (dest == "") then
    if dest:find("/doc/") then
      local dest_doc = Documents:get_by_url(dest)
      if dest_doc == nil then return nil end
      return dest_doc
    end
  end
end

-- FIXME: These are a part of the LSP for now. Remove?

---Open the document linked under the cursor
M.gotoDoc = function ()
  local doc = getCursorDoc()
  if doc then
      doc:open( vim.api.nvim_get_current_win())
  else
    return nil
  end
end

M.hover = function ()
  local doc = getCursorDoc()
  if doc then
    return {
      contents = doc:LSP_hover()
      -- ,
      -- range = {
      --   ["end"] = {
      --     character = 12,
      --     line = 5
      --   },
      --   start = {
      --     character = 5,
      --     line = 5
      --   }
      -- }
    }
  else
    return nil
  end
end

-- Set TS Parser for 'outlinewiki'
vim.treesitter.language.register('markdown', 'outlinewiki')  -- Use the markdown parser for OutlineWiki


-- Create snippets for links.
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


-- Override the default LSP handler
--

-- TODO: Clean this up a bit
local lspconfig = require("lspconfig")
-- table.insert(lspconfigs.marksman.filetypes, "outlinewiki")
lspconfig.marksman.setup{
  filetypes = {'markdown', 'outlinewiki'},
  on_attach = function(client)
    local orig_rpc_request = client.rpc.request
    function client.rpc.request(method, params, handler, ...)
      local orig_handler = handler
      if method == 'textDocument/hover' then
        local doc = getCursorDoc()
        if doc then
          handler(nil, { contents = doc:LSP_hover() })
          return nil
        end
      elseif method == 'textDocument/definition' then
        local doc = getCursorDoc()
        if doc then
          doc:open( vim.api.nvim_get_current_win())
          return nil
          -- return orig_handler(...)
          -- handler = function(...)
          --   local err, result = ...
          --     if not err and result then
          --       local items = result.items or result
          --       for _, item in ipairs(items) do
          --       end
          --     end
          --     return orig_handler(...)
          --   end
        end
      end
      return orig_rpc_request(method, params, handler, ...)
      end
 end
}

return M
