return {
  "stevearc/quicker.nvim",
  lazy = true,
  event = "FileType qf",
  opts = {},
  keys = {
    { "<C-q>", function() require 'quicker'.toggle() end },
    { "<C-tab>", function() require 'quicker'.toggle {loclist = true} end },
  }
}
