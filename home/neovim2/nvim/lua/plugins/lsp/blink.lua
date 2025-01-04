return {
  "saghen/blink.cmp",
  lazy = true,
  event = "InsertEnter",
  dependencies = {
    "L3MON4D3/LuaSnip",
    "xzbdmw/colorful-menu.nvim",
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
      menu = {
        border = "single",

        draw = {
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
                  for _, info in ipairs(highlights_info.highlights) do
                    table.insert(highlights, {
                      info.range[1],
                      info.range[2],
                      group = ctx.deprecated and "BlinkCmpLabelDeprecated" or info[1],
                    })
                  end
                end
                for _, idx in ipairs(ctx.label_matched_indices) do
                  table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
                end
                return highlights
              end,
            },
          },
        },

      },
      ghost_text = { enabled = true, },
      documentation = { auto_show = true },
      trigger = {
        show_on_accept_on_trigger_character = true,
        show_on_insert_on_trigger_character = false,
      },
    },
  },
}
