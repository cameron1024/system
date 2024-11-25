return {
  "chomosuke/typst-preview.nvim",
  lazy = true,
  dependencies = {
    "MrPicklePinosaur/typst-conceal.vim",
  },
  ft = "typst",
  version = '1.*',
  opts = {
    dependencies_bin = {
      ['tinymist'] = "tinymist",
      ['websocat'] = nil
    },
  },
}
