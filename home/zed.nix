{pkgs, ...}: {
  home.packages = with pkgs; [zed-editor];

  xdg.desktopEntries.zed = {
    name = "zed";
    exec = "zeditor -- %u";
  };
}
