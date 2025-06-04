{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    package = with pkgs; (wrapFirefox (firefox-unwrapped.override {pipewireSupport = true;}) {});

    profiles.default = {
      userChrome = builtins.readFile ./userChrome.css;
      settings = {
        "browser.gesture.swipe.left" = "";
        "browser.gesture.swipe.right" = "";
      };
    };
  };
}
