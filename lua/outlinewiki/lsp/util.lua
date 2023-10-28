local ts_utils = require("nvim-treesitter.ts_utils")

local Documents = require("outlinewiki.documents")

local lsp_util = {}

lsp_util.getCursorDoc = function()
  -- Check that the buffer contains a OutlineWiki Document
  local ok, _ = pcall(vim.api.nvim_buf_get_var,0, "outline_id")
  if not ok then
    return
  end

  local node = ts_utils.get_node_at_cursor()
  -- print(vim.inspect(ts_utils.get_named_children(node)))
  -- for _, child in ipairs(ts_utils.get_named_children(node)) do
  --   print(ts_utils.get_node_text(node))
  -- end
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

return lsp_util
