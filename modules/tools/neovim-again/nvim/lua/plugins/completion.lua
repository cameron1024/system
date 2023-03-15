return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/nvim-cmp',
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    "windwp/nvim-autopairs",
  },
  event = "BufEnter",
  config = function()
    local cmp = require 'cmp'

    require 'nvim-autopairs'.setup {}
    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'

    cmp.setup {
      map_complete = true,
      snippet = {
        expand = function(args)
          require 'luasnip'.lsp_expand(args.body)
        end,
      },
      mapping = {
        ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        ['<Tab>'] = cmp.mapping.select_next_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Insert,
          select = false,
        }),
        ['<Down>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i','c'}),
        ['<Up>'] = cmp.mapping(cmp.mapping.select_prev_item(), {'i','c'}),
      },

      sources = {
        { name = 'nvim_lsp' },
        { name = 'nvim_lsp_signature_help' },
        { name = 'luasnip' },
        { name = 'path' },
        { name = 'buffer' },
        { name = 'emoji', insert = true }
      },
    }

    cmp.event:on(
      'confirm_done',
      cmp_autopairs.on_confirm_done()
    )
  end
}
