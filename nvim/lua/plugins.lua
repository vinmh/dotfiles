local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {"catppuccin/nvim", name = "catppuccin", priority = 1000}, -- Colourscheme
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("config.lualine")
    end,
  },
  {"onsails/lspkind.nvim", event = { "VimEnter" }}, -- VSCode-style pictograms
  {"hrsh7th/nvim-cmp", dependencies = { -- Auto-completion Engine
                  "lspkind.nvim",
                  "hrsh7th/cmp-nvim-lsp", -- LSP Auto-Completion
                  "hrsh7th/cmp-buffer", -- Buffer Auto-Completion
                  "hrsh7th/cmp-path", -- Path Auto-Completion
                  "hrsh7th/cmp-cmdline", -- CMDLine Auto-Completion
          }, config = function()
                  require("config.nvim-cmp")
          end
  },
  {"L3MON4D3/LuaSnip", version = "v2.*"}, -- Code Snippet Engine
  "williamboman/mason.nvim", -- Package Manager
  "williamboman/mason-lspconfig.nvim", -- LSP Package Installer
  "neovim/nvim-lspconfig",
  {"nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    }
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup {
	      ensure_installed = { 'vimdoc', 'vim', 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'typescript', 'cmake' },
        sync_install = false,
        highlight = { enable = true, },
        indent = { enable = true},
      }
    end
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true,
      })
    end,
  },
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("config.claudecode")
    end,
  },
})
