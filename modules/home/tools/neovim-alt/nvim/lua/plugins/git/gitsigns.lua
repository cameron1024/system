return {
  "lewis6991/gitsigns.nvim",
  lazy = true,
  event = "BufEnter",
  opts = {},
  keys = {
    { "<C-g><C-b>", "<cmd>Gitsigns blame_line<cr>", desc = "Git Blame Line" },
    { "<C-g><C-d>", "<cmd>Gitsigns preview_hunk<cr>", desc = "Git Preview Hunk" },
  }
}
