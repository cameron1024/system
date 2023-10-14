return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "j-hui/fidget.nvim",
    "smjonas/inc-rename.nvim",
    "rmagatti/goto-preview",
  },
  event = "BufEnter",
  config = function()
    local lspconfig = require 'lspconfig'
    local capabilities = require 'cmp_nvim_lsp'.default_capabilities()

    vim.tbl_deep_extend('keep', lspconfig, {
      noir = {
        cmd = { 'nargo lsp' },
        filetypes = 'nr',
        name = 'noir',
      }
    })

    -- lspconfig.rust_analyzer.setup { capabilities = capabilities, }
    lspconfig.dartls.setup { capabilities = capabilities, }
    lspconfig.nil_ls.setup { capabilities = capabilities, }
    lspconfig.pyright.setup { capabilities = capabilities, }
    lspconfig.noir.setup { capabilities = capabilities, }
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

    require 'fidget'.setup {}
    require 'inc_rename'.setup {}
    require 'goto-preview'.setup {}

    vim.keymap.set("n", "<f2>", function()
      return ":IncRename " .. vim.fn.expand("<cword>")
    end, { expr = true })
  end
}
