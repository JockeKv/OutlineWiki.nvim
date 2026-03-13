local Documents = require("outlinewiki.documents")

local lsp_util = {}

lsp_util.getCursorDoc = function()
  -- Check that the buffer contains a OutlineWiki Document
  local ok, _ = pcall(vim.api.nvim_buf_get_var,0, "outline_id")
  if not ok then
    return
  end

  vim.treesitter.get_parser(0, 'markdown'):parse()

  local node = vim.treesitter.get_node()
  if not node then
    return
  end

  if node:type() == "inline" then
    local parser = vim.treesitter.get_parser(0, 'markdown_inline')
    if not parser then
      return
    end
    local inline = parser:parse(vim.treesitter.get_range(node, 0))[1]:root()

    for _, child in ipairs(inline:named_children()) do
      if vim.treesitter.node_contains(node, vim.treesitter.get_range(child, 0)) then
        node = child
        break
      end
    end
  end

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
