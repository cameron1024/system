return {
  "renerocksai/telekasten.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-telekasten/calendar-vim",
  },
  lazy = true,
  opts = {
    home = vim.fn.expand("~/zettel"),
  },
  keys = {
    { "<leader>kk", "<cmd>Telekasten panel<cr>",    desc = "Telekasten panel" },
    { "<leader>kn", "<cmd>Telekasten new note<cr>", desc = "Telekasten new note" },
  },

}
