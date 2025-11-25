{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./common
    ./hyprland
    ./niri
  ];

  config.environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.system}.default
  ];
}
