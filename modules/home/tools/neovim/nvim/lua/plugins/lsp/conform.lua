return {
  'stevearc/conform.nvim',
  opts = {
    formatters_by_ft = {
      toml = { "taplo" },
      yaml = { "yamlfmt" },
      -- rust = { "rustfmt" },
      -- dart = { "dart_format" },
    }
  },
}
