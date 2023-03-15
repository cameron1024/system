local nvim_lsp = require 'lspconfig'

nvim_lsp.rust_analyzer.setup {}
nvim_lsp.pyright.setup {}
nvim_lsp.rnix.setup {}
nvim_lsp.hls.setup {}
nvim_lsp.dartls.setup {}


local signs = {
		Error = "",
		Warning = "",
		Hint = "",
		Information = "",
		Other = "﫠",
}

for type, icon in pairs(signs) do
	local hl = "LspDiagnosticsSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
	vim.lsp.diagnostic.on_publish_diagnostics, {
		update_in_insert = true,
	}
)

require 'nvim-autopairs'.setup {}
local cmp_autopairs = require 'nvim-autopairs.completion.cmp'

local cmp = require 'cmp'
cmp.setup {
  map_complete = true,
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
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
    { name = 'vsnip' },
    { name = 'path' },
    { name = 'buffer' },
    { name = 'emoji', insert = true }
  },
}

cmp.event:on(
  'confirm_done',
  cmp_autopairs.on_confirm_done()
)
