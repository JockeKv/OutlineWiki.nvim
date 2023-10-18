local api = require("outlinewiki.api")

---@alias API_Collection table Collection object returned from the API

local meta_props = {
  "id",
  "collectionId",
  "parentCollectionId",
  "title",
  "urlId",
  "revision",
  "createdAt",
  -- "createdBy",
  "updatedAt",
  -- "updatedBy",
  "publishedAt",
  "archivedAt",
  "deletedAt",
}

---
-- The Class

---@class Collection
---@field meta table Table of metadata of the Collection
---@field bufnr nil|integer The bufnr of the buffer the Collection is loaded into. Otherwise **nil**
local Collection = {
  -- Object props
  __class = "COL",
  __index = nil,

  -- Meta
  meta = {},

  -- Editor
  bufnr = nil,
}


---
-- Property accessors


---Get the Collection id
---@return string
function Collection: id ()
  return self.meta.id
end

---Get the Collection title
---@return string
function Collection: title ()
  return self.meta.title:gsub("\n", "")
end

---The relative URL of the Collection
---@return string
function Collection: url ()
  return "/collection/"..string.lower(self:title()):gsub(" ", "-").."-"..self.meta.urlId
end

---The filename of the Collection buffer in neovim
---Just the url but with '/outline/' added in front
---@return string
function Collection: filename ()
  return "/outline"..self:url()
end


---Returns 'COL' as there is only one type of Collection
---@return string
function Collection: type ()
  return "COL"
end

---
-- API


---Send a request to the API
---@param endpoint string The endpoint to which the request is sent. Typically 'update'
---@param opts table The parameters to send to the API. Is converted to JSON.
---@return boolean Returns **true** on success, otherwise **false**
function Collection:__post (endpoint, opts)
  opts.id = self:id()

  local obj, err = api.Post("collections."..endpoint, opts)
  if not (err == nil) then
    print("Could not update collection: "..err)
    return false
  elseif obj == nil then
    print("Collection returned as nil")
    return false
  end

  for _, prop in ipairs(meta_props) do
    self.meta[prop] = obj[prop]
  end

  return true
end

---
-- Create new instance

---Create new Collection instance
---@param obj API_Collection
---@return Collection
function Collection:new (obj)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  for _, prop in ipairs(meta_props) do
    self.meta[prop] = obj[prop]
  end
  return o
end

return function (obj)
  return Collection:new(obj)
end


