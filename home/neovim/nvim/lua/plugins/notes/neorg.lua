return {
  "nvim-neorg/neorg",
  lazy = true,
  ft = "norg",
  cmd = { "Neorg" },
  version = "v8.4.1",
  dependencies = {
    "vhyrro/luarocks.nvim",
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
