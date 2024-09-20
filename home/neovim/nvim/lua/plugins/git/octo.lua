return {
  "pwntester/octo.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  lazy = true,
  command = { "Octo" },
  keys = {
    { "<C-g><C-h>", ":Octo ", desc = "Octo" },
  },
  opts = {
    suppress_missing_scope = {
      projects_v2 = true,
    },
  },
}
