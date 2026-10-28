{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./fingerprint.nix
    ./fonts.nix
    
    
    
    ./mail.nix
  ];

  options.services'.desktop = let
    numberType = types.oneOf [types.int types.float];
    displayType = types.submodule {
      options = {
        name = mkOption {
          type = types.str;
          description = "The name of the monitor";
          example = "DP-1";
        };

        resolution.width = mkOption {
          type = types.ints.positive;
        };
        resolution.height = mkOption {
          type = types.ints.positive;
        };

        position.x = mkOption {
          type = types.int;
        };
        position.y = mkOption {
          type = types.int;
        };

        refreshRate = mkOption {
          type = numberType;
        };

        scale = mkOption {
          type = numberType;
        };

        oled = mkOption {
          type = types.bool;
          description = "Whether this display is OLED (and therefore requires burn-in mitigation)";
        };

        auxiliary = mkOption {
          type = types.bool;
          default = false;
        };
      };
    };
  in {
    enable = mkEnableOption "basic desktop functionality";

    isLaptop = mkEnableOption {
      type = types.bool;
      default = false;
    };

    displays = mkOption {
      type = types.addCheck (types.listOf displayType) (list: length list > 0);
    };

    oledMitigations.enable = mkOption {
      type = types.bool;
      default = any (display: display.oled) config.services'.desktop.displays;
      description = ''
        Whether to enable burn-in mitigations for OLED screens.
        Defauts to true if there is at least one monitor that is OLED.
      '';
    };
    oledMitigations.powerOffDisplayCommand = mkOption {
      type = types.str;
      description = "A command that will power off the displays";
    };
  };

  config = mkIf config.services'.desktop.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-gtk
        qt6Packages.fcitx5-chinese-addons
      ];
      fcitx5.waylandFrontend = true;
      fcitx5.settings = {
        globalOptions."Hotkey/TriggerKeys"."0" = "Super+slash";
        # Their popups (clipboard history on Ctrl+;, quick phrase on Super+; and Super+`) are
        # unwanted, and steal myshell's binds.
        globalOptions."Behavior/DisabledAddons" = {
          "0" = "clipboard";
          "1" = "quickphrase";
        };
        inputMethod = {
          "GroupOrder"."0" = "Default";
          "Groups/0" = {
            "Name" = "Default";
            "Default Layout" = "gb";
            "DefaultIM" = "pinyin";
          };
          "Groups/0/Items/0"."Name" = "keyboard-gb";
          "Groups/0/Items/1" = {
            "Name" = "pinyin";
            "Layout" = "gb";
          };
        };
      };
    };
    users.users.cameron = {
      isNormalUser = true;
      description = "cameron";
      extraGroups = ["networkmanager" "wheel" "audio" "video" "sound" "input" "dialout"];
    };

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    # Logitech device manager (enables hi-res scrolling, SmartShift, etc.)
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true; # Solaar GUI

    # WebHID access for NuPhy keyboards (NuPhy IO web configurator). Must sort
    # before 73-seat-late.rules, which applies uaccess ACLs; extraRules lands in
    # 99-local.rules, which is too late.
    services.udev.packages = [
      (pkgs.writeTextDir "etc/udev/rules.d/70-nuphy.rules" ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="19f5", TAG+="uaccess"
      '')
    ];

    services.flatpak.enable = true;
    services.snap.enable = true;

    # Desktops shouldn't block boot waiting for the network to be "online".
    # NetworkManager-wait-online otherwise sits in the pre-greeter critical path
    # for a couple of seconds. Anything that genuinely needs the network starts
    # on its own once connectivity arrives.
    systemd.services.NetworkManager-wait-online.enable = false;

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    services'.mail.enable = true;

    services.gnome.at-spi2-core.enable = true;
    programs.dconf.enable = true;
    programs.dconf.profiles.user.databases = [{
      settings."org/gnome/desktop/interface".toolkit-accessibility = true;
    }];
    environment.systemPackages = with pkgs; [
      kdePackages.accessibility-inspector
      accerciser
      orca
    ];
  };
}

