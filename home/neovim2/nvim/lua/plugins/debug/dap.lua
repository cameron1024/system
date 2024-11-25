return {
  "mfussenegger/nvim-dap",
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
        -- dartSdkPath = "/opt/flutter/bin/cache/dart-sdk/bin/dart",
        -- flutterSdkPath = "/opt/flutter/bin/flutter",
        program = "${workspaceFolder}/lib/main.dart",
        cwd = "${workspaceFolder}",
      },
      {
        type = "flutter",
        request = "launch",
        name = "Launch flutter",
        -- dartSdkPath = "/opt/flutter/bin/cache/dart-sdk/bin/dart",
        -- flutterSdkPath = "/opt/flutter/bin/flutter",
        program = "${workspaceFolder}/lib/main.dart",
        cwd = "${workspaceFolder}",
      }
    }
  end

}
