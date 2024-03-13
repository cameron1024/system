return {
  "nvimdev/lspsaga.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {},
  keys = {
    { "<leader>a", "<cmd>Lspsaga code_action<cr>", desc = "Code Actions" },
  }
}
