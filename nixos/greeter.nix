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
      "1E2326" # black    (Dark Hard bg_dim)
      "E67E80" # red
      "A7C080" # green
      "DBBC7F" # yellow
      "7FBBB3" # blue
      "D699B6" # magenta
      "83C092" # cyan
      "D3C6AA" # white/fg
      "374145" # bright black (Dark Hard bg2)
      "F85552" # bright red
      "8DA101" # bright green
      "DFA000" # bright yellow
      "3A94C5" # bright blue
      "DF69BA" # bright magenta
      "35A77C" # bright cyan
      "DFDDC8" # bright white
    ];

    services.greetd = {
      enable = true;
      settings.default_session.command = ''
        ${pkgs.tuigreet}/bin/tuigreet \
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
