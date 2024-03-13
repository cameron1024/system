return {
  'goolord/alpha-nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  enabled = vim.g.started_by_firenvim == nil,
  config = function()
    require 'alpha'.setup(require 'alpha.themes.dashboard'.config)

    vim.cmd [[
      autocmd User AlphaReady set laststatus=0 | autocmd BufUnload <buffer> set laststatus=3
    ]]

  end
}
