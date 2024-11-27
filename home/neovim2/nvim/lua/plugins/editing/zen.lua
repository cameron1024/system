return {
  "pocco81/true-zen.nvim",
  lazy = true,
  opts = {
    integrations = {
      lualine = true,
    },
  },
  keys = {
    { "<C-z>", "<cmd>TZAtaraxis<cr>", mode = "n" },
    { "<C-z>", ":'<,'>TZNarrow<cr>", mode = "v" },
  }
}
