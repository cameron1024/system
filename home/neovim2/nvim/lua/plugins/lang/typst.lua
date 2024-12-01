return {
  "chomosuke/typst-preview.nvim",
  lazy = true,
  ft = "typst",
  version = '1.*',
  opts = {
    dependencies_bin = {
      ['tinymist'] = "tinymist",
      ['websocat'] = nil
    },
  },
}
