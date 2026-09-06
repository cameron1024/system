{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.services'.streamdeck;
  ids = import ../../../ids.nix;
  officeLight = builtins.head ids.homeAssistant.entities.lights.office;
in {
  imports = [
    inputs.streamcontroller.homeManagerModules.default
  ];

  options.services'.streamdeck = {
    enable = mkEnableOption "StreamController (Elgato Stream Deck) declarative config";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.streamcontroller];

    # Declarative StreamController config via the streamcontroller-nix HM module.
    # Note: this drives the 8 buttons declaratively. The 4 dials and touchscreen
    # strip on the Stream Deck Plus are supported by the app, but the declarative
    # schema only covers `keys` for now - configure those in the GUI.
    #
    # USB access (udev) is set up at the system level, see nixos/default.nix.
    programs.streamcontroller = {
      enable = true;

      # Map the device's serial number to a default page so it loads on plug-in.
      defaultPages."7L1A07847" = "Main";

      pages.Main = {
        brightness.value = 100;

        # Stream Deck Plus: 8 buttons in a 4x2 grid, addressed COLxROW (0-indexed).
        #   0x0  1x0  2x0  3x0
        #   0x1  1x1  2x1  3x1
        #
        # These use com_core447_OSPlugin (core, no plugin install needed) plus
        # playerctl, which is already installed by the niri module.
        keys = {
          "0x0".states."0" = {
            label.center.text = "Prev";
            actions = [
              {
                id = "com_core447_OSPlugin::RunCommand";
                settings.command = "${pkgs.playerctl}/bin/playerctl previous";
              }
            ];
          };
          "1x0".states."0" = {
            label.center.text = "Play";
            actions = [
              {
                id = "com_core447_OSPlugin::RunCommand";
                settings.command = "${pkgs.playerctl}/bin/playerctl play-pause";
              }
            ];
          };
          "2x0".states."0" = {
            label.center.text = "Next";
            actions = [
              {
                id = "com_core447_OSPlugin::RunCommand";
                settings.command = "${pkgs.playerctl}/bin/playerctl next";
              }
            ];
          };

          "0x1".states."0" = {
            label.center.text = "Launch";
            actions = [
              {
                id = "com_core447_OSPlugin::RunCommand";
                settings.command = "vicinae";
              }
            ];
          };

          # Home Assistant actions need the "Home Assistant" plugin (gensyn's
          # HomeAssistantPlugin) installed once via the in-app store, and the
          # HA host/port/token configured in its plugin settings (Settings ->
          # Plugins -> Home Assistant). The token is a secret, so it stays in
          # the GUI-managed settings rather than here.
          "3x1".states."0" = {
            label.center.text = "Office";
            actions = [
              {
                id = "HomeAssistantPlugin::PerformAction";
                settings = {
                  entity = {
                    domain = "light";
                    entity = officeLight;
                  };
                  action = {
                    action = "toggle";
                    parameters = {};
                  };
                };
              }
            ];
          };
        };

        # Escape hatch: anything in `extraConfig` is merged verbatim into the
        # page's JSON (the upstream module does `pageJson // extraConfig`).
        #
        # The structured `keys` option above only models the 8 buttons. The
        # Plus's dials and touchscreen live in separate top-level JSON sections
        # ("dials" and "touchscreens"), so we inject them raw here.
        #
        # NOTE: unlike the structured options, this is the on-disk JSON shape -
        # use the raw key names ("labels", "font-size", ...). The reliable way
        # to get an exact dial/action blob is to configure it once in the GUI,
        # then run `streamcontroller-cli page inspect Main` and paste it here.
        extraConfig = {
          # 4 dials, addressed COLxROW like the keys (single row).
          # NOTE: dials are keyed by plain index ("0".."3"), unlike keys
          # which use COLxROW. Shape captured from a GUI-configured dial via
          # the on-disk pages/Main.json.
          dials = {
            "0x0".states."0".labels.center.text = "Vol";
            # Office light brightness: rotate = +/-10%, press = toggle.
            "3".states."0" = {
              actions = [
                {
                  id = "HomeAssistantPlugin::LevelDial";
                  settings = {
                    entity = {
                      version = 1;
                      domain = "light";
                      entity = officeLight;
                    };
                    level = {
                      step = 10;
                      label = "";
                      # ms to coalesce rotation ticks before sending to HA.
                      # Lower = snappier, higher = fewer commands to the Hue
                      # bridge (less rate-limit dropping). Range 0-500.
                      batch_delay = 50.0;
                      customizations = [];
                    };
                    version = 1;
                  };
                  comment = "Office";
                }
              ];
              image-control-action = 0;
              label-control-actions = [0 0 0];
              background-control-action = 0;
            };
          };
          # touchscreens = { "0x0".states."0" = { ... }; };
        };
      };
    };
  };
}
