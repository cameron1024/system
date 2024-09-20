return {
  "chomosuke/typst-preview.nvim",
  dependencies = {
    "kaarmu/typst.vim",
    "MrPicklePinosaur/typst-conceal.vim",
  },
  lazy = true,
  ft = "typst",
  version = "0.3.*",
  build = function() require 'typst-preview'.update() end,
  opts = {
    debug = true,
    open_cmd = "xdg-open %s",
    dependencies_bin = {
      ['typst-preview'] = "tinymist",
    },
  },
}
