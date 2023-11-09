{ pkgs, ... }:

let
  swaylock = pkgs.swaylock-effects;
  screenOff = "hyprctl dispatch dpms off";
  screenOn = "hyprctl dispatch dpms on";
in
{
  # actually allow swaylock to unlock the screen
  security.pam.services.swaylock = {};
 
  home-manager.users.cameron = {

    programs.swaylock = {
      enable = true;   
      package = swaylock;
      settings = {
        image = "/home/cameron/system/assets/background.jpg";
        effect-blur = "20x20";

        ring-color = "b4befe";
        ring-clear-color = "f5e0dc";
        ring-wrong-color = "eba0ac";
        separator-color = "eba0ac";
        text-color = "cdd6f4";
        text-clear-color = "f5e0dc";
        text-wrong-color = "eba0ac";
        key-hl-color="a6e3a1";
      };
    };

    services.swayidle = {
      enable = true;
      timeouts = [
        { timeout = 300; command = "${swaylock}/bin/swaylock"; }
        { timeout = 600; command = screenOff; resumeCommand = screenOn; }
      ];
    };
    
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, escape, exec, swaylock"
      ];
    };
  };
}
