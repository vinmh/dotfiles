require("claudecode").setup()

local opts = { noremap = true, silent = true }

-- Claude Code keybindings
vim.keymap.set("n", "<Leader>ac", "<cmd>ClaudeCode<cr>", vim.tbl_extend("force", opts, { desc = "Toggle Claude" }))
vim.keymap.set("n", "<Leader>af", "<cmd>ClaudeCodeFocus<cr>", vim.tbl_extend("force", opts, { desc = "Focus Claude" }))
vim.keymap.set("n", "<Leader>ar", "<cmd>ClaudeCode --resume<cr>", vim.tbl_extend("force", opts, { desc = "Resume Claude" }))
vim.keymap.set("n", "<Leader>aC", "<cmd>ClaudeCode --continue<cr>", vim.tbl_extend("force", opts, { desc = "Continue Claude" }))
vim.keymap.set("n", "<Leader>ab", "<cmd>ClaudeCodeAdd %<cr>", vim.tbl_extend("force", opts, { desc = "Add current buffer" }))
vim.keymap.set("v", "<Leader>as", "<cmd>ClaudeCodeSend<cr>", vim.tbl_extend("force", opts, { desc = "Send to Claude" }))
vim.keymap.set("n", "<Leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", vim.tbl_extend("force", opts, { desc = "Accept diff" }))
vim.keymap.set("n", "<Leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", vim.tbl_extend("force", opts, { desc = "Deny diff" }))
