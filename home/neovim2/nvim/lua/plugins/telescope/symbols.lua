return {
  "nvim-telescope/telescope-symbols.nvim",
  lazy = true,
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    { "<C-q>",     function() require 'telescope.builtin'.symbols { sources = { "lean" } } end,             mode = { "n", "i" } },
    -- { "<leader>.", function() require 'telescope.builtin'.symbols { sources = { "kaomoji", } } end, mode = "n" },
    -- { "<C-.>", function() require 'telescope.builtin'.symbols { sources = { "kaomoji", } } end, mode = "n" },
  }
}
