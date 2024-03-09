return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    require 'lazy',
  },
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "LspInfo" },
  config = function()
    local lspconfig = require 'lspconfig'
    -- local cmp = require 'cmp_nvim_lsp'
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    lspconfig.nil_ls.setup { capabilities = capabilities }
    lspconfig.dartls.setup { capabilities = capabilities }
    lspconfig.rust_analyzer.setup { capabilities = capabilities }
    lspconfig.jsonls.setup { capabilities = capabilities }
    lspconfig.taplo.setup { capabilities = capabilities }
    lspconfig.yamlls.setup { capabilities = capabilities }

    -- lspconfig.rust_analyzer.setup {
    --   capabilities = capabilities,
    --   settings = {
    --       ["rust-analyzer"] = {
    --         check = {
    --           command = "clippy",
    --         },
    --       },
    --     },
    -- }

    lspconfig.lua_ls.setup {
      capabilities = capabilities,
      settings = {
        Lua = {
          format = {
            enable = true,
            defaultConfig = {
              indent_style = "space",
              indent_size = "2",
            },
          },
          runtime = {
            version = "LuaJIT",
          },
          diagnostics = {
            globals = { "vim", },
          },
          telemetry = {
            enable = false,
          },
        },
      },
    }
  end,
  keys = {
    { "K",  ":lua vim.lsp.buf.hover()<cr>",           desc = "LSP Hover" },
    { "gd", ":lua vim.lsp.buf.definition()<cr>",      desc = "LSP Goto Definition" },
    { "gc", ":lua vim.lsp.buf.declaration()<cr>",     desc = "LSP Goto Declaration" },
    { "gi", ":lua vim.lsp.buf.implementation()<cr>",  desc = "LSP Goto Implementation" },
    { "gt", ":lua vim.lsp.buf.type_definition()<cr>", desc = "LSP Goto Type Definition" },
    { "gr", ":lua vim.lsp.buf.references()<cr>",      desc = "LSP References" },
    { "<MS-f>", ":lua vim.lsp.buf.format()<cr>",      desc = "LSP Format" },
  },
}
