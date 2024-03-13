return {
  'nvim-neo-tree/neo-tree.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  event = "VeryLazy",
  opts = {
    close_if_last_window = true,
    filesystem = {
      filtered_items = {
        visible = true,
      },
    },
  },
}
