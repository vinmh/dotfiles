-- Only reformat C/C++ when the project defines its own style
local function has_clang_format(ctx)
  return vim.fs.find({ ".clang-format", "_clang-format" }, { upward = true, path = ctx.dirname })[1] ~= nil
end

return {
  formatters_by_ft = {
    python = { "black" },
    rust = { "rustfmt" },
    go = { "gofmt" },
    zig = { "zigfmt" },
    c = { "clang-format" },
    cpp = { "clang-format" },
  },
  formatters = {
    ["clang-format"] = {
      condition = function(_, ctx) return has_clang_format(ctx) end,
    },
  },
  -- Filetypes without a formatter above use the LSP's formatter
  default_format_opts = { lsp_format = "fallback" },
  format_on_save = function(bufnr)
    local ft = vim.bo[bufnr].filetype
    if ft == "c" or ft == "cpp" then
      -- Skip silently without a project style; clangd would apply LLVM style
      local dirname = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
      if not has_clang_format({ dirname = dirname }) then return end
      return { timeout_ms = 500, lsp_format = "never" }
    end
    return { timeout_ms = 500 }
  end,
}
