return {
  'akinsho/flutter-tools.nvim',
  lazy = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'stevearc/dressing.nvim',
  },
  opts = {
    lsp = {
      capabilities = vim.lsp.protocol.make_client_capabilities(),
    },
  },
}
