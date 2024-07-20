return {
  "norcalli/nvim-colorizer.lua",
  lazy = true,
  event = "BufEnter",
  main = "colorizer",
  opts = {},
  keys = {
    { "<leader>ct", "<cmd>ColorizerToggle<cr>", mode = "n", desc = "Toggle Colorizer" },
  },
}
