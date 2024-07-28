return {
  "michaelrommel/nvim-silicon",
  lazy = true,
  cmd = "Silicon",
  opts = {
    -- to_clipboard = true,
    theme = "gruvbox-dark",
    font = "FiraCode Nerd Font",
  },
  keys = {
    { "<leader>ss", "<cmd>Silicon<cr>", mode = { "v", "x" }, desc = "Silicon Snippet" },
  }
}
