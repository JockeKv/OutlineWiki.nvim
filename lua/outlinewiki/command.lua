local ui = require("outlinewiki.ui")
local document = require("outlinewiki.document")

local M = {
  commands = {
    cmd = function ()
      require("noice").redirect(vim.fn.getcmdline())
    end,
    menu = ui.open,
    menu_tab = ui.tab_open,
    open = function (opts)
    end,

  },
  open = function ()
  end,
}

M.list_commands = function ()
  local cmd = {}
  for key, _ in pairs(M.commands) do
    table.insert(cmd, key)
  end
  return cmd
end

M.run = function (opts)
--  print(vim.inspect(opts))
  if M.commands[opts.fargs[1]] then
    M.commands[opts.fargs[1]](opts)
  end
end

M.complete = function (_, line)
  local l = vim.split(line, "%s+")
  local n = #l - 2

  if n == 0 then
    local commands = M.list_commands()
    table.sort(commands)

    return vim.tbl_filter(function(val)
      return vim.startswith(val, l[2])
    end, commands)
  end
end

return M
