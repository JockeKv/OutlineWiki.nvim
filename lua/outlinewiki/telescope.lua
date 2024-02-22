local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")

local Documents = require("outlinewiki.documents")

M = {}

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

local function document_entry (entry)
  -- TODO: Attach functions to the Entry so it can be updated
  return {
    value = entry:id(),
    ordinal = entry:collection():title().."/"..entry:title(),
    obj = entry,
    display = function (e)
      local obj = e.obj
      return document_display {
        { obj:type(), "TelescopeResultsNumber" },
        { obj:tasks(), "TelescopeResultsComment" },
        { obj:collection():title(), "Boolean" },
        -- { "Col", "Boolean" },
        obj:title(),
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
      finder = finders.new_table{ results = Documents:list(), entry_maker = document_entry },
      -- previewer = conf.file_previewer(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          selection.obj:open(opts.win)
        end)
        map("n", "<cr>", (function()
          local selection = action_state.get_selected_entry()
          print(vim.inspect(opts))
          print(vim.inspect(selection))
          return selection
        end))
        -- TODO: This works but the changes are not reflected in the picker.
        --       The code needs some cleanup as well
        -- map("n", "p", (function()
        --   local selection = action_state.get_selected_entry()
        --   if selection.obj:type() == "DOC" then
        --     selection.obj:unpublish()
        --   elseif selection.obj:type() == "DFT" then
        --     selection.obj:publish()
        --   end
        --   return selection
        -- end))
        return true
      end,
    })
    :find()
end

return M
