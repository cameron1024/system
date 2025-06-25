{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options = {
    services'.tuigreet.enable = mkEnableOption "tuigreet";
    services'.tuigreet.command = mkOption {
      type = types.str;
      description = "The command to launch on successful login";
    };
  };

  config = mkIf (config.services'.tuigreet.enable) {
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
      settings.default_session.command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
          --asterisks \
          --time \
          --cmd ${config.services'.tuigreet.command}
      '';
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
  };
}
