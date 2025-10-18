{inputs, pkgs, ...}: {
  home.packages = [inputs.zed.packages.${pkgs.system}.default];

  xdg.desktopEntries.zed = {
    name = "zed";
    exec = "zeditor -- %u";
  };
}
