return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = "3.11",
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  event = "VeryLazy",
  opts = {
    close_if_last_window = true,
  },
}
