{
  pkgs,
  lib,
  ...
}: let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --cmd Hyprland";
in {
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
