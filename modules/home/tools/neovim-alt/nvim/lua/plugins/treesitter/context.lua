return {
  "nvim-treesitter/nvim-treesitter-context",
  event = 'BufReadPost',
  opts = {
    enable = true,
    max_lines = 5,
  },
  keys = {
    { "<leader>c", function() require 'treesitter-context'.go_to_context() end, desc = "Treesitter Goto Context" }
  },
}
