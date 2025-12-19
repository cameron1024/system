{inputs, pkgs, ...}: {
  home.packages = [
    inputs.zed.packages.${pkgs.system}.default
    pkgs.claude-code
  ];

  home.shellAliases = {
    dz = "cargo run -- ~/projects/playground";
  };
}
