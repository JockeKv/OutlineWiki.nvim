local M = {
  base_url = "base_url",
  token = "token",
}

M.setup = function (opts)
  local config = vim.tbl_deep_extend("force", M, opts)
  for key, value in pairs(config) do
    M[key] = value
  end
  return M
end

return M
