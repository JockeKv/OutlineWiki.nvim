local lsp_server = require("outlinewiki.lsp.server")

local lsp = {}

lsp.config = {
  name = "OutlineWiki",
  root_dir = "/outline/",
  on_init = nil,
  on_exit = nil,
  cmd = lsp_server.start,
  filetypes = {'outlinewiki'},
  flags = { debounce_text_changes = nil },
  on_attach = function (client)
  end
}

lsp_server.register(vim.lsp.start_client(lsp.config))

vim.api.nvim_create_autocmd("FileType", {
  pattern = "outlinewiki",
  callback = function(opt)
    vim.lsp.buf_attach_client(opt.buf, lsp_server.client_id)
  end,
  desc = "Start OutlineWiki LSP",
})

return lsp
