{ pkgs, username, ... }:

let
  kittyDropdown = pkgs.writeShellScriptBin "kitty-dropdown" (builtins.readFile ./kitty-dropdown.sh);
in

{

  environment.systemPackages = [ kittyDropdown ];
  
  home-manager.users.${username} = {
    
    wayland.windowManager.hyprland.settings = {

      animations = {
        animation = [
          "specialWorkspace, 1, 1, default, slidevert"
        ];
      };

      decoration = {
        dim_special = 0;
        blur = {
          enabled = false;
        };
      };

      dwindle = {
        special_scale_factor = 1;
      };

      exec-once = [
        "[workspace special] kitty"
      ];

      bind = [
        "SUPER, F12, togglespecialworkspace"
      ];
    };
  };
}

