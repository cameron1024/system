{pkgs, ...}: let
  enable = true;
  lazyLoad = {
    enable = true;
    settings.event = "BufReadPost";
  };
  # TODO
  # tree-climber = pkgs.vimUtils.buildVimPlugin {
  #   name = "tree-climber";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "drybalka";
  #     repo = "tree-climber.nvim";
  #     rev = "9b0c8c8358f575f924008945c74fd4f40d814cd7";
  #     hash = "sha256-iivP8g8aSeEnS/dBcb0sg583ijzhWFA7w430xWPmjF0=";
  #   };
  #   nvimRequireCheck = "tree-climber";
  # };
in {
  programs.nixvim = {
    # extraPlugins = [tree-climber];
    # extraConfigLuaPost = ''
    #   local tree_climber_keymap = require 'lz.n'.keymap {
    #     "tree-climber",
    #   }
    #   tree_climber_keymap.set(
    #     {"n", "v", "o"},
    #     "<M-l>",
    #     function() require 'lz.n'.load 'tree-climber'.goto_next() end
    #   )
    #   tree_climber_keymap.set(
    #     {"n", "v", "o"},
    #     "<M-h>",
    #     function() require 'lz.n'.load 'tree-climber'.goto_prev() end
    #   )
    #   tree_climber_keymap.set(
    #     {"n", "v", "o"},
    #     "<M-k>",
    #     function() require 'lz.n'.load 'tree-climber'.goto_parent() end
    #   )
    #   tree_climber_keymap.set(
    #     {"n", "v", "o"},
    #     "<M-j>",
    #     function() require 'lz.n'.load 'tree-climber'.goto_child() end
    #   )
    #   tree_climber_keymap.set(
    #     {"n", "v", "o"},
    #     "<SM-l>",
    #     function() require 'lz.n'.load 'tree-climber'.swap_next() end
    #   )
    #   tree_climber_keymap.set(
    #     {"n", "v", "o"},
    #     "<SM-h>",
    #     function() require 'lz.n'.load 'tree-climber'.swap_prev() end
    #   )
    #   tree_climber_keymap.set(
    #     {"n", "v", "o"},
    #     "<leader>`",
    #     function() require 'lz.n'.load 'tree-climber'.highlight_node() end
    #   )
    # '';
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
      inherit enable lazyLoad;
    };

    plugins.treesitter-textobjects = {
      inherit enable;

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
      inherit enable;
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
      inherit enable;
      lazyLoad.enable = true;
      lazyLoad.settings.event = "BufReadPost";
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
