return {
  'neovim/nvim-lspconfig',
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "LspInfo" },
  config = function()
    local lspconfig = require 'lspconfig'
    local cmp = require 'cmp_nvim_lsp'
    local capabilities = cmp.default_capabilities()

    lspconfig.nil_ls.setup { capabilities = capabilities }
    lspconfig.dartls.setup { capabilities = capabilities }

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
  end
}
