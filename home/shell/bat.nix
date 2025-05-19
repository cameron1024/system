{
  lib,
  machine,
  pkgs,
  ...
}: {
  config = lib.mkIf machine.linux {
    home.shellAliases = {
      "cat" = "bat";
    };
    programs.bat = {
      enable = true;
      themes = {
        everforest = {
          src = pkgs.everforest-collection;
          file = "bat/everforest-soft.tmTheme";
        };
      };
    };
  };
}
