return {
  "lewis6991/hover.nvim",
  lazy = true,
  keys = {
    { "K", function() require 'hover'.hover() end, desc = "Hover Info" },
  },
  config = function()
      -- Require providers
      require("hover.providers.lsp")
      -- require('hover.providers.gh')
      -- require('hover.providers.gh_user')
      -- require('hover.providers.jira')
      -- require('hover.providers.dap')
      -- require('hover.providers.fold_preview')
      -- require('hover.providers.diagnostic')
      -- require('hover.providers.man')
      -- require('hover.providers.dictionary')
    end
  end

}
