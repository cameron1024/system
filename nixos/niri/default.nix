{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  imports = [../hyprland/fingerprint.nix];

  options = {
    programs'.niri.enable = mkEnableOption "niri";
  };

  config = mkIf (config.programs'.niri.enable) {
    services'.fingerprint.enable = true;

    services'.tuigreet.enable = true;
    services'.tuigreet.command = mkForce "niri-session"    ;


    programs.niri.enable = true;

    services.blueman.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    services.cpupower-gui.enable = true;

    services.pulseaudio.enable = false;
    services.pulseaudio.support32Bit = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    environment.systemPackages = with pkgs; [
      vulkan-tools
      lutris
      pavucontrol
    ];
  };
}
