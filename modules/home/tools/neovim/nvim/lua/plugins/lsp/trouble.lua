return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = true,
  cmd = "Trouble",
  keys = {
    { "<C-e>", "<cmd>Trouble diagnostics toggle<cr>", desc = "Toggle Diagnostics" },
  }
}
