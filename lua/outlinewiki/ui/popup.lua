local api = require"outlinewiki.api"
local util = require"outlinewiki.util"

local Popup = require("nui.popup")

local M = {}

M.info = function (id)
  local s, doc = api.get_document(id)
  if s > 200 then return nil; end

  doc.text = nil

  local popup = Popup({
    position = "50%",
    size = {
      width = 80,
      height = 30,
    },
    enter = true,
    focusable = true,
    zindex = 50,
    relative = "editor",
    border = {
      padding = {
        top = 0,
        bottom = 0,
        left = 0,
        right = 0,
      },
      style = "rounded",
      text = {
        top = " Document Info ",
        top_align = "center",
        bottom = " q / ESC to close ",
        bottom_align = "left",
      },
    },
    buf_options = {},
    win_options = {
      winblend = 0,
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  })
  popup:on("BufLeave", function()
    popup:unmount()
  end, { once = true })
  popup:map("n", "q", function ()
    popup:unmount()
  end)
  popup:map("n", "<ESC>", function ()
    popup:unmount()
  end)
  popup:mount()

  util.set_buffer(popup.bufnr, vim.inspect(doc), { modifiable = false, ft = "json" })


  -- util.open_buffer(popup.winid, "Info", vim.inspect(doc), {})
end

return M
