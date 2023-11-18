return {
  'simrat39/rust-tools.nvim',
  dependencies = {
    "Saecki/crates.nvim",
  },
  event = "VeryLazy",
  opts = {},
  config = function()
    require 'crates'.setup {}
  end
}
