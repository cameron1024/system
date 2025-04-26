{
  pkgs,
  lib,
  ...
}: let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --cmd Hyprland";
in {
  console.colors = [
    "343F44"
    "E67E80"
    "A7C080"
    "DBBC7F"
    "7FBBB3"
    "D699B6"
    "83C092"
    "D3C6AA"
    "5C6A72"
    "F85552"
    "8DA101"
    "DFA000"
    "3A94C5"
    "DF69BA"
    "35A77C"
    "DFDDC8"
  ];

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
