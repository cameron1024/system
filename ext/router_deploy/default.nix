# NixOS module for router_deploy: declarative OpenWrt router deployment.
#
# The options below are lowered to a JSON config file in the nix store and
# baked into the `router-deploy` wrapper. Secrets are never stored here —
# only Proton Pass references (pass://SHARE_ID/ITEM_ID[/FIELD]), which the
# binary resolves at runtime via `pass-cli`.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.services'.router-deploy;

  package = pkgs.callPackage ./build.nix {
    craneLib = inputs.crane.mkLib pkgs;
  };

  configJson = pkgs.writeText "router-deploy-config.json" (builtins.toJSON {
    inherit
      (cfg)
      host
      staticLeases
      serviceDomains
      wanBlockedMacs
      secrets
      ;
  });

  # The binary reads its config as JSON on stdin.
  wrapped = pkgs.writeShellScriptBin "router-deploy" ''
    exec ${lib.getExe package} "$@" < ${configJson}
  '';
in {
  options.services'.router-deploy = {
    enable = lib.mkEnableOption "the router-deploy CLI";

    host = lib.mkOption {
      type = lib.types.str;
      default = "root@192.168.1.1";
      description = "SSH destination of the OpenWrt router.";
    };

    staticLeases = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Hostname for the lease (also the uci section name).";
          };
          mac = lib.mkOption {
            type = lib.types.str;
            description = "MAC address of the device.";
          };
          ip = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address to assign.";
          };
        };
      });
      default = [];
      description = "Static DHCP (mac -> ip) assignments.";
    };

    serviceDomains = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        "home.lan" = "192.168.1.2:8123";
      };
      description = ''
        Local DNS names, mapped to ip:port. The router's dnsmasq resolves
        the name to the IP; the port is for the reverse proxy on that host.
      '';
    };

    wanBlockedMacs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "MAC addresses to block from WAN access (firewall rules).";
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        wifiPassword = "pass://SHARE_ID/ITEM_ID/password";
      };
      description = ''
        Proton Pass secret references, resolved at runtime via pass-cli.
        Safe to commit: the IDs are opaque and useless without an
        authenticated session.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [wrapped];
  };
}
