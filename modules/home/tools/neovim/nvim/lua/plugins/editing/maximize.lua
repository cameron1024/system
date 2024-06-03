return {
  "declancm/maximize.nvim",
  lazy = true,
  opts = {},
  keys = {
    { "<C-z>", function() require 'maximize'.toggle() end, mode = { "n", "v", "t" }, desc = "Toggle Maximize Window" },
  }
}
