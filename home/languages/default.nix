{pkgs, ...}: {
  imports = [./rust.nix ./flutter.nix ./funky.nix];

  home.packages = with pkgs; [
    rainfrog
    mask
    mprocs
    zig
  ];
}
