local api = require"outlinewiki.api"
local NuiLine = require("nui.line")
local NuiTree = require("nui.tree")
local document = require("outlinewiki.document")
local util = require("outlinewiki.util")


local tree = NuiTree({
  bufnr = vim.fn.bufadd("OutlineWikiMenu"),
  nodes = { NuiTree.Node({ text = "Loading.." }) },
  prepare_node = function(node)
    local line = NuiLine()

    line:append(string.rep("  ", node:get_depth() - 1))

    if node:has_children() then
      if node:is_expanded() then
        line:append(" ", "SpecialChar")
      elseif node.type == "collection" then
        line:append(" ", "SpecialChar")
      elseif node.type == "drafts" then
        line:append("󰣞 ", "SpecialChar")
      end
    else
      if node.type == "home" then
        line:append(" ", "SpecialChar")
      elseif node.type == "document" then
        line:append("󰈙 ", "SpecialChar")
      elseif node.type == "draft" then
        line:append("󰷈 ", "SpecialChar")
        line:append("[Draft] ", "Number")
      else
        line:append("---", "SpecialChar")
      end
    end

    line:append(node.text)

    if node.type == "document" and node.tasks.total > 0 then
      line:append(" ["..node.tasks.completed.."/"..node.tasks.total.."]", "Comment")
    end
    return line
  end,
})

tree.refresh = function (self)
  local s, collections = api.get_collections()
  if s > 200 then print(collections); return end

  local documents = document.list(true)
  if documents == nil then return end

  local nodes = {}
  table.insert(nodes, NuiTree.Node({ text = "Home", id = "home", type = "home" }))

  table.insert(nodes, NuiTree.Node({ text = ""}))

  for _, col in ipairs(collections) do
    local subnodes = {}
    for _, doc in ipairs(util.docs_for_col(col, documents)) do
      if doc.publishedAt == vim.NIL then
        table.insert(subnodes, NuiTree.Node({ text = doc.title:gsub('\n',''), id = doc.id, type = "draft", tasks = doc.tasks }))
      else
        table.insert(subnodes, NuiTree.Node({ text = doc.title:gsub('\n',''), id = doc.id, type = "document", tasks = doc.tasks }))
      end
    end
    table.insert(nodes, NuiTree.Node({ text = col.name:gsub('\n',''), id = col.id, type = "collection" }, subnodes))
  end
  self:set_nodes(nodes)
  self:render()
end

-- local function reload ()
--   local nodes = get_nodes()
--   tree:set_nodes(nodes)
--   tree:render()
-- end

tree:refresh()
return tree
