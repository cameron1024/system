{pkgs, ...}: let
  package = with pkgs;
    if stdenv.isLinux
    then (wrapFirefox (firefox-unwrapped.override {pipewireSupport = true;}) {})
    else firefox;
in {
  programs.firefox = {
    enable = true;
    inherit package;

    profiles.default = {
      userChrome = builtins.readFile ./userChrome.css;
      settings = {
        "browser.gesture.swipe.left" = "";
        "browser.gesture.swipe.right" = "";
      };
    };
  };
}
