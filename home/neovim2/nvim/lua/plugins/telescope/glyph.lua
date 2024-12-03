return {
  "alduraibi/telescope-glyph.nvim",
  lazy = true,
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require 'telescope'.load_extension 'glyph'
  end,
  keys = {
    { "<leader>.", "<cmd>Telescope glyph<cr>", mode = "n" },
    -- { "<C-.>",     "<cmd>Telescope emoji<cr>", mode = "i" },
  },
}
