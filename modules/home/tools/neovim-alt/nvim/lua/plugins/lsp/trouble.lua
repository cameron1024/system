return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = true,
  event = "VeryLazy",
  keys = {
    { "<C-e>", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble" },
  }
}
