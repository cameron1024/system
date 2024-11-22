{pkgs, ...}: {
  programs.wezterm = {
    enable = true;
    # package = pkgs.callPackage ./wezterm-pkg.nix {};
  };
}
