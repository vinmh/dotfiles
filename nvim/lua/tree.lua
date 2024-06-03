require("nvim-tree").setup()

-- Keybindings
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<Leader>t', ':NvimTreeToggle<CR>', opts)
