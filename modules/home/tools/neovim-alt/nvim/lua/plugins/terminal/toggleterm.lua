return {
  'akinsho/toggleterm.nvim',
  event = "VeryLazy",
  opts = {
    persist_size = false,
    open_mapping = "<C-t>",
    shell = "fish",
  },
  keys = {
    { "<C-t>", "",                                   mode = { "n" }, desc = "Toggle terminal" },
    { "<C-t>", ":ToggleTermSendVisualSelection<CR>", mode = { "v" }, desc = "Send to terminal" },
  }
}
