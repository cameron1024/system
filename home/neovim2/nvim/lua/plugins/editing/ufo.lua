return {
  "kevinhwang91/nvim-ufo",
  dependencies = {
    "kevinhwang91/promise-async",
  },
  lazy = true,
  event = "BufReadPost",
  config = function()
    vim.o.foldcolumn = "1"
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    require 'ufo'.setup {}
  end,
  keys = {
    { "zR", function() require 'ufo'.openAllFolds() end },
    { "zM", function() require 'ufo'.closeAllFolds() end },
  }
}
