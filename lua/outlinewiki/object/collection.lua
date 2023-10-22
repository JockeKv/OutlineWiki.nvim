local NuiTree = require("nui.tree")
local api = require("outlinewiki.api")

local Documents = require("outlinewiki.documents")

---
-- The Class

---The Metadata for the Collection Class.
---@class CollectionMeta
---@field id string
---@field name string
---@field description string
---@field index string
---@field color string
---@field icon string
---@field permission string
---@field createdAt string
---@field updatedAt string
---@field deletedAt string

---@class Collection
---@field meta CollectionMeta
---@field bufnr nil|integer The bufnr of the buffer the Collection is loaded into. Otherwise **nil**
local Collection = {
  -- Object props
  __class = "DOC",

  -- Meta
  meta = {
    id = "",
    name = "",
    description = "",
    index = "",
    color = "",
    icon = "",
    permission = "",
    createdAt = "",
    updatedAt = "",
    deletedAt = "",
  },

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
  local title = self.meta.name:gsub("\n", "")
  return title
end

---Returns 'COL'
---@return string
function Collection: type ()
  return "COL"
end

---Returns the children Document(s) if any or **nil** if none
---@return Document[]
function Collection: documents ()
  return Documents:list_by_collection(self)
end

---
-- General functions

---Create a sub-Document
---@param title string
---@return nil|Document
function Collection: create(title)
  local Document = require("outlinewiki.object.document")
  local obj = api.Documents("create", {
    title = title,
    collectionId = self.meta.id,
  })
  if obj == nil then return nil end
  local doc = Document(obj)
  Documents:_add(doc)
  return doc
end

---Rename the Collection
---@param name string New name
function Collection:rename (name)
  return self:__update("update", { name = name })
end

---
-- Generating the TreeNode

function Collection: as_TreeNode ()
  local doc_nodes = {}
  for _, doc in ipairs(self:documents()) do
    if not doc:is_child() then
      table.insert(doc_nodes, doc:as_TreeNode())
    end
  end
  return NuiTree.Node(
    {
      id    = self:id(),
      obj   = self,
      rename    = function (s, name) return s.obj:rename(name) end,
      create    = function (s, name) return s.obj:create(name) end,
      open      = function (_, _) return false end,
      type      = function (s) return s.obj:type() end,
      title     = function (s) return s.obj:title() end,
      tasks     = function (_) return "None" end,
      publish   = function (_) return false end,
      unpublish = function (_) return false end,
      delete    = function (_) return false end,
    },
    doc_nodes)
end

---
-- API

---Send a request to the API
---Reset the Collection metadata with the data of the response
---@param endpoint string The endpoint to which the request is sent. Typically 'update'
---@param opts table The parameters to send to the API. Is converted to JSON.
---@return boolean Returns **true** on success, otherwise **false**
function Collection:__update (endpoint, opts)
  opts.id = self:id()

  local obj, err = api.Collections(endpoint, opts)
  if not (err == nil) then
    print("Could not update the Collection: "..err)
    return false
  elseif obj == nil then
    print("Collection returned as nil")
    return false
  end

  for prop, _ in pairs(self.meta) do
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
  o.meta = {}
  for prop, _ in pairs(self.meta) do
    o.meta[prop] = obj[prop]
  end
  return o
end

return function (obj)
  return Collection:new(obj)
end

