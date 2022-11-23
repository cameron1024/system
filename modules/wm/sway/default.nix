{ config, pkgs, lib, ... }:

let
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text =
      let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      in
      ''
        export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
        gnome_schema=org.gnome.desktop.interface
        gsettings set $gnome_schema gtk-theme 'Dracula'
      '';
  };
  colors = (import ../../home/colorschemes.nix).gruvbox;
in
{

  imports = [
    ./wofi
    ./waybar
  ];

  programs.wofi.colors = colors;
  programs.customWaybar.enable = true;

  environment.systemPackages = with pkgs; [
    dbus-sway-environment
    configure-gtk

    swaylock-effects
    swayidle

    swayr

    pamixer
    pavucontrol
    brightnessctl
    playerctl
    blueberry
  ];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  home-manager.users.cameron = {
    xdg.configFile."sway/config".source = ./config;
  };

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
