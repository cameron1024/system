return {
  "3rd/image.nvim",
  lazy = true,
  enabled = vim.g.started_by_firenvim == nil,
  build = false,
  ft = { "markdown", "typst", },
  opts = {
    processor = "magick_cli",
    backend = "kitty",
    integrations = {
      markdown = { enabled = true, },
      typst = { enabled = true, },
    }
  },
}
