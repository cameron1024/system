return {
  "saghen/blink.cmp",
  lazy = true,
  event = "InsertEnter",
  dependencies = {
    "rafamadriz/friendly-snippets",
    -- "mikavilpas/blink-ripgrep.nvim",
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
      ['<C-c>'] = { "hide", "fallback" },
      ['<S-CR>'] = { "fallback" },
    },
    sources = {
      default = { "lsp", "path" },

      providers = {
        -- ripgrep = {
        --   module = "blink-ripgrep",
        --   name = "Ripgrep",
        -- },
        snippets = {
          -- enabled = function() return vim.bo.ft == "dart" end,
          -- should_show_items = function() return vim.bo.ft == "dart" end,
        },
      },
    },
    trigger = {
      completion = {
        show_on_accept_on_trigger_character = true,
        show_on_insert_on_trigger_character = false,
        blocked_trigger_characters = { ' ', '\n', '\t', '.', ',' },
      },

      signature_help = {
        enabled = true,
      },
    },

    completion = {
      ghost_text = { enabled = true, },
    },
  },
}
