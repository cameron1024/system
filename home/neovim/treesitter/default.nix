{pkgs, ...}: let
  treesitter-snap = pkgs.tree-sitter.buildGrammar {
    language = "snap";
    version = "0.0.0";
    src = pkgs.fetchFromGitHub {
      owner = "cameron1024";
      repo = "treesitter-snap-grammar";
      rev = "59510a5033c01626a1b435dd9eb2d01d2d7f63b9";
      hash = "sha256-wTzbgjWr5ec+jEp5LLPMo1jnDWNV78qBY+/sGiry1/c=";
    };
  };

  textobjectKeymap = key: capture: {
    inherit key;
    mode = ["x" "o"];
    action.__raw = ''
      function()
        require "nvim-treesitter-textobjects.select".select_textobject("${capture}", "textobjects")
      end
    '';
  };
in {
  imports = [
    ./injections.nix
    ./modules.nix
    ./treewalker.nix
  ];

  extraFiles."after/ftplugin/snap.lua".text =
    /*
    lua
    */
    ''
      local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
      parser_config.snap = {
        install_info = {
          files = {"src/parser.c"},
          url = "${treesitter-snap}",
        },
      }

      vim.treesitter.start()
    '';
  filetype.extension."snap" = "snap";
  plugins.treesitter = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.event = "BufReadPost";

    grammarPackages =
      pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars
      ++ [
        treesitter-snap
      ];

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
  };

  plugins.treesitter-textobjects = {
    enable = true;
    settings = {
      select.enable = true;
      select.disable = ["dart"];
      select.lookahead = true;
      select.keymaps = {
      };
    }; };

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

  plugins.aerial = {
    enable = true;
  };

  keymaps = [
    {
      key = "<C-s>";
      action = "<cmd>AerialToggle<cr>";
    }
    (textobjectKeymap "af" "@function.outer")
    (textobjectKeymap "if" "@function.inner")
    (textobjectKeymap "ac" "@class.outer")
    (textobjectKeymap "ic" "@class.inner")
    (textobjectKeymap "aa" "@parameter.outer")
    (textobjectKeymap "ia" "@parameter.inner")
    (textobjectKeymap "ar" "@assignment.rhs")
    (textobjectKeymap "at" "@type")

  ];
}
