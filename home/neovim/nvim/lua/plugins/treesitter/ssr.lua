return {
  "cshuaimin/ssr.nvim",
  lazy = true,
  opts = {},
  keys = {
    { "<leader>sr", function() require 'ssr'.open() end, mode = { "n", "x" }, desc = "Search/Replace" }
  }
}
