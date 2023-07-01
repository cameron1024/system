{ pkgs, ... }:

{
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.noisetorch.enable = true;

  environment.systemPackages = with pkgs; [
    pamixer
    pavucontrol
  ];
}
