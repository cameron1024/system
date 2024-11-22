return {
  "neovim/nvim-lspconfig",
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    "saghen/blink.cmp",
  },
  lazy = true,
  event = { "BufReadPost", "BufNewFile", },
  config = function()
    local lspconfig = require 'lspconfig'
    local capabilities = require 'blink.cmp'.get_lsp_capabilities(
      vim.lsp.protocol.make_client_capabilities()
    )

    lspconfig.rust_analyzer.setup { capabilities = capabilities }
    lspconfig.dartls.setup { capabilities = capabilities }
  end
}
