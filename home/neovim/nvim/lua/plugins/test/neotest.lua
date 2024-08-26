return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "sidlatau/neotest-dart",
    "mrcjkb/rustaceanvim",
  },
  lazy = true,
  ft = { "dart" },
  config = function()
    require 'neotest'.setup {
      adapters = {
        require 'neotest-dart' {},
        require 'rustaceanvim.neotest',
      }
    }
  end,
  keys = {
    { "<leader>tn", function() require 'neotest'.run.run() end,                       mode = "n", desc = "Test Nearest" },
    { "<leader>tf", function() require 'neotest'.run.run(vim.fn.expand("%")) end,     mode = "n", desc = "Test File" },
    { "<leader>dn", function() require 'neotest'.run.run { strategy = "dap" } end,    mode = "n", desc = "Debug Nearest" },
    { "<leader>o",  function() require 'neotest'.summary.toggle() end,                mode = "n", desc = "Test Overview" },
    { "]f",         function() require 'neotest'.jump.next { status = "failed" } end, mode = "n", desc = "Next Failed Test" },
    { "[f",         function() require 'neotest'.jump.prev { status = "failed" } end, mode = "n", desc = "Prev Failed Test" },
  },
}
