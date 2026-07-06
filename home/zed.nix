{inputs, pkgs, lib, config, ...}:
lib.mkIf config.services'.desktop.enable {
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
