return {
  "drybalka/tree-climber.nvim",
  lazy = true,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    { "<M-l>",  function() require 'tree-climber'.goto_next() end,   mode = { "n", "v", "o" }, },
    { "<M-h>",  function() require 'tree-climber'.goto_prev() end,   mode = { "n", "v", "o" }, },
    { "<M-k>",  function() require 'tree-climber'.goto_parent() end, mode = { "n", "v", "o" }, },
    { "<M-j>",  function() require 'tree-climber'.goto_child() end,  mode = { "n", "v", "o" }, },
    { "<SM-l>", function() require 'tree-climber'.swap_next() end, },
    { "<SM-h>", function() require 'tree-climber'.swap_prev() end, },
    { "<leader>`", function() require 'tree-climber'.highlight_node() end, },
  }
}
