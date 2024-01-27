return {
  'mrcjkb/rustaceanvim',
  version = '^3',
  ft = { 'rust' },
  dependencies = { 'vxpm/ferris.nvim' },
  config = function ()
    require 'ferris'.setup {}
  end
}
