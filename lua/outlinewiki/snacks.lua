local Documents = require("outlinewiki.documents")
local Snacks = require("snacks")

local M = {}

M.picker = function ()
  return Snacks.picker({
    title = "OutlieneWiki",
    -- format = "text",
    -- items = Documents:list(),
    -- ---@param item Document
    format = function(item)
      local ret = {}
      ret[#ret + 1] = { item.collection, 'SnacksPickerIconObject' }
      ret[#ret + 1] = { string.rep(" ", 20 - #item.collection), virtual = true }
      ret[#ret + 1] = { item.title, 'SnacksPickerLabel' }
      return ret
    end,
    ---@param item Document
    ---@param picker snacks.Picker
    -- confirm = function(picker, item)
      --   picker:close()
      --   item:open()
      -- end,
      ---@snacks.picker.Filter
      filter = {

      },
      finder = function(opts, ctx)
        return vim.iter(
          Documents:list()
          ---@param doc Document
        ):map(function(doc)
          local doctitle = doc:title()
          local coltitle = doc:collection():title()
          return {
            title = doctitle,
            collection = coltitle,
            text = coltitle..doctitle,
            file = "outlinewiki://"..doc:url(),
            -- open = function ()
              --     doc:open()
              -- end
            }
          end):totable()
        end,
      })
    end

    return M
