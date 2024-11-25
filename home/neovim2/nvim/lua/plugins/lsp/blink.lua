return {
  "saghen/blink.cmp",
  lazy = true, 
  event = "InsertEnter",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  version = "v0.5.1",
  build = "cargo build --release",
  opts = {
    keymap = {
      preset = "enter",
      ['<Tab>'] = { "select_next", "fallback" },
      ['<S-Tab>'] = { "select_prev", "fallback" },
      ['<C-j>'] = { "select_next", "fallback" },
      ['<C-k>'] = { "select_prev", "fallback" },
      ['<C-c>'] = { "hide", "fallback" },
    },
    sources = {
      completion = {
        enabled_providers = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    },
  },
}
