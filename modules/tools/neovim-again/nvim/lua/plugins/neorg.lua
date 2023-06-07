return {
  {
    "nvim-neorg/neorg",
    dependencies = { "nvim-lua/plenary.nvim", "folke/zen-mode.nvim" },
    build = ":Neorg sync-parsers",
    config = function()
      require 'zen-mode'.setup {}
      require 'neorg'.setup {
        load = {
          ["core.defaults"] = {},  -- Loads default behaviour
          ["core.concealer"] = {}, -- Adds pretty icons to your documents
          ["core.presenter"] = {
            config = {
              zen_mode = "zen-mode",
              slide_count = {
                enable = true,
                position = "top",
                count_format = "[%d/%d]",
              },
            },
          },
          ["core.dirman"] = { -- Manages Neorg workspaces
            config = {
              workspaces = {
                notes = "~/notes",
              },
            },
          },
        },
      }
    end
  }
}
