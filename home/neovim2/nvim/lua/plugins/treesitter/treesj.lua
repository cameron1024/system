return {
  "Wansmer/treesj",
  lazy = true,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    use_default_keymaps = false,
  },
  keys = {
    { "<leader>s", function() require 'treesj'.toggle() end, },
  }
}
