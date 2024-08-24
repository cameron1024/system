{pkgs, ...}: {
  home.packages = with pkgs; [
    nh
  ];
}
