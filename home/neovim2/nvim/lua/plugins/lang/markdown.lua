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
}
