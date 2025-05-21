{pkgs, ...}: {
  home.packages = with pkgs; [
    nh
    nix-tree
  ];
}
