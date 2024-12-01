return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  lazy = true,
  config = function()
    local dap = require 'dap'

    dap.adapters.dart = {
      type = 'executable',
      command = 'dart',
      args = { 'debug_adapter' },
      options = {
        detached = false,
      }
    }
    dap.adapters.flutter = {
      type = 'executable',
      command = 'flutter',
      args = { 'debug_adapter' },
      options = {
        detached = false,
      }
    }
    dap.configurations.dart = {
      {
        type = "dart",
        request = "launch",
        name = "Launch dart",
        dartSdkPath = "dart",
        flutterSdkPath = "flutter",
        program = "${workspaceFolder}/lib/main.dart",
        cwd = "${workspaceFolder}",
      },
      {
        type = "flutter",
        request = "launch",
        name = "Launch flutter",
        dartSdkPath = "dart",
        flutterSdkPath = "flutter",
        program = "${workspaceFolder}/lib/main.dart",
        cwd = "${workspaceFolder}",
      }
    };
  end,
  keys = {
    { "<C-d><C-b>", function() require 'dap'.toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<C-d><C-c>", function() require 'dap'.continue() end,          desc = "Continue Debugging" },
    { "<C-d><C-n>", function() require 'dap'.step_over() end,         desc = "Step Over" },
    { "<C-d><C-i>", function() require 'dap'.step_into() end,         desc = "Step Into" },
    { "<C-d><C-o>", function() require 'dap'.step_out() end,          desc = "Step Out" },
    { "<C-d><C-r>", function() require 'dap'.repl.open() end,         desc = "Debug Repl" },
  }
}
