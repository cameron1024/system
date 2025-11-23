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
      enable = true;

      theme.name = "Everforest-Dark-BL";
      theme.package = pkgs.everforest-gtk-theme;

      # font.name = "Fira Sans";
      # font.package = pkgs.fira;
      font.name = "Josefin Sans";
      font.package = pkgs.josefin;

      # cursorTheme.name = "Graphite dark Cursors";
      # cursorTheme.package = pkgs.graphite-cursors;
      cursorTheme.name = "Everforest cursors";
      cursorTheme.package = pkgs.everforest-cursors;

      iconTheme.name = "Adwaita";
      iconTheme.package = pkgs.adwaita-icon-theme;
      #
      # gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      # gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };
  };
}
