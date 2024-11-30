return {
  'akinsho/toggleterm.nvim',
  lazy = true,
  event = "VeryLazy",
  opts = {
    persist_size = false,
    open_mapping = false,
  },
  keys = {
    { "<C-t>",     "<cmd>ToggleTerm<cr>",                    mode = { "n", "t", "i", "v", "x" } },
    { "<leader>t", "<cmd>ToggleTermSendCurrentLine<cr>",     mode = { "n" } },
    { "<leader>t", "<cmd>ToggleTermSendVisualSelection<cr>", mode = { "v" } },
  }
}
