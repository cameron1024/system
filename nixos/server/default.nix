{
  pkgs,
  config,
  lib,
  ...
}: let
  isServer = config.networking.hostName == "mini";
in {
  imports = [./home-assistant.nix];
  config = lib.mkIf isServer {
    services.jellyfin = {
      # port = 8096
      enable = true;
      openFirewall = true;
    };

    services.immich = {
      enable = true;
      openFirewall = true;
      port = 2283;
      host = "0.0.0.0";
    };

    # services.homebox = {
    #   # port = 7745
    #   enable = true;
    #   settings = {
    #     "HBOX_WEB_HOST" = "0.0.0.0";
    #     "HBOX_OPTIONS_ALLOW_REGISTRATION" = "true";
    #   };
    # };

    # services.glance.enable = true;
    # services.glance.openFirewall = true;
    # services.glance.settings = {
    #   server.port = 11112;
    #   server.host = "0.0.0.0";
    #   theme = {
    #     background-color = "186 21 20";
    #     contrast-multiplier = 1.2;
    #     primary-color = "97 13 80";
    #   };
    # };

    services.static-web-server = {
      enable = true;
      listen = "0.0.0.0:8787";
      root = "/var/public";
      configuration.general.directory-listing = true;
    };

    networking.firewall.allowedTCPPorts = [8787];

    systemd.tmpfiles.rules = let
      image = pkgs.fetchurl {
        hash = "sha256-qmGcKVLd5ntWVfQWzwMXC3PPYjC+pUYe4Qp1PDxHNfE=";
        url = "https://drive.usercontent.google.com/download?id=1ZW7zL_YzqI6qqaaxdE6jBWFmobw-QhoT";
      };
    in [
      "L+ /var/public/everforest.png - - - - ${image}"
    ];

    services.homepage-dashboard = {
      enable = true;
      openFirewall = true;
      listenPort = 8082;
      allowedHosts = "mini:8082";
      environmentFile = "/etc/homepage-dashboard/.env";

      settings = {
        title = "Home Server";
        startUrl = "http://mini:8082";
        background.image = "http://mini:8787/everforest.png";
        background.blur = "sm";
        background.brightness = 50;
        theme = "dark";
        color = "teal";
      };

      # Keys are stored in a non-declarative file `/etc/homepage-dashboard/.env`
      services = [
        {
          "Smart Home" = [
            {
              "Home Assistant" = {
                href = "http://mini:8123";
                description = "Control Smart Home Devices";
                widgets = [
                  {
                    type = "homeassistant";
                    url = "http://mini:8123";
                    key = "{{HOMEPAGE_VAR_HOME_ASSISTANT_KEY}}";
                  }
                ];
              };
            }
          ];
        }

        {
          "Media" = [
            {
              "Jellyfin" = {
                href = "http://mini:8096";
                description = "Watch Films and TV Shows";
                widgets = [
                  {
                    type = "jellyfin";
                    url = "http://mini:8096";
                    key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
                  }
                ];
              };
            }
            {
              "Immich" = {
                href = "http://mini:2283";
                description = "Photo Management";
                widgets = [
                  {
                    type = "immich";
                    url = "http://mini:2283";
                    key = "{{HOMEPAGE_VAR_IMMICH_KEY}}";
                    version = 2;
                  }
                ];
              };
            }
          ];
        }
      ];

      widgets = [
        {
          resources = {
            cpu = true;
            disk = "/";
            memory = true;
          };
        }
        {
          openmeteo = {
            label = "London";
            # generic coords for london
            latitude = 51.5072;
            longitude = 0.1276;
            units = "metric";
            cache = 5;
            format.maximumFractionDigits = 0;
          };
        }
        {
          datetime = {
            text_size = "xl";
            format.timeStyle = "short";
            format.dateStyle = "short";
            format.hour12 = false;
          };
        }
      ];
    };
  };
}
