local M = {
  base_url = "base_url",
  token = "token",
  lsp = true,
  integrations = {
    telescope = true,
    luasnip = true,
    treesitter = true,
  }
}

M.setup = function (opts)
  local config = vim.tbl_deep_extend("force", M, opts)
  for key, value in pairs(config) do
    M[key] = value
  end

  if M.integrations.telescope then
    require('telescope').load_extension 'outlinewiki'
  end

  return M
end

return M
