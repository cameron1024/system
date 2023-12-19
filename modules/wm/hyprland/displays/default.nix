{ pkgs, username, ... }:

{
  home-manager.users.${username} = {
    
    home.packages = with pkgs; [ kanshi brightnessctl ];
    
    wayland.windowManager.hyprland.settings = {
      # binde = [
      #   # ", XF86MonBrightnessUp, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
      # ];

      monitor = [
        "HDMI-A-1,3840x2160@60,0x500,1"
        "DP-2,2560x2880@60,3840x0,1"
      ];
    };

    # services.kanshi = {
    #   enable = false;
    #   systemdTarget = "hyprland-session.target";
    #
    #   profiles = {
    #
    #     undocked = {
    #       outputs = [
    #         {
    #           criteria = "eDP-1";
    #           status = "enable";
    #         }
    #       ];
    #     };
    #
    #     docked_open = {
    #       outputs = [
    #         # {
    #         #   criteria = "eDP-1";
    #         #   status = "disable";
    #         # }
    #
    #         {
    #           criteria = "BNQ BenQ PD2700U ETD6L00692SL0";
    #           status = "enable";
    #           position = "0,0";
    #           mode = "3840x2160@60Hz";
    #           transform = "90";
    #           scale = 1.0;
    #         } 
    #
    #         {
    #           criteria = "LG Electronics LG SDQHD 204NTDVCE898";
    #           status = "enable";
    #           position = "0,0";
    #           mode = "2560x2880@60";
    #         }
    #       ];
    #     };
    #
    #     # docked_closed = {
    #     #   outputs = [
    #     #     {
    #     #       criteria = "BNQ BenQ PD2700U ETD6L00692SL0";
    #     #       status = "enable";
    #     #       position = "0,0";
    #     #       mode = "3840x2160@60Hz";
    #     #       transform = "90";
    #     #     } 
    #     #
    #     #     {
    #     #       criteria = "LG Electronics LG SDQHD 204NTDVCE898";
    #     #       status = "enable";
    #     #       position = "2160,0";
    #     #       mode = "2560x28800";
    #     #     }
    #     #   ];
    #     # };
    #
    #
    #   };
    # };
  };
}
