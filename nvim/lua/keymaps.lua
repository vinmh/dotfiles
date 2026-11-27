local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-----------------
-- Normal Mode --
-----------------

-- Leader
vim.g.mapleader = " "

-- Navigation
map('n', '<C-h>', '<C-w>h', "Window left")
map('n', '<C-j>', '<C-w>j', "Window down")
map('n', '<C-k>', '<C-w>k', "Window up")
map('n', '<C-l>', '<C-w>l', "Window right")

-- Moving
map('n', '<C-S-h>', '<C-w>H', "Move window left")
map('n', '<C-S-j>', '<C-w>J', "Move window down")
map('n', '<C-S-k>', '<C-w>K', "Move window up")
map('n', '<C-S-l>', '<C-w>L', "Move window right")

-- Resizing
map('n', '<C-Up>', ':resize +2<CR>', "Increase window height")
map('n', '<C-Down>', ':resize -2<CR>', "Decrease window height")
map('n', '<C-Left>', ':vertical resize -2<CR>', "Decrease window width")
map('n', '<C-Right>', ':vertical resize +2<CR>', "Increase window width")

-- Telescope
map('n', '<C-p>',      '<cmd>Telescope find_files<CR>',           "Find files")
map('n', '<leader>fg', '<cmd>Telescope live_grep<CR>',            "Live grep")
map('n', '<leader>fb', '<cmd>Telescope buffers<CR>',              "Buffers")
map('n', '<leader>fr', '<cmd>Telescope oldfiles<CR>',             "Recent files")
map('n', '<leader>fd', '<cmd>Telescope diagnostics<CR>',          "Diagnostics")
map('n', '<leader>fs', '<cmd>Telescope lsp_document_symbols<CR>', "Document symbols")
-- LSP references on grr live in lsp.lua (buffer-local, on LspAttach)

-----------------
-- Visual Mode --
-----------------

map('v', '<', '<gv', "Indent left")
map('v', '>', '>gv', "Indent right")
