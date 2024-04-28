{
  pkgs,
  lib,
  ...
}: let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --cmd Hyprland";

  grubTheme = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "grub";
    rev = "88f6124757331fd3a37c8a69473021389b7663ad";
    hash = "";
  };
in {
  console.colors = [
    "1e1e2e" # base
    "181825" # mantle
    "313244" # surface0
    "45475a" # surface1
    "585b70" # surface2
    "cdd6f4" # text
    "f5e0dc" # rosewater
    "b4befe" # lavender
    "f38ba8" # red
    "fab387" # peach
    "f9e2af" # yellow
    "a6e3a1" # green
    "94e2d5" # teal
    "89b4fa" # blue
    "cba6f7" # mauve
    "f2cdcd" # flamingo
  ];

  boot.loader.grub.theme = grubTheme;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = tuigreet;
      };
    };
  };

  # prevent text overwriting interface
  systemd.services.greetd = {
    unitConfig = {
      After = lib.mkOverride 0 ["multi-user.target"];
    };

    serviceConfig = {
      Type = "idle";
    };
  };
}
