return {
  "saghen/blink.cmp",
  lazy = true,
  event = "InsertEnter",
  dependencies = {
    "xzbdmw/colorful-menu.nvim",
    { 'L3MON4D3/LuaSnip', version = 'v2.*' },
  },
  -- version = "v0.5.1",
  build = "cargo build --release",

  opts = {
    keymap = {
      preset = "enter",
      ['<Tab>'] = { "select_next", "fallback" },
      ['<S-Tab>'] = { "select_prev", "fallback" },
      ['<C-j>'] = { "snippet_forward", "fallback" },
      ['<C-k>'] = { "snippet_backward", "fallback" },
      ['<C-c>'] = { "hide", "fallback" },
      ['<C-space>'] = { "show", "show_documentation", "hide_documentation", "fallback" },
    },
    sources = {
      default = { "lsp", "path", "snippets" },
      providers = {
        lsp = {
          async = true,
        },
      },
    },

    snippets = { preset = "luasnip" },

    signature = { enabled = true },

    completion = {
      list = {
        selection = {
          preselect = false,
          auto_insert = true,
        },
      },
      menu = {
        border = "single",
        draw = { treesitter = { "lsp" } },
      },
      ghost_text = { enabled = true, },
      documentation = { auto_show = true },
      trigger = {
        show_on_accept_on_trigger_character = true,
        show_on_insert_on_trigger_character = false,
      },
    },
  },
  keys = {
    { "<BS>", "<C-g>c", mode = "s" }
  }
}
