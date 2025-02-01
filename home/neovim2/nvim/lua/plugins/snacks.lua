return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    bigfile = { enabled = true },
    lazygit = { enabled = true },
    notifier = { enabled = true },
    terminal = { enabled = true },
    quickfile = { enabled = true },
  },
  keys = {
    { "<C-g><C-L>", function() Snacks.lazygit() end },
  }
}
