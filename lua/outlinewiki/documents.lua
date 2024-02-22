local util = require "outlinewiki.util"
--@class Documents
---@field _list Document[]
local Documents = {
  _list = {},
}

local api = require("outlinewiki.api")

---Add a Document to the list
---@param doc Document
---@return boolean
function Documents: _add (doc)
  if doc == nil then return false end
  table.insert(self._list, doc)
  return true
end

---Returns a list of Documents
--- Can be cached.
--- If *reload* is true, force the reload from the API
---@param reload? boolean
---@return Document[]
function Documents: list (reload)
  if table.maxn(self._list) == 0 or reload then
    -- Reset the list
    self._list = {}
    -- Get the list
    local list = api.Documents("list", { limit = 100 })
    if list == nil then return {} end
    -- Create the Document objects
    -- Put the Documents in _list
    for _, doc in ipairs(list) do
      local Document = require("outlinewiki.object.document")
      self:_add(Document(doc))
    end
    -- Drafts
    -- Get the list
    local drafts = api.Documents("drafts", { limit = 100 })
    if drafts == nil then return {} end
    -- Create the Document objects
    -- Put the Documents in _list
    for _, doc in ipairs(drafts) do
      local Document = require("outlinewiki.object.document")
      self:_add(Document(doc))
    end
  end
  return self._list
end

---Delete Document **doc**
---@param doc Document
---@return boolean
function Documents: delete(doc)
 local res, err = api.Delete("documents", { id = doc:id() })
  if res then
    for i, d in ipairs(self:list()) do
      if d:id() == doc:id() then
        table.remove(self._list, i)
        return true
      end
    end
    print("Delete: Something went wrong?")
    return true
  else
    print(err)
    return false
  end
end

---List the Documents for Collection **col**
---@param col Collection
---@return table|Document[]
function Documents: list_by_collection(col)
  local list = {}
  for _, doc in ipairs(self:list()) do
    if doc:collection() == col then
      table.insert(list, doc)
    end
  end
  return list
end

---List the Documents for parent **parent**
---@param parentid string
---@return table|Document[]
function Documents: list_by_parentid(parentid)
  local list = {}
  for _, doc in ipairs(self:list()) do
    if doc:is_child() and doc:parent():id() == parentid then
      table.insert(list, doc)
    end
  end
  return list
end

---Returns a completion-table for all Documents
---@return table
function Documents: complete ()
    local list = {}
    for _, doc in ipairs(self:list()) do
      table.insert(list, {
        title = doc:title(),
        url = doc:url(),
      })
    end
  return list
end


---
-- Get specific document

---Get the Document by id **id**
---@param id string
---@return nil|Document
function Documents: get_by_id(id)
  for _, doc in ipairs(self:list()) do
    if doc:id() == id then
      return doc
    end
  end
  return nil
end

---Get the Document by url **url**
---@param url string
---@return nil|Document
function Documents: get_by_url(url)
  for _, doc in ipairs(self:list()) do
    if (doc:url() == url) or (doc.meta.urlId == util.last_split(url, "-")) then
      return doc
    end
  end
  return nil
end

---Get the Document by filename **filename**
---@param filename string
---@return nil|Document
function Documents: get_by_filename(filename)
  for _, doc in ipairs(self:list()) do
    if doc:id() == filename then
      return doc
    end
  end
  return nil
end

function Documents:new ()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end
return Documents
