{ pkgs, lib, config, ... }:

let
  hyprlandWorkspaces = pkgs.rustPlatform.buildRustPackage rec {
    pname = "hyprland-workspaces";
    version = "1.2.0";
    src = pkgs.fetchFromGitHub {
      owner = "FieldofClay";
      repo = pname;
      rev = "v1.2.0";
      hash = "sha256-qJDpp6q13zYfQCU1VIHc4t0bPuilglIKjqOLuUrU3lM=";
    };
    cargoHash = "sha256-crvGsdBqV/Xy25o4ddxpSCdbOiWxSqu8ncCixd8O5zc=";
  };

in
{
  imports = [
    ../common/monitoring.nix
    ../sway/wofi
    ../common/rofi
    ../common/eww-bar
    ../sway/waybar

    ./lock
    # ./kanshi
    ./sound.nix
  ];

  # programs.wofi.colors = colors;
  programs.customWaybar.enable = true;
  programs.hyprland.enable = true;
  programs.rofi.enable = true;


  home-manager.users.cameron = {
    xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
    xdg.configFile."hypr/mocha.conf".source = ./mocha.conf;

    programs.fish.shellAbbrs."hr" = "hyprctl reload";
  };

  environment.systemPackages = with pkgs; [
    swayidle
    swaybg

    swayimg

    brightnessctl
    playerctl
    blueberry

    # screenies
    slurp
    grim

    wl-clipboard

    hyprlandWorkspaces

    wev

    xdg-utils


  ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  security.rtkit.enable = true;

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
