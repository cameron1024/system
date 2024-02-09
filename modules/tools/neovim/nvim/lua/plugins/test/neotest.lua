return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "mrcjkb/rustaceanvim",
  },
  event = "VeryLazy",
  config = function()
    require 'neotest'.setup {
      adapters = {
        require 'rustaceanvim.neotest',
      },
    }
  end,
}
