{
  pkgs,
  lib,
  ...
}: {
  home.packages = lib.mkIf pkgs.stdenv.isLinux (with pkgs; [
    whatsapp-for-linux
    zapzap # PWA whatsapp
    slack
    discord

    rquickshare
    deluge
  ]);
}
