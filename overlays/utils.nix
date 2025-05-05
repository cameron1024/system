final: prev: {
  cams-utils = {
    hyprland = {
      mkColor = hex: "rgb(${prev.lib.strings.removePrefix "#" hex})";
    };
  };

  vimPlugins =
    prev.vimPlugins
    // {
      obsidian-nvim = prev.buildVimPlugin {
        pname = "obsidian.nvim";
        version = "3.11.0";
        src = prev.fetchFromGitHub {
          owner = "obsidian-nvim";
          repo = "obsidian.nvim";
          rev = "d6b996733e76549dbbf4741c16640caead1dc8e0";
          hash = "";
        };
      };
    };

  # everforest-gtk = prev.callPackage ./packages/everforest-gtk.nix {};
}
