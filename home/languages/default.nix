{pkgs, ...}: {
  imports = [
    ./rust.nix
    ./flutter.nix
    ./funky.nix
    ./python.nix
  ];

  home.packages = with pkgs; [
    rainfrog
    mask
    mprocs
    zig
    cue
  ];
}
