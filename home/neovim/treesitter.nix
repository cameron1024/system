let
  enable = true;
  lazyLoad = {
    enable = true;
    settings.event = "BufReadPost";
  };
in {
  programs.nixvim = {
    plugins.treesitter = {
      inherit enable;
      lazyLoad.enable = true;
      lazyLoad.settings.event = "BufReadPost";

      settings = {
        highlight.enable = true;

        incremental_selection.enable = true;
        incremental_selection.keymaps = {
          init_selection = "<CR>";
          node_incremental = "<CR>";
          node_decremental = "<BS>";
        };
      };
    };

    plugins.treesitter-context = {
      enable = true;
      inherit lazyLoad;
    };

    plugins.treesitter-textobjects = {
      enable = true;

      select.enable = true;
      select.disable = ["dart"];
      select.lookahead = true;
      select.keymaps = {
        "af" = {
          query = "@function.outer";
          desc = "Around Function";
        };
        "if" = {
          query = "@function.inner";
          desc = "In Function";
        };
        "ac" = {
          query = "@class.outer";
          desc = "Around Class";
        };
        "ic" = {
          query = "@class.inner";
          desc = "In Class";
        };
        "aa" = {
          query = "@parameter.outer";
          desc = "Around Argument";
        };
        "ia" = {
          query = "@parameter.inner";
          desc = "In Argument";
        };
        "ar" = {
          query = "@assignment.rhs";
          desc = "Assignment RHS";
        };
      };
    };

    extraConfigLuaPre = ''
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    '';

    plugins.treesj = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.keys = [
        {
          __unkeyed-1 = "<leader>s";
          __unkeyed-2.__raw = ''
            function() require 'treesj'.toggle() end
          '';
        }
      ];
      settings = {
        use_default_keymaps = false;
        dot_repeat = true;
      };
    };

    plugins.nvim-ufo = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.event = "BufReadPre";
      lazyLoad.settings.before.__raw = ''
        function() require 'lz.n'.trigger_load 'nvim-treesitter' end
      '';
      lazyLoad.settings.keys = [
        {
          __unkeyed-1 = "zR";
          __unkeyed-2.__raw = ''
            function() require 'ufo'.openAllFolds() end
          '';
        }
        {
          __unkeyed-1 = "zM";
          __unkeyed-2.__raw = ''
            function() require 'ufo'.closeAllFolds() end
          '';
        }
      ];
    };
  };
}
