require("neo-tree").setup({
  filesystem = {
    use_libuv_file_watcher = true,
  },
})

-- Keybindings
vim.keymap.set('n', '<Leader>t', ':Neotree reveal toggle<CR>', { silent = true, desc = "File tree" })
vim.keymap.set('n', '<Leader>g', ':Neotree git_status toggle float<CR>', { silent = true, desc = "Git status" })
vim.keymap.set('n', '<Leader>\\', ':Neotree buffers toggle right<CR>', { silent = true, desc = "Buffer list" })
