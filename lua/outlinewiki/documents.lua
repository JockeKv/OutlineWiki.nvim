local api = require"outlinewiki.api"
local util = require"outlinewiki.util"

local Documents = {
  _list = {},
}

---Returns a list of Documents
--- Can be cached.
--- If *reload* is true, force the reload from the API
---@param reload? boolean
---@return Document[]
function Documents: list (reload)
  if self._list == {} or reload then
    -- Get the list
    -- Create the Document objects
    -- Put the Documents in _list
  else
    return self._list
  end
  return {}
end

---Create a new Document
--- Returns the Document on success or **nil** on failure
---@param name string
---@param col Collection
---@param opts? table
---@return Document|nil
function Documents: create (name, col, opts)

  return nil
end

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

local M = {
  comp_list = nil,
  home_page = [[
# Home

This is the homepage for outline!
]],
}

---Open Document with id 'id' in window 'win'
---Returns the bufnr of the opened buffer
---Optional: If 'buf' is passes, check if the Document is loaded and open the buffer instead
---@param id DocumentID
---@param win integer
---@param buf? integer
---@return integer|nil
M.open = function (id, win, buf)
  if id == "home" then
    return util.open_buffer(win,"OutlineWikiHome", M.home_page, {filetype = "markdown", buftype = "nofile", modified = false})
  end

  if buf then
    local ok, buf_id = pcall(vim.api.nvim_buf_get_var, buf, "outline_id")
    if ok and (buf_id == id) then
      vim.api.nvim_win_set_buf(win, buf)
      return buf
    end
  end

  local s, doc = api.get_document(id)
  if s > 200 then print(doc); return end

  doc.url = doc.url:gsub('doc', 'outline/doc')
  -- buf = vim.fn.bufadd(doc.url)
  -- vim.fn.bufload(buf)

  buf = util.open_buffer(win,doc.url, doc.text, {filetype = "markdown", buftype = "acwrite", modified = false})
  vim.api.nvim_buf_set_var(buf, "outline_id", doc.id)

  vim.api.nvim_clear_autocmds({event = "BufWriteCmd", buffer = buf})
  vim.api.nvim_create_autocmd({"BufWriteCmd"},{
    buffer = buf,
    desc = "Save OutlineWiki Document",
    callback = function (opts)

      local b = vim.fn.getbufinfo(opts.buf)[1]

      if b.changed > 0 then
        -- print("Saving document "..opts.file.." with id "..b.variables.outline_id)
        local lines = vim.api.nvim_buf_get_lines(opts.buf, 0, -1, false)
        local content = table.concat(lines, "\n")

        if string.len(content) == 0 then print("No content") end

        local status, error = api.save_document({id = b.variables.outline_id, text = content})

        if status == 200 then
          vim.api.nvim_set_option_value("modified", false, {buf = opts.buf})
          print("Document saved!")
        else
          print("Failed to save document, status "..tostring(status)..", "..error)
        end
      else
        print("Unchanged")
      end
    end
  })
  return buf
end

M.complist = function (force)
  if M.comp_list == nil then
    local list = {}
    for _, doc in ipairs(M.list(true)) do
      local title = doc.title:gsub("\n", "")
      local url = "/doc/"..string.lower(title):gsub(" ", "-").."-"..doc.urlId
      table.insert(list, {
        title = title,
        url = url,
      })
    end
    M.comp_list = list
  end
  return M.comp_list
end
---Get all documents
---@param drafts? boolean If true, return drafts as well
---@return nil|List<table>
M.list = function (drafts, force)
  local s, documents = api.get_documents()
  if s > 200 then print(documents); return end

  if drafts then
    local s, drafts = api.get_drafts()
    if s > 200 then print(drafts); return end

    if table.maxn(drafts) > 0 then
      for _, draft in ipairs(drafts) do
        table.insert(documents,draft)
      end
    end
  end

  return documents
end

---Get all drafts
---@return nil|List<table>
M.drafts = function ()
  local s, docs = api.get_drafts()
  if s < 299 then
    return docs
  else
    return nil
  end
end

---Create new Document
---@param name string Name of the Document
---@param collectionid string ID of the collection to list the document under
---@param opts table? Other options
---@return table|nil
M.create = function (name, collectionid, opts)
  local s, doc = api.create_document(name, collectionid)
  if s < 299 then
    return doc
  else
    return nil
  end
end

M.reload = function(buf)
  local id = vim.api.nvim_buf_get_var(buf, "outline_id")
  if id == nil then print("Not a OutlineWiki document."); return false end

  local s, doc = api.get_document(id)
  if s > 200 then print(doc); return false end

  util.set_buffer(buf, doc.text)
  return true
end

M.rename = function(doc, name)
  if name == "" then
    return doc.title
  end

  local status, error = api.save_document( { id=doc, title = name })

  if status == 200 then
    print("Document saved!")
    return name
  else
    print("Failed to save document, status "..tostring(status)..", "..error)
    return doc.title
  end
end

M.add = function(name)
  local doc = name
  return doc
end

M.delete = function(doc)
  local status, error = api.delete_document(doc)

  if status == 200 then
    print("Document deleted!")
    return true
  else
    print("Failed to delete document, status "..tostring(status)..", "..error)
    return false
  end
end

M.history = function(doc)
  return doc
end

M.publish = function (id)
  local status, error = api.save_document({id = id, publish = true})

  if status == 200 then
    print("Document saved!")
    return true
  else
    print("Failed to save document, status "..tostring(status)..", "..error)
    return false
  end
end

M.unpublish = function (id)
  local status, error = api.unpublish_document(id)

  if status == 200 then
    print("Document saved!")
    return true
  else
    print("Failed to save document, status "..tostring(status)..", "..error)
    return false
  end
end

M.star = function (doc)
  return true
end

return M
