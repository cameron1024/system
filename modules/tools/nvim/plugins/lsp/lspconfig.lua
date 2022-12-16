local nvim_lsp = require 'lspconfig'
local capabilities = require 'cmp_nvim_lsp'.default_capabilities()

nvim_lsp.rust_analyzer.setup {
  capabilities = capabilities,
}
