{inputs, pkgs, ...}: {
  home.packages = [inputs.zed.packages.${pkgs.system}.default];

  home.shellAliases = {
    dz = "cargo run -- ~/projects/playground";
  };
}
