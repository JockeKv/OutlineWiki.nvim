local api = require("outlinewiki.api")

---@alias API_Document table Document object returned from the API

local meta_props = {
  "id",
  "collectionId",
  "parentDocumentId",
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

---@class Document
---@field meta table Table of metadata of the Document
---@field bufnr nil|integer The bufnr of the buffer the Document is loaded into. Otherwise **nil**
local Document = {
  -- Object props
  __class = "DOC",
  __index = nil,

  -- Meta
  meta = {},

  -- Editor
  bufnr = nil,
}

---
-- Property accessors

---Get the Document id
---@return string
function Document: id ()
  return self.meta.id
end

---Get the Document title
---@return string
function Document: title ()
  return self.meta.title:gsub("\n", "")
end

---The relative URL of the Document
---@return string
function Document: url ()
  return "/doc/"..string.lower(self:title()):gsub(" ", "-").."-"..self.meta.urlId
end

---The filename of the Document buffer in neovim
---Just the url but with '/outline/' added in front
---@return string
function Document: filename ()
  return "/outline"..self:url()
end


---Returns the type of the Document
---  'DOC' for a published Document
---  'DFT' for a non-published Document, or Draft
---@return string
function Document: type ()
  return self:is_published() and "DOC" or "DFT"
end

---Returns the Collection the Document belongs to
---@return Collection|nil
function Document: collection ()
  -- TODO: Implement 'collection()'
  return nil
end

---Returns the Parent Document or nil if none.
---@return Document|nil
function Document: parent ()
  -- TODO: Implement 'parent()'
  return nil
end

---Returns the children Document(s) if any or **nil** if none
---@return table<Document>|nil
function Document: children ()
  -- TODO: Implement 'children()'
  return nil
end

---
-- General functions

---Rename the Document
---@param name string New name
function Document:do_rename (name)
  return self:__post("update", { title = name })
end

---Check if Document is published
---@return boolean
function Document:is_published ()
  return not (self.meta.publishedAt == vim.NIL)
end

---Publish Document
---@return boolean
function Document:do_publish ()
  return self:__post("update",{ publish = true })
end

---Unpublish Document
---@return boolean
function Document:do_unpublish ()
  return self:__post("unpublish", {})
end

---
-- Generating the TreeNode

function Document: as_TreeNode ()
  return nil
end

---
-- Opening the Document in a buffer
---

---Open the Document in a buffer
---Returns the bufnr on success or **nil** on failure
---@return integer|nil
function Document:open()
  if vim.fn.bufexists(self.bufnr) then
    -- Check if buffer is valid
    return self.bufnr
  end

  -- Create a new buffer
  local buf = vim.fn.bufadd(self:filename())
  -- Load the buffer
  vim.fn.bufload(buf)
  -- FIXME: Can we make sure that the buffer is okay wihtout loading it into a window?
  -- If possible the Document class should only be responsible for the buffer.
  -- Can we load the buffer into a "hidden" window just to set everything up otherwise?

  -- TODO: Set Autocommands
  --
  -- TODO: Reset undo? 
  ---  Reset undo only on opening a new buffer?
  ---
  -- TODO: Set buffer contents
  --- local undolvl = vim.bo.undolevels
  --- vim.api.nvim_set_option_value("undolevels",-1,{buf = buf})
  --- util.set_buffer(buf,content, opts)
  --- vim.api.nvim_set_option_value("undolevels",undolvl,{buf = buf})
  ---
  -- TODO: Set buffer options
  ---   filetype : "markdown" or "outlinewiki"?
  ---   buftype  : "acwrite"
  ---   listed   : true?
  --- Should be the same for all buffers and stored in this file?

  return self.bufnr
end

---
-- API

---Send a request to the API
---@param endpoint string The endpoint to which the request is sent. Typically 'update'
---@param opts table The parameters to send to the API. Is converted to JSON.
---@return boolean Returns **true** on success, otherwise **false**
function Document:__post (endpoint, opts)
  opts.id = self:id()

  local obj, err = api.Post("document."..endpoint, opts)
  if not (err == nil) then
    print("Could not update document: "..err)
    return false
  elseif obj == nil then
    print("Document returned as nil")
    return false
  end

  for _, prop in ipairs(meta_props) do
    self.meta[prop] = obj[prop]
  end

  return true
end

---
-- Create new instance

---Create new Document instance
---@param obj API_Document
---@return Document
function Document:new (obj)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  for _, prop in ipairs(meta_props) do
    self.meta[prop] = obj[prop]
  end
  return o
end

return function (obj)
  return Document:new(obj)
end


