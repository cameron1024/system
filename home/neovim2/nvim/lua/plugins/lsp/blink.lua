return {
  "saghen/blink.cmp",
  lazy = true,
  event = "InsertEnter",
  dependencies = {
    "xzbdmw/colorful-menu.nvim",
    "moyiz/blink-emoji.nvim",
    "bydlw98/blink-cmp-env",
    { 'L3MON4D3/LuaSnip', version = 'v2.*' },
  },
  -- version = "v0.5.1",
  build = "cargo build --release",

  opts = {
    keymap = {
      preset = "enter",
      ['<Tab>'] = { "select_next", "fallback" },
      ['<S-Tab>'] = { "select_prev", "fallback" },
      ['<C-j>'] = { "select_next", "fallback" },
      ['<C-k>'] = { "select_prev", "fallback" },
      ['<C-l>'] = { "snippet_forward", "fallback" },
      ['<C-h>'] = { "snippet_backward", "fallback" },
      ['<C-c>'] = { "hide", "fallback" },
      ['<C-space>'] = { "show", "show_documentation", "hide_documentation", "fallback" },
    },
    sources = {
      default = { "lsp", "path", "snippets", "emoji", "env" },
      providers = {
        lsp = {
          async = true,
        },
        emoji = {
          module = "blink-emoji",
          name = "Emoji",
          score_offset = 15,
          opts = { insert = true },
        },
        env = {
          module = "blink-cmp-env",
          name = "Env",
          opts = { insert = true },
        }
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
