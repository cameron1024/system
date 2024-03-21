return {
  'stevearc/oil.nvim',
  opts = {
    keymaps = {
      ["<C-t>"] = false,
      ["<C-p>"] = "actions.parent",
      ["<C-v>"] = "actions.select_vsplit",
      ["<C-x>"] = "actions.select_split",
      ["<C-CR>"] = "actions.preview",
      ["-"] = "actions.close",
    },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Oil" }
  },
}
