# OutlineWiki

> Currently a Work-in-progress

A plugin for Neovim to use [Outline](https://getoutline.com) as a personal Wiki.

## Requirements

### Plenary.nvim

[Link](https://github.com/nvim-lua/plenary.nvim)

Outlinewiki uses the curl module from Plenary.nvim to make all the api calls

### Nui

[Link](https://github.com/MunifTanjim/nui.nvim)

Outlinewiki uses NUI to create windows, popups etc

## Optional

### Treesitter

> Active with 'integrations.treesitter = true' (default)

Outlinewiki uses treesitters markdown syntax.
Treesitter is also used for the "LSP".

### Telescope

> Active with 'integrations.telescope = true' (default)

OutlineWiki comes with a telescope integration for opening documents.
Open with ':Telescope outlinewiki' or ':OutlineWiki telescope'

### LuaSnip

> Active with 'integrations.luasnip = true' (default)

OutlineWiki ships some LuaSnip snippets for 
:::Info/Warn/Error which is valid in Outline but not all markdown

The "LSP" also uses LuaSnip to generate links to other Outline documents

## Installation

**Lazy:**
```lua
{
  "JockeKv/OutlineWiki.nvim",
  dependencies = {
    'nvim-lua/plenary.nvim', -- Required
    'MunifTanjim/nui.nvim', -- Required
    'nvim-telescope/telescope.nvim', -- Optional
    'nvim-treesitter/nvim-treesitter', -- Optional
    'L3MON4D3/LuaSnip', -- Optional
  },
  opts = {
    base_url = "base_url", -- URL to Outline eg. https://outline.example.com
    token = "token", -- Your access token
    lsp = true, -- Enable the build-in "LSP-server"
    integrations = {
      telescope = true,
      luasnip = true,
      treesitter = true,
    }
  },
}
```
