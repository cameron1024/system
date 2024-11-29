return {
  "3rd/image.nvim",
  lazy = true,
  build = false,
  event = "BufReadPost",
  opts = {
    processor = "magick_cli",
    backend = "kitty",
    integrations = {
      markdown = { enabled = true, },
      typst = { enabled = true, },
    }
  },
}
