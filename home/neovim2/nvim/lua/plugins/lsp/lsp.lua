local toggle_inlay = function()
  local lsp = vim.lsp
  lsp.inlay_hint.enable(not lsp.inlay_hint.is_enabled())
end

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
    local capabilities = 
    require 'blink.cmp'.get_lsp_capabilities(
      vim.lsp.protocol.make_client_capabilities()
    )

    lspconfig.rust_analyzer.setup { capabilities = capabilities }
    lspconfig.dartls.setup { capabilities = capabilities }
  end,
  keys = {
    { "K",          vim.lsp.buf.hover,         desc = "LSP Hover" },
    { "gd",         vim.lsp.buf.definition,    desc = "LSP Goto Definition" },
    { "gc",         vim.lsp.buf.declaration,   desc = "LSP Goto Declaration" },
    { "<leader>e",  vim.diagnostic.open_float, desc = "Show Diagnostic" },
    { "Q",          vim.diagnostic.setloclist, desc = "Open Diagnostic Loclist" },
    { "<C-n>",      vim.diagnostic.goto_next,  desc = "Goto Next Diagnostic" },
    { "<C-b>",      vim.diagnostic.goto_prev,  desc = "Goto Prev Diagnostic" },
    { "<leader>a",  vim.lsp.buf.code_action,   desc = "Code Action" },
    { "<leader>i",  toggle_inlay,              desc = "Toggle Inlay Hints" },
    { "<leader>sc", toggle_harper,             desc = "Toggle Spellcheck" },

  },
}
