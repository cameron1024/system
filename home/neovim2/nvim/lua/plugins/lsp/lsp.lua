local toggle_inlay = function()
  local lsp = vim.lsp
  lsp.inlay_hint.enable(not lsp.inlay_hint.is_enabled())
end

return {
  "neovim/nvim-lspconfig",
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    "saghen/blink.cmp",
    "b0o/schemastore.nvim",
    require 'plugins.lsp.fidget',
  },
  lazy = true,
  event = { "BufReadPost", "BufNewFile", },
  config = function()
    local lspconfig = require 'lspconfig'
    local schemastore = require 'schemastore'
    local capabilities =
    require 'blink.cmp'.get_lsp_capabilities(
      vim.lsp.protocol.make_client_capabilities()
    )

    lspconfig.dartls.setup { capabilities = capabilities }
    lspconfig.nil_ls.setup { capabilities = capabilities }
    lspconfig.nixd.setup { capabilities = capabilities }
    lspconfig.ts_ls.setup { capabilities = capabilities }
    lspconfig.tinymist.setup { capabilities = capabilities }
    lspconfig.bashls.setup { capabilities = capabilities }
    lspconfig.lemminx.setup { capabilities = capabilities }

    lspconfig.yamlls.setup {
      capabilities = capabilities,
      settings = {
        yaml = {
          schemas = schemastore.yaml.schemas(),
          schemaStore = {
            enable = false,
            url = "",
          },
        },
      },
    }

    lspconfig.jsonls.setup {
      capabilities = capabilities,
      cmd = { "vscode-json-languageserver", "--stdio" },
      settings = {
        json = {
          schemas = schemastore.json.schemas(),
          validate = { enable = true },
        },
      },
    }

    lspconfig.lua_ls.setup {
      capabilities = capabilities,
      settings = {
        Lua = {
          hint = {
            enable = true,
            arrayIndex = 'Enable',
            setType = true,
          },
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
            globals = { "vim" },
          },
          telemetry = {
            enable = false,
          },
        },
      },
    }

  end,
  keys = {
    { "K",          vim.lsp.buf.hover,         desc = "LSP Hover" },
    { "gd",         vim.lsp.buf.definition,    desc = "LSP Goto Definition" },
    { "<leader>e",  vim.diagnostic.open_float, desc = "Show Diagnostic" },
    { "Q",          vim.diagnostic.setloclist, desc = "Open Diagnostic Loclist" },
    { "<C-n>",      vim.diagnostic.goto_next,  desc = "Goto Next Diagnostic" },
    { "<C-b>",      vim.diagnostic.goto_prev,  desc = "Goto Prev Diagnostic" },
    { "<leader>i",  toggle_inlay,              desc = "Toggle Inlay Hints" },
  },
}
