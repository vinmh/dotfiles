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
  {
    "saghen/blink.cmp", -- Auto-completion Engine
    version = "1.*", -- release tags ship a prebuilt fuzzy matcher
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = function()
      return require("config.blink-cmp")
    end,
  },
  {"L3MON4D3/LuaSnip", version = "v2.*"}, -- Code Snippet Engine
  {
    "stevearc/conform.nvim", -- Formatting
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = function()
      return require("config.conform")
    end,
  },
  {
    "lewis6991/gitsigns.nvim", -- Git change markers and hunk actions
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      return require("config.gitsigns")
    end,
  },
  {
    "folke/which-key.nvim", -- Keymap hints
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>h", group = "git hunk" },
        { "<leader>w", group = "workspace" },
      },
    },
  },
  "mason-org/mason.nvim", -- Package Manager
  "mason-org/mason-lspconfig.nvim", -- LSP Package Installer
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
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        'vimdoc', 'vim', 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'typescript', 'cmake',
        'markdown', 'markdown_inline',
      })
      -- The main branch no longer enables highlight/indent; start them per buffer
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          if not pcall(vim.treesitter.start, ev.buf) then return end
          -- Only languages with indent queries; others keep their regular indent
          local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
          if lang and vim.treesitter.query.get(lang, "indents") then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
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
    "Aietes/esp32.nvim"
  },
  {
    "folke/lazydev.nvim", -- lua_ls library for the Neovim API, loaded on demand
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons"},
    ft = {"markdown"},
    opts = {}
  },
  {
    's1n7ax/nvim-window-picker',
    name = 'window-picker',
    event = 'VeryLazy',
    version = 'v2.*',
    config = function()
      require('window-picker').setup()
    end,
  },
  {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- optional but recommended
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
      require("config.telescope")
    end,
  }
}, {
  rocks = { enabled = false }, -- no plugin needs luarocks
})
