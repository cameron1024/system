{
  pkgs,
  lib,
  machine,
  ...
}: {
  home.packages = lib.mkIf machine.linux (with pkgs; [
    whatsapp-for-linux
    zapzap # PWA whatsapp
    slack
    discord
    zoom-us

    rquickshare
  ]);
}
