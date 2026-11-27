return {
  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    -- Hunk navigation; ]c / [c keep their diff-mode meaning
    map("n", "]c", function()
      if vim.wo.diff then return vim.cmd.normal({ "]c", bang = true }) end
      gitsigns.nav_hunk("next")
    end, "Next git hunk")
    map("n", "[c", function()
      if vim.wo.diff then return vim.cmd.normal({ "[c", bang = true }) end
      gitsigns.nav_hunk("prev")
    end, "Previous git hunk")

    map("n", "<Leader>hs", gitsigns.stage_hunk, "Stage hunk")
    map("n", "<Leader>hr", gitsigns.reset_hunk, "Reset hunk")
    map("v", "<Leader>hs", function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
    map("v", "<Leader>hr", function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selection")
    map("n", "<Leader>hS", gitsigns.stage_buffer, "Stage buffer")
    map("n", "<Leader>hp", gitsigns.preview_hunk, "Preview hunk")
    map("n", "<Leader>hb", function() gitsigns.blame_line({ full = true }) end, "Blame line")
    map("n", "<Leader>hd", gitsigns.diffthis, "Diff against index")
  end,
}
