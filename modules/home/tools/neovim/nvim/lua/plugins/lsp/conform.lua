return {
  "stevearc/conform.nvim",
  lazy = true,
  opts = {
    formatters_by_ft = {
      nix = { "alejandra" },
    },
  },
  keys = {
    { "<MS-f>", function() require 'conform'.format { lsp_fallback = true } end, desc = "Format Buffer" },
  },
}
