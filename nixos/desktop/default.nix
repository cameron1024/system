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

  config.programs.coolercontrol.enable = true;
  config.environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.system}.default
  ];
}
