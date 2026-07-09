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
  adguardhome = config.services'.adguardhome.enable;
  ntopng = config.services'.ntopng.enable;
in {
  options.services'.dashboard.enable = mkOption {
    type = types.bool;
    default = any id [
      jellyfin
      immich
      home-assistant
      adguardhome
      ntopng
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
      "d /var/public 0755 root root - -"
      "L+ /var/public/everforest.png - - - - ${image}"

      # Ensure the (non-declarative) secrets file always exists, so the
      # services that read it don't fail to start before the first secret
      # deploy. `f` creates it empty if absent and never truncates an
      # existing file, so deployed secrets are preserved across rebuilds.
      "d /etc/homepage-dashboard 0755 root root - -"
      "f /etc/homepage-dashboard/.env 0600 root root - -"
    ];

    # Generate a themed WiFi QR code (Everforest palette) that the
    # static-web-server above hosts at http://mini:8787/wifi.svg.
    # The SSID and password are read at runtime from the existing
    # non-declarative secrets file so they never enter the nix store.
    systemd.services.wifi-qr = {
      description = "Generate themed WiFi QR code for the dashboard";
      wantedBy = ["multi-user.target"];
      after = ["systemd-tmpfiles-setup.service"];
      path = [pkgs.qrencode pkgs.gnused];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = "-/etc/homepage-dashboard/.env";
      };
      script = ''
        set -euo pipefail

        # Nothing to do until the WiFi secrets have been deployed.
        if [ -z "''${ROUTER_SSID:-}" ] || [ -z "''${ROUTER_WIFI_PASSWORD:-}" ]; then
          echo "WiFi SSID/password not set yet; skipping QR generation" >&2
          exit 0
        fi

        # Escape the characters that are special in the WIFI: URI scheme
        # (backslash, semicolon, comma, colon and double quote).
        escape() {
          printf '%s' "$1" | sed 's/\\/\\\\/g; s/;/\\;/g; s/,/\\,/g; s/:/\\:/g; s/"/\\"/g'
        }

        ssid=$(escape "$ROUTER_SSID")
        pass=$(escape "$ROUTER_WIFI_PASSWORD")

        qrencode \
          -t SVG \
          -o /var/public/wifi.svg \
          -l H \
          -s 5 \
          -m 1 \
          --svg-path \
          --foreground=d3c6aa \
          --background=2d353b \
          "WIFI:T:WPA;S:$ssid;P:$pass;;"

        # qrencode emits an <svg> with a fixed cm width/height AND
        # preserveAspectRatio="none". Inside the dashboard's fixed-height
        # iframe that both overflows (clipping the bottom) and would distort.
        # Strip the intrinsic width/height so the SVG scales to the iframe,
        # and set preserveAspectRatio so it stays square, centered, and
        # contained ("meet") rather than stretched.
        sed -i -E \
          -e 's/ (width|height)="[0-9.]+cm"//g' \
          -e 's/preserveAspectRatio="none"/preserveAspectRatio="xMidYMid meet"/' \
          /var/public/wifi.svg
      '';
    };

    # Regenerate the QR code whenever the secrets file changes.
    systemd.paths.wifi-qr = {
      wantedBy = ["multi-user.target"];
      pathConfig.PathChanged = "/etc/homepage-dashboard/.env";
    };

    # Restart homepage when its secrets file changes, so deployed/cycled
    # secrets are picked up automatically (systemd does not reload a service
    # when its EnvironmentFile changes).
    systemd.paths.homepage-dashboard-reload = {
      wantedBy = ["multi-user.target"];
      pathConfig.PathChanged = "/etc/homepage-dashboard/.env";
    };
    systemd.services.homepage-dashboard-reload = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart homepage-dashboard.service";
      };
    };

    services.homepage-dashboard = {
      enable = true;
      openFirewall = true;
      listenPort = 8082;
      allowedHosts = "mini:8082";
      environmentFiles = ["/etc/homepage-dashboard/.env"];

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
        ])
        ++ (optionals (adguardhome || ntopng) [
          {
            "Network" =
              []
              ++ (optionals adguardhome [
                {
                  "AdGuard Home" = {
                    href = "http://mini:4909";
                    description = "DNS Ad Blocking";
                    widgets = [
                      {
                        type = "adguard";
                        url = "http://mini:4909";
                        username = "admin";
                        password = "password";
                      }
                    ];
                  };
                }
              ])
              ++ (optionals ntopng [
                {
                  "ntopng" = {
                    href = "http://mini:3000";
                    description = "Network Traffic";
                  };
                }
              ])
              ++ [
                {
                  "Router" = {
                    href = "http://192.168.1.1";
                    description = "OpenWrt";
                    widgets = [
                      {
                        type = "openwrt";
                        url = "http://192.168.1.1";
                        username = "root";
                        password = "{{HOMEPAGE_VAR_ROUTER_PASSWORD}}";
                        interfaceName = "pppoe-wan";
                      }
                    ];
                  };
                }
              ];
          }
        ])
        ++ [
          {
            "WiFi" = [
              {
                "Network Access" = {
                  description = "Scan the QR code to join the WiFi";
                  widgets = [
                    {
                      type = "iframe";
                      name = "WiFi QR";
                      src = "http://mini:8787/wifi.svg";
                      classes = "h-96";
                      allowScrolling = "no";
                      referrerPolicy = "same-origin";
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
            uptime = true;
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
