local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

return {
  snippets = { preset = "luasnip" },
  keymap = {
    preset = "none",
    -- Use <C-b/f> to scroll the docs
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    -- Use <C-k/j> to switch in items
    ["<C-k>"] = { "select_prev", "fallback" },
    ["<C-j>"] = { "select_next", "fallback" },
    -- Use <CR>(Enter) to accept the selected item (the first one is preselected)
    ["<CR>"] = { "accept", "fallback" },
    -- Tab: next item if the menu is open, otherwise open it after a word
    ["<Tab>"] = {
      "select_next",
      function(cmp)
        if has_words_before() then return cmp.show() end
      end,
      "fallback",
    },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    -- Keys nvim-cmp's insert preset provided
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
    ["<Up>"] = { "select_prev", "fallback" },
    ["<C-y>"] = { "accept", "fallback" },
    ["<C-e>"] = { "cancel", "fallback" },
  },
  -- Command-line completion was never enabled under nvim-cmp; keep it off
  cmdline = { enabled = false },
  sources = {
    default = { "lsp", "snippets", "buffer", "path" },
  },
}
