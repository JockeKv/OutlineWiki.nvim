---@class Collections
---@field __list Collection[]
local Collections = {
  __list = {},
}

local api = require("outlinewiki.api")
local Collection = require("outlinewiki.object.collection")

---Add a Collection to the list
---@param col Collection
---@return boolean
function Collections: __add (col)
  if col == nil then return false end
  table.insert(self.__list, col)
  return true
end

---Returns a list of Collections
--- Can be cached.
--- If *reload* is true, force the reload from the API
---@param reload? boolean
---@return Collection[]
function Collections: list (reload)
  if table.maxn(self.__list) == 0 or reload then
    self.__list = {}
    -- Get the list
    local list = api.Collections("list", { limit = 100 })
    if list == nil then return {} end
    -- Create the Collection objects
    -- Put the Collections in _list
    for _, doc in ipairs(list) do
      self:__add(Collection(doc))
    end
  end
  return self.__list
end

---
-- Get specific document

---Get the Collection by id **id**
---@param id string
---@return nil|Collection
function Collections: get_by_id(id)
  for _, col in ipairs(self:list()) do
    if col:id() == id then
      return col
    end
  end
  return nil
end

return Collections
