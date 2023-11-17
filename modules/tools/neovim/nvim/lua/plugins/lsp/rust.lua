return {
  'simrat39/rust-tools.nvim',
  dependencies = {
    "Saecki/crates.nvim",
  },
  ft = { "rust", 'toml' },
  opts = {},
  config = function()
    require 'crates'.setup {}
  end
}
