local toggle_inlay = function()
  local lsp = vim.lsp
  lsp.inlay_hint.enable(not lsp.inlay_hint.is_enabled())
end

local function next_error()
  vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
end
local function prev_error()
  vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
end

local function toggle_harper()
  local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in pairs(buf_clients) do
    if client.name == "harper_ls" then
      client.stop()
      return
    end
  end
  vim.cmd("LspStart harper_ls")
end

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
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }

    lspconfig.nil_ls.setup { capabilities = capabilities }
    lspconfig.nixd.setup { capabilities = capabilities }
    lspconfig.taplo.setup { capabilities = capabilities }
    lspconfig.biome.setup { capabilities = capabilities }
    lspconfig.ts_ls.setup { capabilities = capabilities }
    lspconfig.tinymist.setup { capabilities = capabilities }
    lspconfig.bashls.setup { capabilities = capabilities }
    lspconfig.harper_ls.setup { capabilities = capabilities, autostart = false, }
    -- lspconfig.markdown_oxide.setup { capabilities = capabilities }
    lspconfig.marksman.setup { capabilities = capabilities }
    lspconfig.nickel_ls.setup { capabilities = capabilities }
    lspconfig.wgsl_analyzer.setup { capabilities = capabilities }
    lspconfig.lemminx.setup { capabilities = capabilities }
    lspconfig.fstar.setup { capabilities = capabilities }
    lspconfig.kotlin_language_server.setup { capabilities = capabilities }

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

    -- lspconfig.dartls.setup {
    --   capabilities = capabilities,
    --   cmd = { "nix", "run", "nixpkgs#dart", "--", "language-server", "--protocol=lsp" },
    -- }

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
    { "gc",         vim.lsp.buf.declaration,   desc = "LSP Goto Declaration" },
    { "<leader>e",  vim.diagnostic.open_float, desc = "Show Diagnostic" },
    { "Q",          vim.diagnostic.setloclist, desc = "Open Diagnostic Loclist" },
    { "<C-n>",      vim.diagnostic.goto_next,  desc = "Goto Next Diagnostic" },
    { "<C-b>",      vim.diagnostic.goto_prev,  desc = "Goto Next Diagnostic" },
    { "<M-n>",      next_error,                desc = "Goto Next Diagnostic" },
    { "<M-b>",      prev_error,                desc = "Goto Previous Error" },
    { "<leader>a",  vim.lsp.buf.code_action,   mode = { "n", "v" },             desc = "Code Action" },
    { "<leader>i",  toggle_inlay,              mode = { "n", "v" },             desc = "Toggle Inlay Hints" },
    { "<leader>sc", toggle_harper,             mode = { "n", "v" },             desc = "Toggle Spellcheck" },

  },
}
