local util = {}
-- local function split(str, sep)
--    local result = {}
--    local regex = ("([^%s]+)"):format(sep)
--    for each in str:gmatch(regex) do
--       table.insert(result, each)
--    end
--    return result
-- end
--


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

util.open_buffer = function(win, name, content, opts)
  local buf = vim.fn.bufadd(name)
  
  local undolvl = vim.bo.undolevels
  vim.api.nvim_set_option_value("undolevels",-1,{buf = buf})
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

return util
