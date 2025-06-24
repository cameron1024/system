{pkgs, ...}: {
  imports = [../hyprland/fingerprint.nix];
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
}
