return {
  "lewis6991/hover.nvim",
  lazy = true,
  opts = {
    init = function ()
      require 'hover.providers.lsp'
      require 'hover.providers.gh'
      require 'hover.providers.gh_user'
      require 'hover.providers.fold_preview'
      require 'hover.providers.man'
      require 'hover.providers.dictionary'
    end
  },
  keys = {
    { "K", function() require 'hover'.hover() end },
    { "gK", function() require 'hover'.hover_switch "next" end },
  }

}
