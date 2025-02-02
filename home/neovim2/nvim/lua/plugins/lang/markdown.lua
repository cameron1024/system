return {
  "OXY2DEV/markview.nvim",
  ft = { "markdown", "typst", "latex", "html", "markdown_inline", "yaml" },
  lazy = true,
  tag = "v25.0.0",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
    {
      'Kicamon/markdown-table-mode.nvim',
      opts = {},
    },
  },
  config = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function(args)
        vim.lsp.start({
          name = 'iwes',
          cmd = { 'iwes' },
          root_dir = vim.fs.root(args.buf, { '.iwe' }),
          flags = {
            debounce_text_changes = 300
          }
        })
      end,
    })
  end
}
