return {
  "mfussenegger/nvim-dap",
  lazy = true,
  config = function()
    local dap = require 'dap'

    dap.adapters.dart = {
      type = 'executable',
      command = 'dart', -- if you're using fvm, you'll need to provide the full path to dart (dart.exe for windows users), or you could prepend the fvm command
      args = { 'debug_adapter' },
      -- windows users will need to set 'detached' to false
      options = {
        detached = false,
      }
    }
    dap.adapters.flutter = {
      type = 'executable',
      command = 'flutter', -- if you're using fvm, you'll need to provide the full path to flutter (flutter.bat for windows users), or you could prepend the fvm command
      args = { 'debug_adapter' },
      -- windows users will need to set 'detached' to false
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
    { "<C-d><C-b>", function() require 'dap'.continue() end,          desc = "Continue Debugging" },
    { "<C-d><C-o>", function() require 'dap'.step_over() end,         desc = "Step Over" },
    { "<C-d><C-i>", function() require 'dap'.step_into() end,         desc = "Step Into" },
    { "<C-d><C-u>", function() require 'dap'.step_out() end,          desc = "Step Out" },
    { "<C-d><C-r>", function() require 'dap'.repl.open() end,         desc = "Debug Repl" },
  }
}
