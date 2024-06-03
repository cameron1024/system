return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    require 'plugins.lsp.cmp',
    "b0o/schemastore.nvim",
  },
  lazy = true,
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "LspInfo" },
  config = function()
    local lspconfig = require 'lspconfig'
    local schemastore = require 'schemastore'

    local capabilities = require 'cmp_nvim_lsp'.default_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true

    lspconfig.nil_ls.setup { capabilities = capabilities }
    lspconfig.taplo.setup { capabilities = capabilities }
    lspconfig.biome.setup { capabilities = capabilities }
    -- lspconfig.markdown_oxide.setup { capabilities = capabilities }
    lspconfig.marksman.setup { capabilities = capabilities }
    lspconfig.nickel_ls.setup { capabilities = capabilities }
    lspconfig.wgsl_analyzer.setup { capabilities = capabilities }
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

    lspconfig.dartls.setup {
      capabilities = capabilities,
      -- cmd = { "nix", "run", "nixpkgs#dart", "--", "language-server", "--protocol=lsp" },
    }

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
    { "K",         vim.lsp.buf.hover,           desc = "LSP Hover" },
    { "gd",        vim.lsp.buf.definition,      desc = "LSP Goto Definition" },
    { "gc",        vim.lsp.buf.declaration,     desc = "LSP Goto Declaration" },
    { "gi",        vim.lsp.buf.implementation,  desc = "LSP Goto Implementation" },
    { "gt",        vim.lsp.buf.type_definition, desc = "LSP Goto Type Definition" },
    { "gr",        vim.lsp.buf.references,      desc = "LSP References" },
    { "<leader>e", vim.diagnostic.open_float,   desc = "Show Diagnostic" },
    { "Q",         vim.diagnostic.setloclist,   desc = "Open Diagnostic Loclist" },
    { "<C-n>",     vim.diagnostic.goto_next,    desc = "Goto Next Diagnostic" },
    { "<C-b>",     vim.diagnostic.goto_prev,    desc = "Goto Next Diagnostic" },
    { "<leader>r", vim.lsp.buf.rename,          desc = "Rename" },
    { "<leader>a", vim.lsp.buf.code_action,     mode = { "n", "v" },              desc = "Goto Next Diagnostic" },

  },
}
