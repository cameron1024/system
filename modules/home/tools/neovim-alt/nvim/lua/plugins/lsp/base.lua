return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    require 'plugins.lsp.cmp',
    "b0o/schemastore.nvim",
  },
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
    lspconfig.markdown_oxide.setup { capabilities = capabilities }
    lspconfig.nickel_ls.setup { capabilities = capabilities }
    lspconfig.wgsl_analyzer.setup { capabilities = capabilities }

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
      cmd = { "nix", "run", "nixpkgs#dart", "--", "language-server", "--protocol=lsp" },
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
    { "K",         ":lua vim.lsp.buf.hover()<cr>",           desc = "LSP Hover" },
    { "gd",        ":lua vim.lsp.buf.definition()<cr>",      desc = "LSP Goto Definition" },
    { "gc",        ":lua vim.lsp.buf.declaration()<cr>",     desc = "LSP Goto Declaration" },
    { "gi",        ":lua vim.lsp.buf.implementation()<cr>",  desc = "LSP Goto Implementation" },
    { "gt",        ":lua vim.lsp.buf.type_definition()<cr>", desc = "LSP Goto Type Definition" },
    { "gr",        ":lua vim.lsp.buf.references()<cr>",      desc = "LSP References" },
    { "<C-e>",     ":lua vim.diagnostic.open_float()<cr>",   desc = "Show Diagnostic" },
    { "Q",         ":lua vim.diagnostic.setloclist()<cr>",   desc = "Open Diagnostic Loclist" },
    { "<C-n>",     ":lua vim.diagnostic.goto_next()<cr>",    desc = "Goto Next Diagnostic" },
    { "<C-b>",     ":lua vim.diagnostic.goto_prev()<cr>",    desc = "Goto Next Diagnostic" },
    { "<leader>r", ":lua vim.lsp.buf.rename()<cr>",          desc = "Rename" },
    { "<leader>a", ":lua vim.lsp.buf.code_action()<cr>",     mode = { "n", "v" },              desc = "Goto Next Diagnostic" },

  },
}

