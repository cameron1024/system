return {
  "michaelrommel/nvim-silicon",
  lazy = true,
  cmd = "Silicon",
  opts = {
    font = "FiraCode Nerd Font=16",
    to_clipboard = true,
    theme = "catppuccin-mocha",
  },
  keys = {
    { "<leader>ss", "<cmd>Silicon<cr>", mode = { "v", "x" }, desc = "Silicon Snippet" },
  }
}
