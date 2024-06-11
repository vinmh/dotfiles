require("neo-tree").setup()

-- Keybindings
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<Leader>t', ':Neotree reveal toggle<CR>', opts)
vim.keymap.set('n', '<Leader>g', ':Neotree git_status toggle float<CR>', opts)
vim.keymap.set('n', '<Leader>\\', ':Neotree buffers toggle right<CR>', opts)
