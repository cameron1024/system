{
  plugins.neotest = {
    enable = false;
    lazyLoad.enable = true;
    lazyLoad.settings.keys = [
      {
        desc = "Test Nearest";
        __unkeyed-1 = "<leader>tn";
        __unkeyed-2.__raw = ''
          function() require 'neotest'.run.run() end
        '';
      }
      {
        desc = "Test File";
        __unkeyed-1 = "<leader>tf";
        __unkeyed-2.__raw = ''
          function() require 'neotest'.run.run(vim.fn.expand("%")) end
        '';
      }
      {
        desc = "Test All";
        __unkeyed-1 = "<leader>ta";
        __unkeyed-2.__raw = ''
          function() require 'neotest'.run.run(vim.fn.getcwd()) end
        '';
      }
      {
        desc = "Test Overview";
        __unkeyed-1 = "<leader>tt";
        __unkeyed-2.__raw = ''
          function() require 'neotest'.summary.toggle() end
        '';
      }
      {
        desc = "Test Output";
        __unkeyed-1 = "<leader>to";
        __unkeyed-2.__raw = ''
          function() require 'neotest'.output_panel.toggle() end
        '';
      }
      {
        desc = "Next Failed Test";
        __unkeyed-1 = "]f";
        __unkeyed-2.__raw = ''
          function() require 'neotest'.jump.next { status = "failed" } end
        '';
      }
      {
        desc = "Prev Failed Test";
        __unkeyed-1 = "[f";
        __unkeyed-2.__raw = ''
          function() require 'neotest'.jump.prev { status = "failed" } end
        '';
      }
    ];

    # adapters.dart.enable = true;
    # adapters.rust.enable = true;

    # settings.diagnostic.enabled = false;
  };
}
