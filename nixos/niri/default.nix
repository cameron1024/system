{pkgs, ...}: {
  imports = [../hyprland/fingerprint.nix];
  programs.niri.enable = true;

  services.blueman.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.cpupower-gui.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    pulseaudio.support32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    lutris
    pavucontrol
  ];
}
