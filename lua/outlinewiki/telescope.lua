local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")

local document = require("outlinewiki.document")
local tree = require("outlinewiki.ui.tree")

M = {}

---
--- Node parsing

local function get_parent(node)
  return tree.nodes.by_id[node._parent_id]
end

local function get_node(id)
  return tree.nodes.by_id[id]
end

local function get_children(node)
  if not node:has_children() then return {} end
  local children = {}
  for _, id in ipairs(node:get_child_ids()) do
    table.insert(children, get_node(id))
  end
end

local function get_documents(draft)
  local docs = {}
  for k, node in pairs(tree.nodes.by_id) do
    if (node.type == "document") or (draft and node.type == "draft") then
      table.insert(docs,  {
        title = node.text,
        collection = get_parent(node).text,
        tasks = node.tasks or { completed = 0, total = 0 },
        id = node.id,
        type = (node.type == "document" and "DOC") or (node.type == "draft" and "DFT")
      })
    end
  end
  return docs
end

---
--- Entries

local document_display = entry_display.create {
  separator = " ",
  items = {
    { width = 3 },
    { width = 5 },
    { width = 10 },
    { remaining = true },
  },
}

local function document_entry (entry, opts)
  return {
    value = entry.id,
    ordinal = entry.title,
    entry = entry,
    display = function (e)
      return document_display {
        { e.entry.type, "TelescopeResultsNumber" },
        { e.entry.tasks.completed.."/"..e.entry.tasks.total, "TelescopeResultsComment" },
        { e.entry.collection, "Boolean" },
        e.entry.title,
      }
      end,
  }
end

---
--- Telescope lists
--- vim.api.nvim_buf_attach ??
--- vim.api.nvim_put

M.open = function (opts)
  opts = opts or {}
  opts.find_command = opts.find_command or { "ls" }
  -- make file icon (make_entry.gen_from_file(opts))
  opts.entry_maker = make_entry
  opts.win = vim.api.nvim_get_current_win()
  pickers
    .new(opts, {
      prompt_title = "Open Document",
      finder = finders.new_table{ results = get_documents(true), entry_maker = document_entry },
      -- previewer = conf.file_previewer(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          print(vim.inspect(selection))
          document.open(selection.value, opts.win)
        end)
        map("n", "<cr>", (function()
          local selection = action_state.get_selected_entry()
          print(vim.inspect(opts))
          print(vim.inspect(selection))
          return selection
        end))
        map("n", "d", (function()
          local selection = action_state.get_selected_entry()
          return selection
        end))
        return true
      end,
    })
    :find()
end

return M
