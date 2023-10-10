local NuiTree = require("nui.tree")
local Split = require("nui.split")

local popup = require"outlinewiki.ui.popup"
local document = require"outlinewiki.document"
local api = require"outlinewiki.api"

return function(cwin)
  local tree = require("outlinewiki.ui.tree")

  local split = Split({
    relative = "editor",
    position = "left",
    size = 50,
    buf_options = {
      ft = "OutlineMenu"
    },
    
  })
  split:mount()
  tree.bufnr = split.bufnr
  tree:render()

  local map_options = { noremap = true, nowait = true }

  split:on("BufEnter", function ()
    print("BufEnter "..split.bufnr)
    tree.bufnr = split.bufnr
    tree:render()
  end, { once = false })

  -- quit
  split:map("n", "q", function()
    split:unmount()
  end, map_options)

  -- Reload
  split:map("n", "R", function()
    -- reload()
  end, map_options)

  -- Interact
  split:map("n", "<CR>", function()
    local node = tree:get_node()
    if node:has_children() then
      if node:is_expanded() then
        node:collapse()
      else
        node:expand()
      end
      tree:render()
    else
      if node.id then
        document.open(node.id, cwin)
        vim.api.nvim_set_current_win(cwin)
      end
    end
  end, map_options)

  -- Create Document
  split:map("n", "a", function()
    local node = tree:get_node()
    if node.type == "document" then
    elseif node.type == "collection" then
      local name = vim.fn.input("Name: ", "")
      if not (name == "") then
        local doc = document.create(name, node.id)
        if doc then
          document.open(doc.id, cwin)
          vim.api.nvim_set_current_win(cwin)
          tree:add_node(
            NuiTree.Node({ text = doc.title:gsub("\n",""), id = doc.id, type = "draft" }),
            node:get_id()
          )
          tree:render()
        else
          print("Create failed.")
        end
      end
    end

    tree:render()
  end, map_options)

  -- Rename
  split:map("n", "r", function()
    local node = tree:get_node()
    if node.type == "document" then
      local name = vim.fn.input("Rename: ", node.text)
      if not (name == "") then
        node.text = document.rename(node.id, name)
      end
    elseif node.type == "collection" then
      local name = vim.fn.input("Rename: ", node.text)
      if not (name == "") then
        local s, col = api.save_collection({ id = node.id, name = name })
        if s < 299 then
          node.text = col.name
        end
      end
    end
    tree:render()
  end, map_options)

  -- Info
  split:map("n", "i", function()
    local node = tree:get_node()
    if node.type == "document" or node.type == "draft" then
      popup.info(node.id)
    elseif node.type == "collection" then
      print(node:get_id())
    end
  end, map_options)

  -- Delete
  split:map("n", "d", function ()
    local node = tree:get_node()
    if node.type == "document" or node.type == "draft" then
      local sure = vim.fn.input("Delete document "..node.text.."? ", "")
      if sure == "y" then
        if document.delete(node.id) then
          tree:remove_node(node:get_id())
          tree:render()
        end
      end
    end
  end, map_options)

  -- Publish
  split:map("n", "p", function()
    local node = tree:get_node()
    if node.type == "document" then
      if document.unpublish(node.id) then
        node.type = "draft"
        tree:render()
      end
    elseif node.type == "draft" then
      if document.publish(node.id) then
        node.type = "document"
        tree:render()
      end
    end
  end, map_options)

  -- expand all nodes
  split:map("n", "L", function()
    local updated = false

    for _, node in pairs(tree.nodes.by_id) do
      updated = node:expand() or updated
    end

    if updated then
      tree:render()
    end
  end, map_options)
  return split
end
