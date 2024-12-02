return {
  "xiyaowong/telescope-emoji.nvim",
  lazy = true,
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require "telescope".load_extension "emoji"
  end,
  keys = {
    { "<leader>.", "<cmd>Telescope emoji<cr>", mode = "n" },
    { "<C-.>",     "<cmd>Telescope emoji<cr>", mode = "i" },
  },
}
