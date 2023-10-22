local buffer = require("outlinewiki.buffer")


local lspconfigs = require("lspconfig.configs")
lspconfigs.marksman.launch()

local ok, id = pcall(vim.api.nvim_buf_get_var,0, "outline_id")

vim.keymap.set("n", "q", buffer.gotoDoc)

-- Set wrap
vim.opt.wrap = true
-- Tab = 2 spaces
vim.opt.expandtab   = true
vim.opt.tabstop     = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth  = 2

-- Set conceallevel
vim.opt.conceallevel = 2

local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "gj", ":lua vim.lsp.buf.definition()<CR>",{ silent = true, buffer = bufnr })

-- Highlights
vim.api.nvim_set_hl(0, "Headline", {link = "ColorColumn"})
vim.api.nvim_set_hl(0, "CodeBlock", {link = "MsgSeparator"})
vim.api.nvim_set_hl(0, "Qoute", {link = "TodoBgFIX"})
vim.api.nvim_set_hl(0, "Dash", {link = "Boolean"})
vim.api.nvim_set_hl(0, "Doubledash", {link = "Exception"})
vim.api.nvim_set_hl(0, "@text.literal.markdown_inline", {link = "CursorLine"})

-- Attempt to get some inline syntax highlights working
-- vim.treesitter.query.set("markdown_inline", "highlights", [[
--     (inline 
--       (strikethrough) @Comment)
--     (inline 
--       (strikethrough
--         (emphasis_delimiter) @Conceal
--         (#set! conceal "")))
--
--     ;(inline
--     ;  (block_continuation) @Character
--     ;  (#set! conceal "┃"))
-- ]])

-- Conceal and Highlights Query
vim.treesitter.query.set("markdown", "highlights", [[
  (fenced_code_block
    (fenced_code_block_delimiter) @conceal
    (#set! conceal ""))
  (fenced_code_block
    (info_string (language) @comment))

  ;(latex_block
  ;  (latex_span_delimiter) @conceal
  ;  (#set! conceal "L"))

  ;(code_span
  ; (code_span_delimiter) @Character
  ; (#set! conceal "'"))

  (atx_heading
    (atx_h1_marker) @Boolean
    (#set! conceal "󰉫 ")
    (inline) @Boolean)
  (atx_heading
    (atx_h2_marker) @Boolean
    (#set! conceal "󰉬 ")
    (inline) @Boolean)
  (atx_heading
    (atx_h3_marker) @Boolean
    (#set! conceal "󰉭 "))
  (atx_heading
    (atx_h4_marker) @Boolean
    (#set! conceal "󰉮 "))
  (atx_heading
    (atx_h5_marker) @Boolean
    (#set! conceal "󰉯 "))

  (setext_heading) @Boolean
  (setext_heading
    (setext_h1_underline) @Debug)
  (setext_heading
    (setext_h2_underline) @Debug)

  (list_item
    (list_marker_minus) @Keyword)
    ;(#set! conceal ""))
  (list_item
    (list_marker_star) @Keyword)
    ;(#set! conceal ""))
  (list_item
    (list_marker_dot) @Keyword)

  (list_item
    (task_list_marker_unchecked) @conceal
    (#set! conceal ""))
  (list_item
    (task_list_marker_checked) @conceal
    (#set! conceal ""))

  ; Block Qoute
  (block_quote
    (block_quote_marker) @Character
    (#set! conceal "┃"))
  ; Continue after blank qoute line
  (block_quote
    (block_continuation) @Character
    (#set! conceal "┃"))
  ; Continue qoute
  (block_quote
    (paragraph (block_continuation) @Character)
    (#set! conceal "┃"))
  ; Qoute with list
  (block_quote
    (list (list_item(paragraph(block_continuation) @Character)))
    (#set! conceal "┃"))
  (block_quote
    (list (list_item(paragraph(inline(block_continuation) @Character))))
    (#set! conceal "┃"))
  (block_quote
    (paragraph (inline (block_continuation) @Character))
    (#set! conceal "┃"))
]])

local augroup = vim.api.nvim_create_augroup('outlinewiki', {})
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*.md',
  group = augroup,
  callback = function()
    -- vim.api.nvim_set_hl(0, 'Conceal', { bg = 'NONE', fg = '#00cf37' })
    vim.api.nvim_set_hl(0, 'todoCheckbox', { link = '@punctuation.delimiter.markdown_inline' })
    -- vim.bo.conceallevel = 1

    -- vim.cmd [[
    --     syn match todoCheckbox '\v(\s+)?(-|\*)\s\[\s\]'hs=e-4 conceal cchar=
    --     syn match todoCheckbox '\v(\s+)?(-|\*)\s\[x\]'hs=e-4 conceal cchar=
    -- ]]
  end
})

vim.cmd [[
  augroup Headlines
  autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,WinScrolled * lua HighlightBlocks()
  augroup END
]]

local q = require "vim.treesitter.query"

local nvim_buf_set_extmark = function(...)
    pcall(vim.api.nvim_buf_set_extmark, ...)
end

local parse_query_save = function(query)
    local ok, parsed_query =
        pcall(vim.treesitter.query.parse, "markdown", query)
    if not ok then
        return nil
    end
    return parsed_query
end

local M = {
  namespace = vim.api.nvim_create_namespace "headlines_namespace",
  query = parse_query_save([[
                (atx_heading [
                    (atx_h1_marker)
                    (atx_h2_marker)
                    (atx_h3_marker)
                    (atx_h4_marker)
                    (atx_h5_marker)
                    (atx_h6_marker)
                ] @headline)

                (thematic_break) @dash

                (fenced_code_block) @codeblock

                ;(latex_block) @codeblock

                (block_quote_marker) @quote
                (block_quote (paragraph (inline (block_continuation) @quote)))

  ]]),
  headline_highlights = { "Headline" },
  codeblock_highlight = "CodeBlock",
  codetitle_highlight = "CodeTitle",
  dash_highlight = "Dash",
  dash_string = "",
  quote_highlight = "Quote",
  quote_string = "┃",
}

HighlightBlocks = function ()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(0, M.namespace, 0, -1)
    if not M.query then
        return
    end

    local language_tree = vim.treesitter.get_parser(bufnr, "markdown")
    local syntax_tree = language_tree:parse()
    local root = syntax_tree[1]:root()
    local win_view = vim.fn.winsaveview()
    local left_offset = win_view.leftcol
    local width = vim.api.nvim_win_get_width(0)
    local last_fat_headline = -1

    for _, match, metadata in M.query:iter_matches(root, bufnr) do
        for id, node in pairs(match) do
            local capture = M.query.captures[id]
            local start_row, start_column, end_row, _ =
                unpack(vim.tbl_extend("force", { node:range() }, (metadata[id] or {}).range or {}))

            -- if capture == "headline" and M.headline_highlights then
            --     local get_text_function = vim.treesitter.get_node_text(node, bufnr)
            --     local level = #vim.trim(get_text_function)
            --     local hl_group = M.headline_highlights[math.min(level, #M.headline_highlights)]
            --     nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
            --         end_col = 0,
            --         end_row = start_row + 1,
            --         hl_group = hl_group,
            --         hl_eol = true,
            --     })
            -- end

            if capture == "dash" and M.dash_highlight and M.dash_string then
                nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
                    virt_text = { { M.dash_string:rep(width), M.dash_highlight } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine",
                })
            end

            if capture == "codeblock" and M.codeblock_highlight then
                nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
                    end_col = 0,
                    end_row = end_row,
                    hl_group = M.codeblock_highlight,
                    hl_eol = true,
                })

                local start_line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
                local _, padding = start_line:find "^ +"
                local codeblock_padding = math.max((padding or 0) - left_offset, 0)

                if codeblock_padding > 0 then
                    for i = start_row, end_row do
                        nvim_buf_set_extmark(bufnr, M.namespace, i, 0, {
                            virt_text = { { string.rep(" ", codeblock_padding), "Normal" } },
                            virt_text_win_col = 0,
                            priority = 1,
                        })
                    end
                end
            end

            -- if capture == "quote" and M.quote_highlight and M.quote_string then
            --     nvim_buf_set_extmark(bufnr, M.namespace, start_row, start_column, {
            --         virt_text = { { M.quote_string, M.quote_highlight } },
            --         virt_text_pos = "overlay",
            --         hl_mode = "combine",
            --     })
            -- end
        end
    end
end

