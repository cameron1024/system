{ pkgs, ... }:

{

  home-manager.users.cameron = {
    xdg.configFile."waybar/config".source = ./config.json; 
    xdg.configFile."waybar/style.css".source = ./style.css;
  };
  
  environment.systemPackages = with pkgs; [
    waybar
  ];
}
