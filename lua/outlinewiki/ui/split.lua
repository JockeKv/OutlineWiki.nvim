local Split = require("nui.split")

local popup = require"outlinewiki.ui.popup"

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

  -- Set current buffer as active buffer.
  split:on("BufEnter", function ()
    tree.bufnr = split.bufnr
    tree:render()
  end, { once = false })

  -- quit
  split:map("n", "q", function()
    split:unmount()
  end, map_options)

  -- Reload
  split:map("n", "R", function()
    tree:refresh(true)
  end, map_options)

  -- Interact
  split:map("n", "<Tab>", function()
    local node = tree:get_node()
    if node:has_children() then
      if node:is_expanded() then
        node:collapse()
      else
        node:expand()
      end
      tree:render()
    end
  end, map_options)

  split:map("n", "<CR>", function()
    local node = tree:get_node()
    if node:open(cwin) then
      vim.api.nvim_set_current_win(cwin)
    elseif node:has_children() then
      if node:is_expanded() then
        node:collapse()
      else
        node:expand()
      end
      tree:render()
    end
  end, map_options)

  -- Create Document
  split:map("n", "a", function()
    local node = tree:get_node()
    local name = vim.fn.input("Name: ", "")
    if not (name == "") then
      local doc = node:create(name)
      if doc then
        tree:add_node(doc:as_TreeNode(), node:get_id())
        tree:render()
        if node:open(cwin) then
          vim.api.nvim_set_current_win(cwin)
        end
      else
        print("Could not create Document")
      end
    end
  end, map_options)

  -- Rename
  split:map("n", "r", function()
    local node = tree:get_node()
    local name = vim.fn.input("Rename: ", node:title())
    if not (name == "") then
      if node:rename(name) then
        tree:render()
      end
    end
  end, map_options)

  -- Info
  split:map("n", "i", function()
    local node = tree:get_node()
    if node:type() == "DOC" or node:type() == "DFT" then
      popup.info(node.id)
    elseif node:type() == "COL" then
      print(node:get_id())
    end
  end, map_options)

  -- Delete
  split:map("n", "d", function ()
    local node = tree:get_node()
    if (node:type() == "DOC") or (node:type() == "DFT") then
      local sure = vim.fn.input("Delete document "..node:title().."? ", "")
      if sure == "y" then
        if node:delete() then
          tree:remove_node(node:get_id())
          tree:render()
        end
      end
    end
  end, map_options)

  -- Publish
  split:map("n", "p", function()
    local node = tree:get_node()
    if not node:publish() then
      node:unpublish()
    end
    tree:render()
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
