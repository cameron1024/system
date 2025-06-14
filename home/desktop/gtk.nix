{pkgs, ...}: {
  gtk = {
    enable = true;

    theme.name = "Everforest-Dark-BL";
    theme.package = pkgs.everforest-gtk-theme;

    font.name = "Fira Sans";
    font.package = pkgs.fira;

    cursorTheme.name = "Graphite dark Cursors";
    cursorTheme.package = pkgs.graphite-cursors;

    iconTheme.name = "Adwaita";
    iconTheme.package = pkgs.adwaita-icon-theme;
  };
}
