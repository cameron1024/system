{
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.shellAliases = {
      "cat" = "bat";
    };
    # programs.bat = {
    #   enable = true;
    #   themes = {
    #     everforest = {
    #       src = pkgs.everforest-collection;
    #       file = "bat/everforest-soft.tmTheme";
    #     };
    #   };
    # };
  };
}
