{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.services'.streamdeck;
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

      # Map your device's serial number to a default page so it loads on plug-in.
      # Find the serial with: streamcontroller-cli device list
      # defaultPages."AL22K2C74512" = "Main";

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
          dials = {
            "0x0".states."0".labels.center.text = "Vol";
          };
          # touchscreens = { "0x0".states."0" = { ... }; };
        };
      };
    };
  };
}
