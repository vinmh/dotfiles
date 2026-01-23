# Neovim Configuration

Minimal nvim config with LSP, completion, and Claude Code integration.

## Requirements

- Neovim 0.10+
- [Nerd Font](https://www.nerdfonts.com/) (for icons)

## Plugins

| Plugin | Purpose |
|--------|---------|
| lazy.nvim | Plugin manager |
| catppuccin | Colourscheme (mocha) |
| lualine | Statusline |
| nvim-cmp | Auto-completion |
| LuaSnip | Snippets |
| mason | LSP installer |
| nvim-lspconfig | LSP configuration |
| neo-tree | File explorer |
| nvim-treesitter | Syntax highlighting |
| nvim-autopairs | Auto-close brackets |
| claudecode.nvim | Claude Code integration |

## Keybindings

Leader key: `<Space>`

### General

| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Navigate windows |
| `Ctrl+Arrow` | Resize windows |
| `<` / `>` (visual) | Indent and stay in visual mode |

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
| `gr` | Find references |
| `gi` | Go to implementation |
| `K` | Hover documentation |
| `<Leader>rn` | Rename symbol |
| `<Leader>ca` | Code action |
| `<Leader>f` | Format buffer |
| `<Leader>e` | Show diagnostics |
| `[d` / `]d` | Previous/next diagnostic |

### Claude Code

| Key | Mode | Action |
|-----|------|--------|
| `<Leader>ac` | n | Toggle Claude terminal |
| `<Leader>af` | n | Focus Claude terminal |
| `<Leader>ar` | n | Resume session |
| `<Leader>aC` | n | Continue conversation |
| `<Leader>ab` | n | Add current buffer |
| `<Leader>as` | v | Send selection |
| `<Leader>aa` | n | Accept diff |
| `<Leader>ad` | n | Deny diff |

## Structure

```
~/.config/nvim/
├── init.lua              # Entry point
└── lua/
    ├── options.lua       # Editor options
    ├── keymaps.lua       # Key mappings
    ├── plugins.lua       # Plugin definitions
    ├── colorscheme.lua   # Theme setup
    ├── lsp.lua           # LSP configuration
    ├── tree.lua          # Neo-tree setup
    └── config/
        ├── nvim-cmp.lua  # Completion config
        ├── lualine.lua   # Statusline config
        └── claudecode.lua # Claude keybindings
```

## LSP Servers

Managed via Mason. Pre-configured:
- Python (pylsp)
- Lua (lua_ls)
- Rust (rust_analyzer)
- Zig (zls)
- C/C++ (clangd)
- Bash (bashls)

Install more with `:Mason`.
