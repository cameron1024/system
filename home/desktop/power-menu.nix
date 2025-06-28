{
  pkgs,
  lib,
  config,
  ...
}: let
  departure = {
    rustPlatform,
    fetchFromGitHub,
    pkg-config,
    glib,
    pango,
    gdk-pixbuf,
    gtk4,
    gtk4-layer-shell,
    ...
  }:
    rustPlatform.buildRustPackage rec {
      pname = "departure";
      version = "0.0.0";

      src = fetchFromGitHub {
        owner = "mpalatsi";
        repo = pname;
        rev = "656118acd3a6a86012fda527b4eed559739c0dd7";
        hash = "sha256-6TX5wYaJ0q7Q5O+KFRde+fnMqCq63L7zmOcDDYeWdnQ=";
      };

      cargoLock.lockFile = "${src}/Cargo.lock";

      nativeBuildInputs = [pkg-config];
      buildInputs = [glib pango gdk-pixbuf gtk4 gtk4-layer-shell];
    };
in
  with lib; {
    options = {
      programs'.departure.enable = mkEnableOption "Departure logout app";
    };
    config = mkIf config.programs'.departure.enable {
      home.packages = [(pkgs.callPackage departure {})];
    };
  }
