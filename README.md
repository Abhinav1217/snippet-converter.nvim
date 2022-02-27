<div align="center">

# snippet-converter.nvim

Neovim plugin to parse, transform and convert snippets. Supports a variety of formats and snippet engines.

[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

</div>

> :warning: This plugin is still in development and not currently usable. Stay tuned!

## Primary objectives
- Decouple the functionality of user's snippets from the concrete syntax or snippet engine.
- Facilitate and encourage creation and sharing of snippet collections.

## Use cases
There are several cases where this plugin comes in handy:

- You are **switching to a new snippet engine** but don't want to lose your
  hand-crafted snippets:\
  Simply let SnippetConverter convert them to your desired output format.
- You are using a collection of predefined snippets such as [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) or
  [vim-snipmate](https://github.com/honza/vim-snippets), however there is that **one snippet
  that always gets in your way:**\
  Instead of maintaining your own fork of the snippet collection, simply remove or modify the snippet with a few lines of Lua code.
- You are a **plugin author** and don't want to reinvent the wheel by writing your own parsers:\
  SnippetConverter generates a standardized (format-agnostic) AST from your snippet definitions. Feel free to integrate SnippetConverter with your plugin!

Other reasons may include:
- You **dislike the snippets format** your snippet engine supports:\
  In that case, simply write the snippet in a nicer format (in my opinion, VSCode snippets are quite
  awkward to write in JSON, why not write them in UltiSnips format and convert them afterwards?).
- You want to **validate the syntax** of your snippets:\
  SnippetConverter includes a graphical UI that will show you exactly where and why your snippet
  could not be parsed. You can even send the errors to the quickfix list and step through them one by one!

### Supported snippet engines
SnippetConverter can convert snippets between the following formats:
- [VSCode](https://code.visualstudio.com/docs/editor/userdefinedsnippets) (supported by [vim-vsnip](https://github.com/hrsh7th/vim-vsnip), [LuaSnip](https://github.com/L3MON4D3/LuaSnip))
- [UltiSnips](https://github.com/SirVer/ultisnips)
- [SnipMate](https://github.com/garbas/vim-snipmate)

Support for the following formats is planned for future versions:
- Native [LuaSnip](https://github.com/L3MON4D3/LuaSnip) (the snippets will be defined in Lua code)
- [neosnippet.vim](https://github.com/Shougo/neosnippet.vim)

Is there any other snippet engine or custom format that you think should be supported? Let me know by creating an issue!

## Getting started

To get started, pass a Lua table with a list of templates to the `setup` function. A template must contain
`sources` (the formats and paths of your input snippets) and `output` tables (the target formats and paths).

Here's an example to convert a set of UltiSnips and SnipMate snippets to the VSCode snippets format (using packer.nvim):

```lua
use {
  "smjonas/snippet-converter.nvim",
  config = function()
    local template = {
      -- name = "My UltiSnips to VSCode template", (optionally give your template a name to refer to it in the transform stage)
      sources = {
        ultisnips = {
          -- Add snippets from (plugin) folders or individual files on your runtimepath...
          "vim-snippets/UltiSnips",
          "latex-snippets/tex.snippets",
          -- ...or use absolute paths on your system.
          vim.fn.stdpath("config") .. "/UltiSnips",
        },
        snipmate = {
          "vim-snippets/snippets",
        },
      },
      output = {
        vscode = vim.fn.stdpath("data") .. "/vscode_snippets",
      },
    }

    require("snippet_converter").setup {
      templates = { template },
      -- settings = {}, (to change the default settings, see configuration section)
    }
  end
}
```
Then simply run the command `:ConvertSnippets` to convert all snippets to your specified
output locations and formats.

## Documentation

For detailed instructions on customization, check out the
[documentation](docs/DOCUMENTATION.md).

## Acknowledgements
I want to thank [@williamboman](https://github.com/williamboman) for his plugin [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer) - his code inspired me tremendously while designing the UI for this plugin and helped me to get started with Neovim's window API.
