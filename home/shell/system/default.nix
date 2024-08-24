{pkgs, ...}: {
  home.packages = with pkgs; [
    bottom
    killall

  ];
}
