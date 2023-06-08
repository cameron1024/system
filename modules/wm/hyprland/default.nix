{ pkgs, lib, config, ...}:

{
  imports = [
    ../sway/wofi
    ../sway/waybar
  ];

  # programs.wofi.colors = colors;
  programs.customWaybar.enable = true;
  programs.hyprland.enable = true;

  home-manager.users.cameron = {
    xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
    xdg.configFile."hypr/mocha.conf".source = ./mocha.conf;
  };

  environment.systemPackages = with pkgs; [
    swaylock-effects
    swayidle
    swaybg
    swayr

    pamixer
    pavucontrol
    brightnessctl
    playerctl
    blueberry

    # screenies
    slurp
    grim

    wl-clipboard
  ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.hardware.bolt.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  security.pam.services.swaylock = {
    text = "auth include login";
  };
}
