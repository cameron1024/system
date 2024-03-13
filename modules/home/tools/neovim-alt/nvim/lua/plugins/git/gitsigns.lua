return {
  "lewis6991/gitsigns.nvim",
  lazy = true,
  event = "BufEnter",
  opts = {},
  keys = {
    { "gb", "<cmd>Gitsigns blame_line<cr>", desc = "Git Blame Line" },
  }
}
