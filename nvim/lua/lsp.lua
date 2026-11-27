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
    'bashls',
    'gopls'
  },
  -- Enables every Mason-installed server; there is no separate vim.lsp.enable list
  automatic_enable = true
})

local esp32 = require("esp32")
local esp32_clangd_config = esp32.lsp_config()

-- Global diagnostic keymaps (these don't need to be in on_attach)
-- [d / ]d (diagnostic jumps) and K (hover) are Neovim defaults
vim.keymap.set("n", "<Leader>e", vim.diagnostic.open_float, { silent = true, desc = "Show diagnostic" })
vim.keymap.set("n", "<Leader>q", vim.diagnostic.setloclist, { silent = true, desc = "Diagnostics to loclist" })

-- Formatting goes through conform, which falls back to the LSP formatter
vim.keymap.set("n", "<Leader>cf", function()
  require("conform").format({ async = true })
end, { silent = true, desc = "Format buffer" })

-- LspAttach autocmd replaces the on_attach function
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local bufnr = ev.buf

    -- Enable inlay hints for rust_analyzer
    if client.name == "rust_analyzer" then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    -- Buffer-local LSP keymaps
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { silent = true, buffer = bufnr, desc = desc })
    end
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gi", vim.lsp.buf.implementation, "Go to implementation")
    map("grr", "<cmd>Telescope lsp_references<CR>", "References (Telescope)")
    map("<Leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
    map("<Leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
    map("<Leader>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "List workspace folders")
    map("<Leader>D", vim.lsp.buf.type_definition, "Go to type definition")
    map("<Leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("<Leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})

-- Server-specific configurations using vim.lsp.config
-- lua_ls: the Neovim API library comes from lazydev.nvim
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      telemetry = {
        enable = false,
      },
    },
  },
})

if esp32_clangd_config then
  vim.lsp.config('clangd', esp32_clangd_config)
end
