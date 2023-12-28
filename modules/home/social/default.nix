{ pkgs, ... }:

{
  home.packages = with pkgs; [
    slack
    whatsapp-for-linux
    telegram-desktop
    discord
  ];
}
