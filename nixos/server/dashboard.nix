{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  jellyfin = config.services'.jellyfin.enable;
  immich = config.services'.immich.enable;
  home-assistant = config.services'.home-assistant.enable;
in {
  options.services'.dashboard.enable = mkOption {
    type = types.bool;
    default = any id [
      jellyfin
      immich
      home-assistant
    ];
  };

  config = lib.mkIf config.services'.dashboard.enable {
    # host background image for dashboard
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
      services =
        []
        ++ (optionals home-assistant [
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
        ])
        ++ (optionals (jellyfin || immich) [
          {
            "Media" =
              []
              ++ (optionals jellyfin [
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
              ])
              ++ (optionals immich [
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
              ]);
          }
        ]);

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
