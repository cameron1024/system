return {
  "saghen/blink.cmp",
  lazy = true,
  event = "InsertEnter",
  dependencies = {
    "L3MON4D3/LuaSnip",
  },
  -- version = "v0.5.1",
  build = "cargo build --release",
  opts = {
    keymap = {
      preset = "enter",
      ['<Tab>'] = { "select_next", "snippet_forward", "fallback" },
      ['<S-Tab>'] = { "select_prev", "snippet_backward", "fallback" },
      ['<C-j>'] = { "select_next", "fallback" },
      ['<C-k>'] = { "select_prev", "fallback" },
      ['<C-c>'] = { "hide", "fallback" },
      ['<C-space>'] = { "show_documentation", "hide_documentation", "fallback" },
    },
    sources = {
      default = { "lsp", "path", "luasnip" },
      -- cmdline = {},
    },

    snippets = {
      expand = function(snippet) require 'luasnip'.lsp_expand(snippet) end,
      active = function(filter)
        if filter and filter.direction then
          return require 'luasnip'.jumpable(filter.direction)
        end
        return require 'luasnip'.in_snippet()
      end,
      jump = function(direction) require 'luasnip'.jump(direction) end,
    },

    signature = { enabled = true },

    completion = {
      list = { selection = "manual" },
      menu = { border = "single" },
      ghost_text = { enabled = true, },
      documentation = { auto_show = true },
      trigger = {
        show_on_accept_on_trigger_character = true,
        show_on_insert_on_trigger_character = false,
      },
    },
  },
}
