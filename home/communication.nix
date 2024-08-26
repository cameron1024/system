{pkgs, ...}: {
  home.packages = with pkgs; [
    whatsapp-for-linux
    zapzap  # PWA whatsapp
    slack

    rquickshare
  ];
}
