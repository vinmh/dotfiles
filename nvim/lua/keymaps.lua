local opts = {
    noremap = true,
    silent = true
}

-----------------
-- Normal Mode --
-----------------

-- Leader
vim.g.mapleader = " "

-- Navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', opts)
vim.keymap.set('n', '<C-j>', '<C-w>j', opts)
vim.keymap.set('n', '<C-k>', '<C-w>k', opts)
vim.keymap.set('n', '<C-l>', '<C-w>l', opts)

-- Moving
vim.keymap.set('n', '<C-S-h>', '<C-w>H', opts)
vim.keymap.set('n', '<C-S-j>', '<C-w>J', opts)
vim.keymap.set('n', '<C-S-k>', '<C-w>K', opts)
vim.keymap.set('n', '<C-S-l>', '<C-w>L', opts)

-- Resizing
vim.keymap.set('n', '<C-Up>', ':vertical resize -2<CR>', opts)
vim.keymap.set('n', '<C-Down>', ':resize +2<CR>', opts)
vim.keymap.set('n', '<C-Left>', ':resize -2<CR>', opts)
vim.keymap.set('n', '<C-Right>', ':vertical resize +2<CR>', opts)

-- Telescope
vim.keymap.set('n', '<C-p>',      '<cmd>Telescope find_files<CR>',           opts)
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>',            opts)
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>',              opts)
vim.keymap.set('n', '<leader>fr', '<cmd>Telescope oldfiles<CR>',             opts)
vim.keymap.set('n', '<leader>fd', '<cmd>Telescope diagnostics<CR>',          opts)
vim.keymap.set('n', '<leader>fs', '<cmd>Telescope lsp_document_symbols<CR>', opts)
vim.keymap.set('n', 'gr',         '<cmd>Telescope lsp_references<CR>',       opts)
vim.keymap.set('n', 'gd',         '<cmd>Telescope lsp_definitions<CR>',      opts)

-----------------
-- Visual Mode --
-----------------

vim.keymap.set('v', '<', '<gv', opts)
vim.keymap.set('v', '>', '>gv', opts)

