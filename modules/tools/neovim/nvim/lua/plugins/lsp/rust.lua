return {
  'mrcjkb/rustaceanvim',
  version = '^4',
  ft = { 'rust' },
  -- dependencies = { 'vxpm/ferris.nvim' },
  config = function()
    -- require 'ferris'.setup {}

    vim.g.rustaceanvim = {
      settings = {
        ['rust-analyzer'] = {
          checkOnSave = {
            command = "clippy",
          },
          check = {
            command = "clippy",
          },
        },
      },
    }
  end
}
