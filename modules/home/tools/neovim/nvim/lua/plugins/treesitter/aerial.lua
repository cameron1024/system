return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  lazy = true,
  opts = {

  },
  keys = {
    { "<leader>o", "<cmd>AerialToggle right<cr>", desc = "Toggle Overview" },
    { "{",         "<cmd>AerialNext<cr>",         mode = { "n", "o", "v" } },
    { "}",         "<cmd>AerialPrev<cr>",         mode = { "n", "o", "v" } },
  }


}
