return {
  "rachartier/tiny-inline-diagnostic.nvim",
  lazy = true,
  event = "BufReadPost",
  config = function()
    vim.diagnostic.config { virtual_text = false }
    require 'tiny-inline-diagnostic'.setup {}
  end,
  keys = {
    { "<leader>e", function() require 'tiny-inline-diagnostic'.toggle() end }
  }
}
