local menu_draw = {
  components = {
    label = {
      width = { fill = true, max = 60 },
      text = function(ctx)
        local highlights_info =
            require("colorful-menu").highlights(ctx.item, vim.bo.filetype)
        if highlights_info ~= nil then
          return highlights_info.text
        else
          return ctx.label
        end
      end,
      highlight = function(ctx)
        local highlights_info =
            require("colorful-menu").highlights(ctx.item, vim.bo.filetype)
        local highlights = {}
        if highlights_info ~= nil then
          if highlights_info.highlights == nil then
            return { {
              0,
              #ctx.label,
              group = ctx.deprecated
                  and "BlinkCmpLabelDeprecated"
                  or "BlinkCmpLabel",
            } }
          else
            for _, info in ipairs(highlights_info.highlights) do
              table.insert(highlights, {
                info.range[1],
                info.range[2],
                group = ctx.deprecated and "BlinkCmpLabelDeprecated" or info[1],
              })
            end
          end
        end
        for _, idx in ipairs(ctx.label_matched_indices) do
          table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
        end
        return highlights
      end,
    },
  },
}


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
      -- cmdline = {},
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
        draw = menu_draw,
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
