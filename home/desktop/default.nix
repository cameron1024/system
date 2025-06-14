{pkgs, ...}: {
  imports = [./quickshell ./power-menu.nix ./gtk.nix];
  programs.obs-studio.enable = true;

  home.packages = with pkgs; [
    plover.dev
    libnotify
  ];
}
