-- Note Order: mason -> mason-lspconfig
require('mason').setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

-- nvim-lspconfig should still be installed as it provides the base configs
-- but we don't require() it anymore
require('mason-lspconfig').setup({
  ensure_installed = {
    'pylsp',
    'lua_ls',
    'rust_analyzer',
    'zls',
    'clangd',
    'bashls'
  },
  -- mason-lspconfig v2 auto-enables by default, but being explicit:
  automatic_enable = true
})

local esp32 = require("esp32")
local esp32_clangd_config = esp32.lsp_config()

-- Global diagnostic keymaps (these don't need to be in on_attach)
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<Leader>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<Leader>q", vim.diagnostic.setloclist, opts)

-- LspAttach autocmd replaces the on_attach function
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local bufnr = ev.buf

    -- Enable completion triggered by <c-x><c-o>
    vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

    -- Enable inlay hints for rust_analyzer
    if client.name == "rust_analyzer" then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    -- Buffer-local LSP keymaps
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
    vim.keymap.set("n", "<Leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set("n", "<Leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set("n", "<Leader>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set("n", "<Leader>D", vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, bufopts)
    vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, bufopts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
    vim.keymap.set("n", "<Leader>f", function()
      vim.lsp.buf.format({ async = true })
    end, bufopts)
  end,
})

-- Server-specific configurations using vim.lsp.config
-- lua_ls needs special configuration
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

if esp32_clangd_config then
  vim.lsp.config('clangd', esp32_clangd_config)
end

-- Enable all the servers
-- mason-lspconfig's automatic_enable should handle this, but if you want explicit control:
vim.lsp.enable({
  'pylsp',
  'lua_ls',
  'rust_analyzer',
  'zls',
  'clangd',
  'bashls'
})
