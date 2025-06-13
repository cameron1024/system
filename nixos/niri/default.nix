{pkgs, ...}: {
  imports = [../hyprland/fingerprint.nix];
  programs.niri.enable = true;

  services = {
    blueman.enable = true;
    # power-profiles-daemon.enable = true;
    upower.enable = true;
    cpupower-gui.enable = true;
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
  ];

  
}
