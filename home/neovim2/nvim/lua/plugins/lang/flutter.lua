return {
  "nvim-flutter/flutter-tools.nvim",
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim',
    "nvim-telescope/telescope.nvim",
    -- "mfussenegger/nvim-dap",
  },
  ft = "dart",
  config = function ()
    require 'flutter-tools'.setup {
      debugger = {
        enabled = true,
      },
    }
  end
}
