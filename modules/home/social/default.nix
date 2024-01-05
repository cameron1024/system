{ pkgs, lib, isDarwin, ... }:

let
  packages = with pkgs; [
    slack
    whatsapp-for-linux
    telegram-desktop
    discord
  ];
in

{
  home.packages = lib.mkIf (!isDarwin) packages;
}
