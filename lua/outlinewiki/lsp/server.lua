local lsp_util = require("outlinewiki.lsp.util")

local server = {
  client_id = nil,
}

function server.register (client_id)
  server.client_id = client_id
  vim.lsp.buf_attach_client(0, server.client_id)
  return server
end

server.start = function(tbl)
  tbl.notify = server.notify
  tbl.request = server.handleRequest
  tbl.is_closing = server.is_closing
  return tbl
end

---Handle LSP Server Request
---@param method string
---@param params table|nil
---@param callback lsp-handler
server.handleRequest = function (method, params, callback)
  -- print("Type: "..vim.inspect(method))
  -- print("Request: "..vim.inspect(request))
  -- print("Callback: "..vim.inspect(callback))
  local ctx = {
    method = method,
    bufnr = vim.api.nvim_get_current_buf(),
    client_id = server.client_id,
  }

  if method == "initialize" then
    callback(nil,{
      capabilities = {
        hoverProvider = true,
        declarationProvider = true,
        definitionProvider = true,
        referencesProvider = true,
      }
    },ctx)
  elseif method == "textDocument/hover" then
    local doc = lsp_util.getCursorDoc()
    if doc then
      callback(nil, {
        contents = doc:LSP_hover(),
      },ctx)
    else
      callback(nil,nil,ctx)
    end
  elseif method == 'textDocument/definition' then
    local doc, header = lsp_util.getCursorDoc()
    if doc then
      if header then
        local pos = lsp_util.getHeaderPos(doc, header)
        if pos then
          callback(nil,{
            uri = "outlinewiki://"..doc:url(),
            range = pos,
          },
          ctx)
          return
        end
      end
      callback(nil,{
        uri = "outlinewiki://"..doc:url(),
        range = {
          [ "start" ] = { line = 0, character = 0 },
          [ "end" ] = { line = 0, character = 0 },
        },
      },
      ctx)
    elseif header then
      doc = lsp_util.getCurrentDoc()
      print(doc and doc:title() or "No doc")
      if not doc then return end
      local pos = lsp_util.getHeaderPos(doc, header)
      if pos then
        callback(nil,{
          uri = "outlinewiki://"..doc:url(),
          range = pos,
        },
        ctx)
        return
      end
    end
  elseif method == 'textDocument/references' then
    local doc = lsp_util.getCursorDoc()
    if doc then
      local backlinks = doc:backlinks()
      if #backlinks > 0 then
        local result = {}
        for _, backlink in ipairs(backlinks) do
          local positions = lsp_util.getLinkPos(doc, backlink)
          if positions then
            for _, pos in ipairs(positions) do
              table.insert(result, {
                uri = "outlinewiki://"..backlink:url(),
                range = pos,
              })
            end
          else
            table.insert(result, {
              uri = "outlinewiki://"..backlink:url(),
              range = {
                [ "start" ] = { line = 0, character = 0 },
                [ "end" ] = { line = 0, character = 0 },
              },
            })
          end
        end
        callback(nil,result,ctx)
      end
    end
  else
    callback(nil,nil,ctx)
  end
end

server.notify = function (notification, a, b, c)
  -- print("Notification: "..vim.inspect(notification))
  -- print("a: "..vim.inspect(a))
  -- print("b: "..vim.inspect(b))
  -- print("c: "..vim.inspect(c))
end

server.is_closing = function ()
  return false
end

return server
