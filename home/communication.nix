{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  slack =
    if osConfig == null
    then pkgs.wrapWithNixGL {name = "slack";}
    else pkgs.slack;
in {
  home.packages = lib.mkIf pkgs.stdenv.isLinux (with pkgs; [
    whatsapp-for-linux
    zapzap # PWA whatsapp
    slack
    discord

    rquickshare
    deluge
    google-chrome

    signal-cli
    signal-desktop
  ]);
}
