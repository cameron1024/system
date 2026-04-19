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
  xdg.configFile."zathura/zathurarc".text = ''
    # Everforest Dark Medium — only colour & font overrides
    set font "Josefin Sans 18"

    # Default UI
    set default-fg "#d3c6aa"
    set default-bg "#1e2326"

    # Status bar
    set statusbar-fg "#d3c6aa"
    set statusbar-bg "#343f44"

    # Input bar
    set inputbar-fg "#d3c6aa"
    set inputbar-bg "#343f44"

    # Notifications
    set notification-fg "#d3c6aa"
    set notification-bg "#343f44"
    set notification-error-fg "#e67e80"
    set notification-error-bg "#343f44"
    set notification-warning-fg "#dbbc7f"
    set notification-warning-bg "#343f44"

    # Completion menu
    set completion-fg "#d3c6aa"
    set completion-bg "#3d484d"
    set completion-highlight-fg "#2d353b"
    set completion-highlight-bg "#a7c080"
    set completion-group-fg "#a7c080"
    set completion-group-bg "#3d484d"

    # Search highlighting
    set highlight-color "#a7c080"
    set highlight-active-color "#83c092"
    set highlight-transparency 0.4

    # Document dark mode (toggle with Ctrl+R)
    set recolor-lightcolor "#1e2326"
    set recolor-darkcolor "#d3c6aa"
    set recolor-keephue true
    set recolor-reverse-video true
    set recolor false

    # Index mode
    set index-fg "#d3c6aa"
    set index-bg "#2d353b"
    set index-active-fg "#2d353b"
    set index-active-bg "#a7c080"

    # Loading indicator
    set render-loading-bg "#1e2326"
    set render-loading-fg "#d3c6aa"
  '';

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
