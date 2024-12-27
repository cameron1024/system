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
  ft = { "dart", "rust" },
  config = function()
    require 'neotest'.setup {
      adapters = {
        require 'neotest-dart' {},
        require 'rustaceanvim.neotest',
      },
      summary = {
        follow = true,
      },
    }
  end,
  keys = {
    { "<leader>tn", function() require 'neotest'.run.run() end,                       desc = "Test Nearest" },
    { "<leader>tf", function() require 'neotest'.run.run(vim.fn.expand("%")) end,     desc = "Test File" },
    { "<leader>ta", function() require 'neotest'.run.run(vim.fn.getcwd()) end,        desc = "Test All" },
    { "<leader>dn", function() require 'neotest'.run.run { strategy = "dap" } end,    desc = "Debug Nearest" },
    { "<leader>tt",  function() require 'neotest'.summary.toggle() end,                desc = "Test Overview" },
    { "<leader>to",  function() require 'neotest'.output_panel.toggle() end,                desc = "Test Overview" },
    { "]f",         function() require 'neotest'.jump.next { status = "failed" } end, desc = "Next Failed Test" },
    { "[f",         function() require 'neotest'.jump.prev { status = "failed" } end, desc = "Prev Failed Test" },
  },
}
