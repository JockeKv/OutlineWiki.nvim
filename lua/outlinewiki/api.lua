---@alias DocumentID string The ID of a Document
---@alias CollectionID string The ID of a Collection
---@alias Error string An error message
---@alias Status integer The HTTP statuscode of a request

local curl = require "plenary.curl"
local config = require"outlinewiki.config"

local api = {}

---Golang-like POST function.
---@param endpoint string
---@param opts table
---@return nil|table Result
---@return nil|string Error
api.Post = function (endpoint, opts)
  local body = vim.fn.json_encode(opts)
  local baseurl = config.base_url.."/api/"
  local res = curl.post(baseurl..endpoint, {
    body = body,
    headers = {
      content_type  = "application/json",
      authorization = "Bearer "..config.token
    }
  })
  local ret = vim.fn.json_decode(res.body)
  if ret.status == 200 then
    return ret.data, nil
  else
    return nil, ret.error..": "..ret.message
  end
end

---POST function for Documents endpoint
---@param endpoint string
---@param opts table
---@return nil|API_Document|API_Document[]
api.Documents = function (endpoint, opts)
  return api.Post("documents."..endpoint, opts)
end


---POST function for Collections endpoint
---@param endpoint string
---@param opts table
---@return nil|API_Collection|API_Collection[]
api.Collections = function (endpoint, opts)
  return api.Post("collections."..endpoint, opts)
end

---Delete a respurce of type **type**
---@param type string
---@param opts table
---@return boolean
---@return nil|string
api.Delete = function (type, opts)
  local body = vim.fn.json_encode(opts)
  local baseurl = config.base_url.."/api/"
  local res = curl.post(baseurl..type..".delete", {
    body = body,
    headers = {
      content_type  = "application/json",
      authorization = "Bearer "..config.token
    }
  })
  local ret = vim.fn.json_decode(res.body)
  if ret.status == 200 then
    return true, nil
  else
    return false, ret.error..": "..ret.message
  end
end

local function post(endpoint, body)
  local baseurl = config.base_url.."/api/"
  local res = curl.post(baseurl..endpoint, {
    body = body,
    headers = {
      content_type  = "application/json",
      authorization = "Bearer "..config.token
    }
  })
  local ret = vim.fn.json_decode(res.body)
  if ret.status == 200 then
    return ret.status, ret.data
  else
    print(ret.status, ret.error..": "..ret.message)
    return ret.status, ret.error..": "..ret.message
  end
end

---Get Document Info and Text
---@param id DocumentID
---@return integer, Document|Error
api.get_document = function (id)
  local body = vim.fn.json_encode({ id = id })
  return post("documents.info", body)
end

return api
