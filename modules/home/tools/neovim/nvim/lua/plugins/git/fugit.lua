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
  cmd = { 'Fugit2', 'Fugit2Graph', 'FugitBlame', 'Fugit2Diff' },
  keys = {
    { '<C-g><C-g>', mode = 'n', '<cmd>Fugit2<cr>',      desc = "Open Fugit" },
    { '<C-g><C-b>', mode = 'n', '<cmd>Fugit2Blame<cr>', desc = "Git Blame" },
    { '<C-g><C-v>', mode = 'n', '<cmd>Fugit2Graph<cr>', desc = "Git Graph" },
    { '<C-g><C-d>', mode = 'n', '<cmd>Fugit2Diff<cr>',  desc = "Git Diff" },
  },
  opts = {
    libgit2_path = os.getenv("LIBGIT2_PATH") .. "/lib/libgit2.so",
  },
}
