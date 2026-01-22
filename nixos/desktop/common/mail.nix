
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.services'.mail;
in {
  options.services'.mail = with lib; {
    enable = mkEnableOption "Mail services";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [himalaya protonmail-bridge];

    services.gnome.gnome-keyring.enable = true;
    systemd.user.services.protonmail-bridge = {
      enable = true;
      description = "Proton Mail Bridge";
      script = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive --log-level info";
      path = [pkgs.gnome-keyring];
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
    };
  };
}
