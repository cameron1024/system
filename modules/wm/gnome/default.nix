{ pkgs, config, lib, ... }:

{

  imports = [
    ../../workarounds/cursor_fix.nix
  ];
  /* dconf.settings = import ./dconf.nix; */
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
