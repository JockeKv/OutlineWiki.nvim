local api = require("outlinewiki.api")

local M = {}

M.list = function ()
  local s, collections = api.get_collections()
  if s > 200 then print(collections); return end

  return collections
end

return M
