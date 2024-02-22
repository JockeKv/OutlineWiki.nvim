local util = {}

local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

---Convert to urlencoded string
---@param url string
---@return string|nil
util.urlencode = function (url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

util.docs_for_col = function (col, docs)
  local r = {}
  for _, d in ipairs(docs) do
    if d.collectionId == col.id then
      table.insert(r, d)
    end
  end
  return r
end

util.set_buffer = function (buf, content, opts)
  local text_obj = util.split(content,"\n")
  vim.api.nvim_buf_set_lines(buf,0,-1,false, text_obj)
  vim.api.nvim_set_option_value("modified", false, {buf = buf})

  for k, v in pairs(opts) do
    vim.api.nvim_set_option_value(k,v, {buf = buf})
  end
end

---Open a buffer and set the name. content and buffer options according to parameters
---@param win window
---@param name string
---@param content string
---@param opts table
---@return buffer
util.open_buffer = function(win, name, content, opts)
  local buf = vim.fn.bufadd(name) --[[@as integer]] -- To remove warnings

  local undolvl = vim.bo.undolevels
  vim.api.nvim_set_option_value("undolevels",-1,{ buf = buf })
  vim.api.nvim_win_set_buf(win, buf)
  util.set_buffer(buf,content, opts)
  vim.api.nvim_set_option_value("undolevels",undolvl,{buf = buf})

  return buf
end


util.gsplit = function (text, pattern, plain)
  local splitStart, length = 1, #text
  return function ()
    if splitStart then
      local sepStart, sepEnd = string.find(text, pattern, splitStart, plain)
      local ret
      if not sepStart then
        ret = string.sub(text, splitStart)
        splitStart = nil
      elseif sepEnd < sepStart then
        -- Empty separator!
        ret = string.sub(text, splitStart, sepStart)
        if sepStart < length then
          splitStart = sepStart + 1
        else
          splitStart = nil
        end
      else
        ret = sepStart > splitStart and string.sub(text, splitStart, sepStart - 1) or ''
        splitStart = sepEnd + 1
      end
      return ret
    end
  end
end

util.split = function (text, pattern, plain)
  local ret = {}
  for match in util.gsplit(text, pattern, plain) do
    table.insert(ret, match)
  end
  return ret
end

util.last_split = function (s, pat)
  local split = util.split(s,pat)
  return split[#split]
end


return util
