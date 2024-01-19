{ pkgs, ... }:

{

  imports = [
    ./cursor_fix.nix
    ./chinese-input.nix
  ];

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
  ];

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver = {
    layout = "gb";
    xkbVariant = "";
  };
}
