local NuiTree = require("nui.tree")

local api = require("outlinewiki.api")
local util = require("outlinewiki.util")

local Collections = require("outlinewiki.collections")
local Documents = require("outlinewiki.documents")

---
-- The Class

---The Metadata for the Document Class.
---@class DocumentMeta
---@field id string
---@field collectionId string
---@field parentDocumentId string
---@field title string
---@field urlId string
---@field tasks table
---@field revision integer
---@field createdAt string
---@field updatedAt string
---@field publishedAt string|vim.NIL
---@field archivedAt string
---@field deletedAt string

---@class Document
---@field meta DocumentMeta
---@field bufnr nil|integer The bufnr of the buffer the Document is loaded into. Otherwise **nil**
local Document = {
  -- Object props
  __class = "DOC",

  -- Meta
  meta = {
    id = "",
    collectionId = "",
    parentDocumentId = "",
    title = "",
    urlId = "",
    tasks = { completed = 0, total = 0 },
    revision = 0,
    createdAt = "",
    -- createdBy = {},
    updatedAt = "",
    -- updatedBy = {},
    publishedAt = vim.NIL,
    archivedAt = "",
    deletedAt = "",
  },

  -- Editor
  bufnr = nil,
}
-- Document.__index = Document

---
-- Property accessors

---Get the Document id
---@return string
function Document:id ()
  return self.meta.id
end

---Get the Document title
---@return string
function Document:title ()
  local title = self.meta.title:gsub("\n", "")
  return title
end

---The relative URL of the Document
---@return string
function Document:url ()
  local url = string.lower(self:title()):gsub(" ", "-")
  local url_encoded = util.urlencode(url)
  return "/doc/"..url_encoded.."-"..self.meta.urlId
end

---The filename of the Document buffer in neovim
---Just the url but with '/outline/' added in front
---@return string
function Document:filename ()
  return "outlinewiki://"..self:url()
end

---@return string
function Document:tasks ()
  local tasks = self.meta.tasks
  if tasks == nil or tasks.total == 0 then return "None" end
  return tasks.completed.."/"..tasks.total
end

---Returns the type of the Document
---  'DOC' for a published Document
---  'DFT' for a non-published Document, or Draft
---@return string
function Document:type ()
  return (self:published() and "DOC") or "DFT"
end

---Returns the Collection the Document belongs to
---@return Collection|nil
function Document:collection ()
  local col = Collections:get_by_id(self.meta.collectionId)
  return col
end

---Return a list of documents referencing this document
---@return Document[]
function Document:backlinks()
  local docs = {}
  local list = api.Documents("list", { limit = 100, backlinkDocumentId = self.meta.id })
  if list == nil then return {} end
  -- Create the Document objects
  -- Put the Documents in _list
  for _, doc in ipairs(list) do
    local Doc = Document
    table.insert(docs,Doc:new(doc))
  end
  return docs
end

---Returns the Parent Document or nil if none.
---@return Document|nil
function Document:parent ()
  if self:is_child() then
    return Documents:get_by_id(self.meta.parentDocumentId)
  end
  return nil
end

---Returns the children Document(s) if any or **nil** if none
---@return Document[]
function Document:children ()
  return Documents:list_by_parentid(self.meta.id)
end

function Document:is_child ()
  return not (self.meta.parentDocumentId == vim.NIL)
end

---
-- General functions

---Create a sub-Document
---@param title string
---@return nil|Document
function Document:create(title)
  local obj = api.Documents("create", {
    title = title,
    collectionId = self.meta.collectionId,
    parentDocumentId = self.meta.id,
  })
  if obj == nil then return nil end
  local doc = Document:new(obj)
  Documents:_add(doc)
  return doc
end

---Get the content of the Document
---@return nil|string
function Document:content()
  return self:__text()
end

---Rename the Document
---@param name string New name
function Document:rename (name)
  return self:__update("update", { title = name })
end

---Check if Document is published
---@return boolean
function Document:published ()
  return not (self.meta.publishedAt == vim.NIL)
end

---Publish Document
---@return boolean
function Document:publish ()
  if self:published() then
    return false
  else
    return self:__update("update",{ publish = true })
  end
end

---Unpublish Document
---@return boolean
function Document:unpublish ()
  if self:published() then
    return self:__update("unpublish", {})
  else
    return false
  end
end

---Delete Document
---@return boolean
function Document:delete ()
  return Documents:delete(self)
end

---
-- Generate other types
---Generate the LSP Hover doc
function Document:LSP_hover ()
  local text = self:title()
  text = text.."\n---\n"
  text = text..((self:collection() and "\nCollection: "..self:collection():title()) or "")
  text = text..((self:parent() and "\nParent document: "..self:parent():title()) or "")
  text = text.."\n---\n"
  text = text.."\nCreated at: "..self.meta.createdAt
  text = text.."\nModified at: "..self.meta.updatedAt
  text = text.."\n---\n"
  text = text.."Tasks: "..self:tasks()
  return {
    kind = "markdown",
    value = text,
  }
end



