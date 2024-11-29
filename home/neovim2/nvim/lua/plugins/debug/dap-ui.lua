return {
  "rcarriga/nvim-dap-ui",
  lazy = true,
  dependencies = {
    require 'plugins.debug.dap',
    "nvim-neotest/nvim-nio",
  },
  opts = {},
  keys = {
    { "<C-d><C-d>", function() require 'dapui'.toggle() end, },
    { "<C-d><C-b>", function() require 'lua.plugins.debug.dap-ui'.toggle_breakpoint() end, },
  }
}
