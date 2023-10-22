local NuiLine = require("nui.line")
local NuiTree = require("nui.tree")

local Documents = require("outlinewiki.documents")
local Collections = require("outlinewiki.collections")


local tree = NuiTree({
  bufnr = vim.fn.bufadd("OutlineWikiMenu"),
  nodes = { NuiTree.Node({ text = "Loading.." }) },
  prepare_node = function(node)
    local line = NuiLine()

    line:append(string.rep("  ", node:get_depth() - 1))

    if node:has_children() then
      if node:is_expanded() then
        line:append(" ", "Comment")
      else
        line:append(" ", "Comment")
      end
    else
      line:append("  ", "SpecialChar")
    end
    if node:type() == "home" then
      line:append(" ", "SpecialChar")
    elseif node:type() == "COL" then
      line:append(" ", "SpecialChar")
    elseif node:type() == "DOC" then
      line:append("󰈙 ", "SpecialChar")
    elseif node:type() == "DFT" then
      line:append("󰷈 ", "SpecialChar")
      line:append("[Draft] ", "Number")
    else
      line:append("---", "SpecialChar")
    end

    line:append(node:title())

    if (node:type() == "DOC") and not (node:tasks() == "None") then
      line:append(" ["..node:tasks().."]", "Comment")
    end
    return line
  end,
})

function tree: refresh (reload)
  local nodes = {}
  if reload then
    Documents:list(true)
  end
  for _, col in ipairs(Collections:list(reload)) do
    table.insert(nodes, col:as_TreeNode())
  end
  self:set_nodes(nodes)
  self:render()
end

tree:refresh()
return tree
