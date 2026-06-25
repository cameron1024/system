{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
with lib; {
  options = {
    programs'.niri.enable = mkEnableOption "niri";
  };

  config = mkIf (config.programs'.niri.enable) {
    services'.fingerprint.enable = true;
    
    services'.tuigreet.enable = !config.services.displayManager.gdm.enable;
    services'.tuigreet.command = mkForce "niri-session";

    services'.desktop.enable = true;
    services'.desktop.oledMitigations.powerOffDisplayCommand = ''
      niri msg action power-off-monitors
    '';

    programs.niri.enable = true;
    programs.niri.useNautilus = true;

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    services.cpupower-gui.enable = true;

    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = ["*" "-32ac:0006"];
        settings = {
          main = {
            "capslock" = "overload(control, esc)";
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      vulkan-tools
      lutris
      pavucontrol
    ];

    # Screensharing fix.
    #
    # On niri the ScreenCast portal is provided by xdg-desktop-portal-gnome,
    # which forwards to niri's own org.gnome.Mutter.ScreenCast D-Bus API. That
    # backend's unit has `Requisite=graphical-session.target`, so it can only
    # be activated once the session target is up.
    #
    # The xdg-desktop-portal *frontend* is D-Bus-activated and only ordered
    # `After=dbus.service`. At login it gets activated early (by waybar/vicinae/
    # etc.) *before* graphical-session.target is reached. When it scans for a
    # ScreenCast implementation at that moment, the gnome backend isn't
    # activatable, so the frontend permanently drops the ScreenCast interface
    # (gtk doesn't implement it) and screensharing breaks in every app for the
    # rest of the session.
    #
    # Pull both into the graphical session, ordered after the target (and the
    # frontend after the gnome backend), so a usable ScreenCast backend exists
    # by the time the frontend probes for implementations.
    systemd.user.services = {
      xdg-desktop-portal-gnome = {
        after = ["graphical-session.target"];
        wantedBy = ["graphical-session.target"];
      };
      xdg-desktop-portal = {
        after = ["graphical-session.target" "xdg-desktop-portal-gnome.service"];
        wantedBy = ["graphical-session.target"];
      };
    };
  };
}
