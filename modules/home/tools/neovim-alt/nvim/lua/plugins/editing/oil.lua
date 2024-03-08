return {
  'stevearc/oil.nvim',
  opts = {
    keymaps = {
      ["<C-t>"] = false,
      ["<C-p>"] = "actions.parent",
    },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>p", "<cmd>Oil<cr>", desc = "Oil" }
  },
}
