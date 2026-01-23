require("lualine").setup({
  options = {
    theme = "catppuccin",
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { "filename" },
    lualine_x = { "diagnostics", "encoding", "filetype", "filesize" },
    lualine_y = { "location" },
    lualine_z = {},
  },
})
