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
    zapzap # PWA whatsapp
    slack
    discord

    rquickshare
    deluge
    google-chrome

    signal-cli
    signal-desktop

    zathura

    protonmail-desktop
    proton-pass
    proton-pass-cli
    keyutils
    neomutt
    thunderbird

    zulip
    zulip-term
  ]);

  

}