---Generate the Entity table for Telescope
---@return table
function Document:as_TelescopeNode()
  return {
    title = self:title(),
    collection = self:collection():title(),
    tasks = self:tasks(),
    id = self:id(),
    type = self:type(),
  }
end

---@class DocNode
---@field id string
---@field obj Document

---Return the Document as a node for NuiTree
---@return table
function Document:as_TreeNode ()
  local child_nodes = {}
  for _, child in ipairs(self:children()) do
    table.insert(child_nodes, child:as_TreeNode())
  end
  return NuiTree.Node(
    {
      id    = self:id(),
      obj   = self,
      ---@param s DocNode
      ---@param name string
      rename    = function (s, name) return s.obj:rename(name) end,
      ---@param s DocNode
      ---@param name string
      create    = function (s, name) return s.obj:create(name) end,
      ---@param s DocNode
      ---@param win integer
      open      = function (s, win) return s.obj:open(win) end,
      ---@param s DocNode
      type      = function (s) return s.obj:type() end,
      ---@param s DocNode
      title     = function (s) return s.obj:title() end,
      ---@param s DocNode
      tasks     = function (s) return s.obj:tasks() end,
      ---@param s DocNode
      publish   = function (s) return s.obj:publish() end,
      ---@param s DocNode
      unpublish = function (s) return s.obj:unpublish() end,
      ---@param s DocNode
      delete    = function (s) return s.obj:delete() end,
    },
    child_nodes)
  end

  ---Helper function to recursively generate children TreeNodes
  function Document:__child_TreeNodes ()
    local children = {}
    for _, child in ipairs(self:children()) do
      table.insert(children, child:as_TreeNode())
    end
  end

  ---
  -- Buffer functions
  ---

  ---Open the Document in a buffer
  ---Returns the bufnr on success or **nil** on failure
  ---@param win? integer the id of the window to create the buffer in
  ---@return integer
  function Document:open(win)
    if self.bufnr and vim.fn.bufexists(self.bufnr) then
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_buf(win, self.bufnr)
        return self.bufnr
      end
      return self.bufnr
    end

    -- Create a new buffer
    self.bufnr = util.open_buffer(self:filename(), self:content(), {
      filetype = "outlinewiki",
      buftype = "", -- 'acwrite' breaks Trouble etc. Leave empty (normal file) if possible
      buflisted = true
    })

    vim.api.nvim_clear_autocmds({event = "BufWriteCmd", buffer = self.bufnr})
    vim.api.nvim_create_autocmd({"BufWriteCmd"},{
      buffer = self.bufnr,
      desc = "Save OutlineWiki Document",
      callback = function (opts)
        self:save()
      end,
    })
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_buf(win, self.bufnr)
      return self.bufnr
    end
    return self.bufnr
  end

  ---Reload the current Document
  ---@return boolean
  function Document:reload ()
    if not vim.fn.bufexists(self.bufnr) then
      return false
    end
    local content = self:__text()
    if content == nil then
      return false
    else
      util.set_buffer(self.bufnr, content, {})
      return true
    end
  end

  ---Save the Document
  ---  Returns **true** if successfull, otherwise **false**
  ---@return boolean
  function Document:save ()
    local buf = vim.fn.getbufinfo(self.bufnr)[1]
    if buf.changed > 0 then
      local lines = vim.api.nvim_buf_get_lines(buf.bufnr, 0, -1, false)
      local content = table.concat(lines, "\n")

      if string.len(content) == 0 then print("No content") end

      if self:__update("update",{ text = content }) then
        vim.api.nvim_set_option_value("modified", false, {buf = buf.bufnr})
        print("Document saved!")
        return true
      else
        print("Failed to save document")
        return false
      end
    end
    return false
  end


  ---
  -- API

  ---Send a request to the API
  ---Reset the Document metadata with the data of the response
  ---@param endpoint string The endpoint to which the request is sent. Typically 'update'
  ---@param opts table The parameters to send to the API. Is converted to JSON.
  ---@return boolean Returns **true** on success, otherwise **false**
  function Document:__update (endpoint, opts)
    opts.id = self:id()

    local obj, err = api.Documents(endpoint, opts)
    if not (err == nil) then
      print("Could not update the document: "..err)
      return false
    elseif obj == nil then
      print("Document returned as nil")
      return false
    end

    for prop, _ in pairs(self.meta) do
      self.meta[prop] = obj[prop]
    end

    return true
  end

  ---Retreive the document content
  ---@return nil|string
  function Document:__text()
    local opts = { id = self:id() }

    local obj, err = api.Documents("info", opts)
    if not (err == nil) then
      print("Could not retreive the document: "..err)
      return nil
    elseif obj == nil then
      print("Document returned as nil")
      return nil
    end

    for prop, _ in pairs(self.meta) do
      self.meta[prop] = obj[prop]
    end

    return obj.text
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
    o.meta = {}
    for prop, _ in pairs(self.meta) do
      o.meta[prop] = obj[prop]
    end
    return o
  end

  return function (obj)
    return Document:new(obj)
  end


