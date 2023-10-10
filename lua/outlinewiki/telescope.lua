local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local make_entry = require("telescope.make_entry")

M = {}

M.start = function (opts)
  opts = opts or {}
  opts.find_command = opts.find_command or { "ls" }
  -- make file icon (make_entry.gen_from_file(opts))
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)
  pickers
    .new(opts, {
      prompt_title = "Open Document",
      finder = finders.new_oneshot_job(opts.find_command, opts),
      previewer = conf.file_previewer(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        map("n", "<cr>", (function()
          local selection = action_state.get_selected_entry()
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
