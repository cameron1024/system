return {
  "SuperBo/fugit2.nvim",
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-tree/nvim-web-devicons',
    'nvim-lua/plenary.nvim',
    {
      'chrisgrieser/nvim-tinygit', -- optional: for Github PR view
      dependencies = { 'stevearc/dressing.nvim' }
    },
  },
  lazy = true,
  cmd = { 'Fugit2', 'Fugit2Graph' },
  keys = {
    { '<C-g>', mode = 'n', '<cmd>Fugit2<cr>', desc = "Open Fugit" },
  }
}
