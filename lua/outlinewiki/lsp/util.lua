local Documents = require("outlinewiki.documents")

local lsp_util = {}

---@return Document|nil, string?
lsp_util.getCursorDoc = function()
  -- Check that the buffer contains a OutlineWiki Document

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
    local parts = vim.split(dest, "#")
    if #parts == 1 then
      if dest:find("/doc/") then
        return Documents:get_by_url(dest)
      end
    elseif #parts > 1 then
      if dest:find("/doc/") then
        return Documents:get_by_url(parts[1]), parts[2]
      elseif parts[1] == '' then
        return nil, parts[2]
      end
    end
  end
end

---@return Document|nil
lsp_util.getCurrentDoc = function ()
  return Documents:get_by_url(vim.fn.expand('%'))
end

---@param doc Document The document to search
---@param heading string The heading to look for
---@return table
lsp_util.getHeaderPos = function (doc, heading)
  -- Make lowercase to search case insensitive
  heading = heading:lower()
  -- Strip 'h-' if present
  heading = heading:gsub("h%-", "", 1)
  -- Replace all '-' with wildcards as we don't know if they should be spaces or dashes
  heading = heading:gsub("-", ".+")
  -- Add the heading marker
  heading = "##+ "..heading

  local lines = vim.split(doc:content(), "\n")

  for nr, line in ipairs(lines) do
    local s, e = line:lower():find(heading)
    if s and e then
      return {
        [ "start" ] = { line = nr-1, character = s },
        [ "end" ] = { line = nr-1, character = e },
      }
    end
  end
end

---@param doc Document The document to search
---@param backlink Document The document to search
---@return table
lsp_util.getLinkPos = function (doc, backlink)

  local lines = vim.split(backlink:content(), "\n")
  local res = {}
  for nr, line in ipairs(lines) do
    local s, e = line:find(doc:url(), 1, true)
    if s and e then
      table.insert(res, {
        [ "start" ] = { line = nr-1, character = s },
        [ "end" ] = { line = nr-1, character = e },
      })
    end
  end
  return res
end


return lsp_util
