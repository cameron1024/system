{ pkgs, ... }:

{
  home.packages = [
    (import ../../rust_packages/erdtree.nix { inherit pkgs; })
  ];

  xdg.configFile."erdtree/.erdtreerc".text = ''
    -s size
    --disk-usage logical
    --icons
    --size-left
    --prune
  '';
}
