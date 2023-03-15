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
}
