return {
  "nvim-neorg/neorg",
  build = ":Neorg sync-parsers",
  lazy = true,
  ft = "norg",
  cmd = { "Neorg" },
  -- tag = "*",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
  },
  config = function()
    require("neorg").setup {
      load = {
        ["core.defaults"] = {},
        ["core.concealer"] = {},
        ["core.completion"] = {
          config = {
            engine = "nvim-cmp",
          },
        },
        ["core.dirman"] = {
          config = {
            default_workspace = "notes",
            workspaces = {
              notes = "~/notes",
            },
          },
        },
        ["core.summary"] = {},
      },
    }
  end,
}
