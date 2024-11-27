return {
  "stevearc/quicker.nvim",
  lazy = true,
  event = "FileType qf",
  keys = {
    { "<C-q>", function() require 'quicker'.toggle() end },
    { "<C-tab>", function() require 'quicker'.toggle {loclist = true} end },
  },
  opts = {
    keys = {
      {
        ">",
        function ()
          require 'quicker'.expand { before = 2, after = 2, add_to_existing = true }
        end,
      },
      {
        "<",
        function ()
          require 'quicker'.collapse()
        end,
      }
    }
  },
}
