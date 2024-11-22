return {
  "stevearc/conform.nvim",
  lazy = true,
  cmd = { "ConformInfo" },
  keys = {
    { "<MS-f>", function() require("conform").format({ async = true }) end, },
  },
  opts = {
    formatters_by_ft = {
      nix = { "alejandra" },
    },

    default_format_opts = {
      lsp_format = "fallback",
    },
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
