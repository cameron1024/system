return {
  'stevearc/oil.nvim',
  lazy = true,
  opts = {
    keymaps = {
      ["<C-t>"] = false,
      ["<leader>p"] = false,
      ["<C-p>"] = "actions.parent",
      ["<C-v>"] = "actions.select_vsplit",
      ["<C-x>"] = "actions.select_split",
      ["<C-CR>"] = "actions.select_split",
      ["-"] = "actions.close",
    },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Oil" }
  },
}
