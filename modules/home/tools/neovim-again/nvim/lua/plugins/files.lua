return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    "Pocco81/auto-save.nvim",
  },
  event = "UIEnter",
  config = function()
    require 'auto-save'.setup {}
    require 'neo-tree'.setup {
      filesystem = {
        filtered_items = {
          visible = true,
        },
      },
    }
  end
}

