return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  keys = {
    { "<leader>e", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble" },
  }
}
