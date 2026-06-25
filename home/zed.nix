{inputs, pkgs, ...}: {
  home.packages = with pkgs; [
    inputs.zed.packages.${pkgs.system}.default
    sentry-cli
    bubblewrap
  ];

  home.sessionVariables = {
    "ZED_EXPERIMENTAL_A11Y" = 1;
  };

  home.shellAliases = {
    dz = "cargo run -- ~/projects/playground";
  };
}
