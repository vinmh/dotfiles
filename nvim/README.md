# Neovim Configuration

Minimal nvim config with LSP, completion, formatting, and treesitter.

## Requirements

- Neovim 0.12+
- [Nerd Font](https://www.nerdfonts.com/) (for icons)
- `tree-sitter` CLI and a C compiler (nvim-treesitter `main` builds parsers locally)
- `make` (telescope-fzf-native)
- Optional formatters, used by conform when on `PATH`: `black`, `rustfmt`, `gofmt`, `zig`, `clang-format`
- Optional: `fd` (faster Telescope file search)

## Plugins

| Plugin | Purpose |
|--------|---------|
| lazy.nvim | Plugin manager |
| catppuccin | Colourscheme (mocha) |
| lualine | Statusline |
| blink.cmp | Auto-completion |
| LuaSnip | Snippets |
| conform.nvim | Formatting (format on save) |
| mason + mason-lspconfig | LSP installer; enables every installed server |
| nvim-lspconfig | Base LSP server configs |
| lazydev.nvim | Neovim API types for lua_ls |
| nvim-treesitter (`main`) | Parser installer; highlight and indent per buffer |
| render-markdown | In-buffer markdown rendering |
| telescope + fzf-native | Fuzzy finder |
| neo-tree + window-picker | File explorer |
| gitsigns | Git change markers and hunk actions |
| which-key | Keymap hints |
| nvim-autopairs | Auto-close brackets |
| esp32.nvim | ESP-IDF build/flash/monitor and clangd setup |

## Keybindings

Leader key: `<Space>`. Press it and wait for which-key to list what's available.

### General

| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Navigate windows |
| `Ctrl+Shift+h/j/k/l` | Move window |
| `Ctrl+Up/Down` | Increase/decrease window height |
| `Ctrl+Left/Right` | Decrease/increase window width |
| `<` / `>` (visual) | Indent and stay in visual mode |

### Find (Telescope)

| Key | Action |
|-----|--------|
| `Ctrl+p` | Find files |
| `<Leader>fg` | Live grep |
| `<Leader>fb` | Buffers |
| `<Leader>fr` | Recent files |
| `<Leader>fd` | Diagnostics |
| `<Leader>fs` | Document symbols |

### File Explorer (neo-tree)

| Key | Action |
|-----|--------|
| `<Leader>t` | Toggle file tree |
| `<Leader>g` | Git status (float) |
| `<Leader>\` | Buffer list (right) |

### LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `grr` | References (Telescope) |
| `K` | Hover documentation (Neovim default) |
| `<Leader>D` | Go to type definition |
| `<Leader>rn` / `grn` | Rename symbol |
| `<Leader>ca` / `gra` | Code action |
| `<Leader>cf` | Format buffer (conform, falls back to LSP) |
| `<Leader>e` | Show diagnostic |
| `<Leader>q` | Diagnostics to location list |
| `[d` / `]d` | Previous/next diagnostic (Neovim default) |
| `<Leader>wa` / `wr` / `wl` | Add/remove/list workspace folders |

### Completion (insert mode)

| Key | Action |
|-----|--------|
| `Tab` | Next item, or open the menu after a word |
| `Shift+Tab` | Previous item, or jump back in a snippet |
| `Ctrl+j` / `Ctrl+k` | Next/previous item (also `Ctrl+n`/`Ctrl+p`, `Down`/`Up`) |
| `Enter` / `Ctrl+y` | Accept (first item is preselected) |
| `Ctrl+e` | Close the menu and restore typed text |
| `Ctrl+b` / `Ctrl+f` | Scroll documentation |

### Git (gitsigns, in git buffers)

| Key | Action |
|-----|--------|
| `]c` / `[c` | Next/previous hunk (diff navigation in diff mode) |
| `<Leader>hs` | Stage hunk (or selection in visual mode) |
| `<Leader>hr` | Reset hunk (or selection in visual mode) |
| `<Leader>hS` | Stage buffer |
| `<Leader>hp` | Preview hunk |
| `<Leader>hb` | Blame line |
| `<Leader>hd` | Diff against index |

### ESP32 (esp32.nvim)

`<Leader>R` lists build, flash, monitor, configure and clean actions.

## Formatting

Format on save via conform. Python uses black, Rust rustfmt, Go gofmt, Zig `zig fmt`;
other filetypes fall back to the LSP formatter. C/C++ are only formatted on save when a
`.clang-format` exists in the file's directory or a parent, so projects without a defined
style are left untouched (`<Leader>cf` still formats them through clangd).

## Structure

```
~/.config/nvim/
├── init.lua               # Entry point
├── lua/
│   ├── options.lua        # Editor options
│   ├── keymaps.lua        # Key mappings
│   ├── plugins.lua        # Plugin definitions
│   ├── colorscheme.lua    # Theme setup
│   ├── lsp.lua            # Mason, servers, LSP keymaps
│   ├── tree.lua           # Neo-tree setup
│   └── config/
│       ├── blink-cmp.lua  # Completion
│       ├── conform.lua    # Formatting
│       ├── gitsigns.lua   # Git signs and hunk keymaps
│       ├── lualine.lua    # Statusline
│       └── telescope.lua  # Fuzzy finder
└── tests/
    ├── smoke.lua          # Headless smoke test
    └── fixtures/          # Sample markdown/python/lua files
```

## LSP Servers

Managed via Mason; every installed server is enabled. Pre-configured:
- Python (pylsp)
- Lua (lua_ls)
- Rust (rust_analyzer)
- Zig (zls)
- C/C++ (clangd)
- Bash (bashls)
- Go (gopls)

Install more with `:Mason`.

## Testing

Run the headless smoke test from the config directory:

```
nvim --headless -c 'luafile tests/smoke.lua'
```

It prints `PASS`/`FAIL` per check and exits non-zero on any failure. It checks startup
errors and warnings, treesitter and markdown rendering, LSP attach and keymaps,
completion, format on save, gitsigns, and lazy-loaded plugins.
