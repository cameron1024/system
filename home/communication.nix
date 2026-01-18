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
    # protonmail-bridge
    # protonmail-bridge-gui
    proton-pass
    # proton-pass-cli
    neomutt
    himalaya
    thunderbird

    zulip
    zulip-term
  ]);

  

}
