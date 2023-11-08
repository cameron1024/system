{ pkgs, ... }:

let
  swaylock = pkgs.swaylock-effects;
  swayidle = pkgs.swayidle;
  screenOff = "hyprctl dispatch dpms off";
  screenOn = "hyprctl dispatch dpms on";

  lock = pkgs.writeShellScriptBin "lock-screen" ''
    echo "hello"
    ${swaylock}
  '';
in
{
  # actually allow swaylock to unlock the screen
  security.pam.services.swaylock = {};

  environment.systemPackages = [
    swaylock
    swayidle

    lock
  ];
 
  home-manager.users.cameron = {
    
    wayland.windowManager.hyprland.settings = {
      exec-once = [
        "swayidle -w timeout 300 ${lock} timeout 600 '${screenOff}' resume '${screenOn}'"
      ]; 

      bind = [
        "SUPER, w, exec, ${lock}"
      ];
    };
  };
}
