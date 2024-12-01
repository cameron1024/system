return {
  'Julian/lean.nvim',
  lazy = true,
  event = { 'BufReadPre *.lean', 'BufNewFile *.lean' },
  dependencies = {
    'neovim/nvim-lspconfig',
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    lsp = {},
    mappings = true,
  }
}
