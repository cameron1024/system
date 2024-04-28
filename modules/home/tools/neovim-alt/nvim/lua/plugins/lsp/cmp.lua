return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-emoji',
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    'windwp/nvim-autopairs',
    'Saecki/crates.nvim',
    'petertriho/cmp-git',
    'nvim-neorg/neorg',
  },
  lazy = true,
  event = "InsertEnter",
  config = function()
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'

    require 'nvim-autopairs'.setup {}
    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'


    cmp.setup {
      map_complete = true,
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      mapping = {
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Insert,
          select = false,
        }),
        ['<Down>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
        ['<Up>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      },

      sources = {
        {
          name = 'nvim_lsp',
          option = {
            markdown_oxide = {
              keyword_pattern = [[\(\k\| \|\/\|#\)\+]]
            },
          },
        },
        { name = 'nvim_lsp_signature_help' },
        { name = 'luasnip' },
        { name = 'path' },
        { name = "git" },
        { name = 'buffer' },
        { name = 'crates' },
        { name = 'neorg' },
        { name = 'emoji',                  insert = true },
      },
    }

    cmp.event:on(
      'confirm_done',
      cmp_autopairs.on_confirm_done()
    )

    require 'cmp_git'.setup {}

    function leave_snippet()
      if
          ((vim.v.event.old_mode == 's' and vim.v.event.new_mode == 'n') or vim.v.event.old_mode == 'i')
          and luasnip.session.current_nodes[vim.api.nvim_get_current_buf()]
          and not luasnip.session.jump_active
      then
        luasnip.unlink_current()
      end
    end

    -- stop snippets when you leave to normal mode
    vim.api.nvim_command([[
        autocmd ModeChanged * lua leave_snippet()
    ]])
  end
}
