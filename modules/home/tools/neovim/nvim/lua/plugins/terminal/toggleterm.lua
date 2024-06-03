return {
  'akinsho/toggleterm.nvim',
  lazy = true,
  opts = {
    persist_size = false,
    open_mapping = "<C-t>",
    shell = "fish",
  },
  keys = {
    { "<C-t>", "", mode = { "n" }, desc = "Toggle terminal" },
  }
}
