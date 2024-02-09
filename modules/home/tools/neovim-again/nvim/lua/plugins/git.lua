return {
  "pwntester/octo.nvim",
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    "tpope/vim-fugitive",
    "lewis6991/gitsigns.nvim",
    "f-person/git-blame.nvim",
    "akinsho/git-conflict.nvim",
  },
  event = "UIEnter",
  config = function()
    require 'octo'.setup {}
    require 'gitsigns'.setup {}
    require 'git-conflict'.setup {}
  end
}

