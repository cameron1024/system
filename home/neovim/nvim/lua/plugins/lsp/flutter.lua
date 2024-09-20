return {
  "akinsho/flutter-tools.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim",
  },
  lazy = true,
  ft = { "dart", "yaml" },
  opts = {
    lsp = {
      color = {
        enabled = true,
      },
    },
    closing_tags = {
      enabled = true,
    }
  },
}
