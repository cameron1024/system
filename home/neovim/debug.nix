{
    plugins.dap = {
      enable = false;
      lazyLoad.enable = true;
      lazyLoad.settings.keys = [
        {
          desc = "Toggle Breakpoint";
          __unkeyed-1 = "<C-d><C-b>";
          __unkeyed-2.__raw = ''
            function() require 'dap'.toggle_breakpoint() end
          '';
        }
        {
          desc = "Clear Breakpoints";
          __unkeyed-1 = "<C-d><C-x>";
          __unkeyed-2.__raw = ''
            function() require 'dap'.clear_breakpoints() end
          '';
        }
        {
          desc = "Continue Debugging";
          __unkeyed-1 = "<C-d><C-c>";
          __unkeyed-2.__raw = ''
            function() require 'dap'.continue() end
          '';
        }
        {
          desc = "Step Over";
          __unkeyed-1 = "<C-d><C-n>";
          __unkeyed-2.__raw = ''
            function() require 'dap'.step_over() end
          '';
        }
        {
          desc = "Step Into";
          __unkeyed-1 = "<C-d><C-i>";
          __unkeyed-2.__raw = ''
            function() require 'dap'.step_into() end
          '';
        }
        {
          desc = "Step Out";
          __unkeyed-1 = "<C-d><C-o>";
          __unkeyed-2.__raw = ''
            function() require 'dap'.step_out() end
          '';
        }
      ];
      adapters.executables = {
        "dart" = {
          command = "dart";
          args = ["debug_adapter"];
          options.detached = false;
        };
        "flutter" = {
          command = "flutter";
          args = ["debug_adapter"];
          options.detached = false;
        };
      };

      configurations = {
        "dart" = [
          {
            type = "dart";
            request = "launch";
            name = "Launch dart";
            flutterSdkPath = "flutter";
            program = "$${workspaceFolder}/lib/main.dart";
            cwd = "$${workspaceFolder}";
          }
          {
            type = "flutter";
            request = "launch";
            name = "Launch flutter";
            flutterSdkPath = "flutter";
            program = "$${workspaceFolder}/lib/main.dart";
            cwd = "$${workspaceFolder}";
          }
        ];
      };
    };

    plugins.dap-ui = {
      enable = false;
      lazyLoad.enable = true;
      lazyLoad.settings.before.__raw = ''
        function() require 'lz.n'.trigger_load 'nvim-dap' end
      '';
      lazyLoad.settings.keys = [
        {
          desc = "Toggle Breakpoint";
          __unkeyed-1 = "<C-d><C-d>";
          __unkeyed-2.__raw = ''
            function() require 'dapui'.toggle() end
          '';
        }
      ];
    };
}
