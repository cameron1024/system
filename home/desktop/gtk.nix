{
  pkgs,
  config,
  lib,
  ...
}:
with lib; {
  options = {
    gtk'.enable = mkEnableOption "Everforest GTK";
  };
  
  config = lib.mkIf config.gtk'.enable {
    gtk = {
      enable = false;

      theme.name = "Everforest-Dark-BL";
      theme.package = pkgs.everforest-gtk-theme;

      font.name = "Fira Sans";
      font.package = pkgs.fira;

      cursorTheme.name = "Graphite dark Cursors";
      cursorTheme.package = pkgs.graphite-cursors;

      iconTheme.name = "Adwaita";
      iconTheme.package = pkgs.adwaita-icon-theme;
    };
  };
}
