{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
with lib;
let
  browser = "firefox.desktop";
  mail = "proton-mail.desktop";
in
{
  imports = [
    # inputs.noctalia.homeModules.default

    ./ai.nix
    ./audio.nix
    ./gtk.nix
    ./lock
    # ./noctalia.nix
    ./one-password.nix
    ./picker.nix
    ./power-menu.nix
    ./waybar
    ./walker.nix
    ./sherlock.nix
    ./rofi
    ./wallpaper.nix
    ./vicinae
    ./streamdeck
  ];

  options.services'.desktop = {
    enable = mkEnableOption "desktop";

    launch-at-startup =
      with types;
      mkOption {
        default = [ ];
        type = listOf (submodule {
          options = {
            program = mkOption { type = str; };
            args = mkOption {
              type = listOf str;
              default = [ ];
            };
          };
        });
      };
  };

  config = mkIf config.services'.desktop.enable {
    gtk'.enable = true;

    programs'.waybar.enable = true;
    programs'.waybar.enableNiriIntegration = true;
    programs'.rofi.enable = true;
    programs'.departure.enable = true;

    services.darkman.enable = true;

    xdg.enable = true;
    xdg.userDirs.enable = true;
    xdg.userDirs.setSessionVariables = true;

    xdg.mimeApps = {
      enable = true;
      defaultApplications =
        genAttrs [
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/chrome"
          "text/html"
          "application/xhtml+xml"
          "application/x-extension-htm"
          "application/x-extension-html"
          "application/x-extension-shtml"
          "application/x-extension-xhtml"
          "application/x-extension-xht"
        ] (_: [ browser ])
        // {
          "x-scheme-handler/mailto" = [ mail ];
          "x-scheme-handler/proton-inbox" = [ mail ];
          "x-scheme-handler/slack" = [ "slack.desktop" ];
          "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
          "x-scheme-handler/delta-trunk" = [ "delta-trunk.desktop" ];
          "x-scheme-handler/delta" = [ "delta-stable.desktop" ];
        };
    };

    # scripts/update-delta.sh installs these aliases separately so system builds never
    # need credentials or pre-seeded private Delta release assets.
    xdg.desktopEntries = {
      # The CLI package doesn't ship the handler created by Claude's own installer.
      claude-code-url-handler = {
        name = "Claude Code URL Handler";
        exec = "${pkgs.claude-code}/bin/claude --handle-uri %u";
        noDisplay = true;
        mimeType = [ "x-scheme-handler/claude-cli" ];
      };
      delta-trunk = {
        name = "Delta Trunk";
        exec = "delta open %U";
        terminal = false;
        categories = [ "Development" "IDE" "TextEditor" ];
        mimeType = [ "x-scheme-handler/delta-trunk" ];
        settings.StartupWMClass = "dev.zed.DeltaTrunk";
      };
      delta-stable = {
        name = "Delta";
        exec = "delta-stable open %U";
        terminal = false;
        categories = [ "Development" "IDE" "TextEditor" ];
        mimeType = [ "x-scheme-handler/delta" ];
        settings.StartupWMClass = "dev.zed.Delta";
      };
    };

    home.packages =
      if pkgs.stdenv.isLinux then
        (with pkgs; [
          libnotify
          wl-clipboard
          google-chrome
          inputs.hexecute.packages.${pkgs.system}.default
          s-tui
          inputs.handy.packages.${pkgs.system}.default
          wtype
          dotool
        ])
      else
        [ ];
  };
}
