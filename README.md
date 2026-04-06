# 🌀 wayback.nvim

Browse and open the current file at any previous commit, without detaching HEAD. Supports multiple picker backends: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), [fzf-lua](https://github.com/ibhagwan/fzf-lua), and [snacks.nvim](https://github.com/folke/snacks.nvim).

## ✨ Features

- Open file at any commit in current buffer, split, vsplit, or tab
- Preview file contents at the selected commit
- Handles file renames/moves via `git log --follow`
- Open file at commit in your web browser (supports GitHub, GitLab, Bitbucket, Azure DevOps)
- Copy commit hash to clipboard
- Auto-detects your installed picker, or configure explicitly
- Opens as [vim-fugitive](https://github.com/tpope/vim-fugitive) objects when available (enabling `:Gblame`, etc.)

### What is the difference between this and `buffer commits`?

Some pickers such as Telescope include the functionality to view buffer commits via `:Telecope b_commits`. This plugin differs in a few ways:

- **Purpose**: Opens the file at a previous version without affecting your git state. `git_bcommits` checks out the entire repo.
- **Moved files**: Handles renamed/moved files correctly.
- **Preview**: Shows file contents at the commit, not the diff.

## 🔩 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "piersolenski/wayback.nvim",
  dependencies = {
    -- Optional
    { "tpope/vim-fugitive" },
  },
  opts = {},
  keys = {
    {
      "<leader>gw",
      function()
        require("wayback").open()
      end,
      desc = "Wayback",
    },
  },
}
```

#### Optional dependencies

- **[vim-fugitive](https://github.com/tpope/vim-fugitive)** - When installed, files open as fugitive objects instead of read-only scratch buffers. This means you get full fugitive integration (`:Gblame`, `:Gdiffsplit`, etc.) on historical file versions.

## ⚙️ Configuration

```lua
require("wayback").setup({
  -- "auto", "telescope", "fzf_lua", or "snacks"
  picker = "auto",

  -- Browser command for the open-in-browser action (nil = auto-detect)
  browser_command = nil,

  -- Force a specific forge for browser URLs (nil = auto-detect from remote URL)
  -- Options: "github", "gitlab", "bitbucket", "azure_devops"
  forge = nil,

  -- Additional telescope-specific mappings (only applies to telescope backend)
  mappings = {
    i = {},
    n = {},
  },
})
```

### Browser support

The open-in-browser action auto-detects your forge from the remote URL hostname:

| Forge        | Detection                                          |
| ------------ | -------------------------------------------------- |
| GitHub       | Default fallback                                   |
| GitLab       | URL contains `gitlab`                              |
| Bitbucket    | URL contains `bitbucket`                           |
| Azure DevOps | URL contains `dev.azure.com` or `visualstudio.com` |

For self-hosted instances with non-standard hostnames, set `forge` explicitly in your config.

### Telescope extension (optional)

If you prefer the `:Telescope wayback` command, load the extension:

```lua
require("telescope").load_extension("wayback")
```

This always uses the Telescope picker regardless of your `picker` setting.

## 🚀 Usage

```vim
:Wayback
```

Or for a specific file:

```vim
:Wayback path/to/file.lua
```

Or from Lua:

```lua
require("wayback").open() -- current file
require("wayback").open("path/to/file.lua") -- specific file
```

Or via Telescope:

```vim
:Telescope wayback
```

## ⌨️ Keymaps

The following keymaps are available from inside the picker:

| Keymap  | Action                                  |
| ------- | --------------------------------------- |
| `<CR>`  | Open file at commit in current buffer   |
| `<C-v>` | Open file at commit in vertical split   |
| `<C-x>` | Open file at commit in horizontal split |
| `<C-t>` | Open file at commit in new tab          |
| `<C-g>` | Open file at commit in web browser      |
| `<C-y>` | Copy commit hash to clipboard           |

## Credits

Based off of the [telescope-git-file-history.nvim](https://github.com/isak102/telescope-git-file-history.nvim) Telescope extension by [isak102](https://github.com/isak102/telescope-git-file-history.nvim).
