return {
  'stevearc/oil.nvim',
  lazy = true,
  opts = {
    keymaps = {
      ["<C-t>"] = false,
      ["<leader>p"] = false,
      ["<C-p>"] = "actions.parent",
      ["<C-v>"] = false,
      ["<C-x>"] = false,
      ["-"] = "actions.close",
    },
    view_options = {
      show_hidden = true,
    },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Oil" }
  },
}
