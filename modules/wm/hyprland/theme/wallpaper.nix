{
  pkgs,
  lib,
  config,
  username,
  displays,
  ...
}: let
  wallpapers = map (pkgs.fetchurl) config.wallpapers;
  wallpaperDir = pkgs.stdenv.mkDerivation {
    name = "all-wallpapers";
    version = "0.0.0";
    dontUnpack = true;
    buildPhase = ''
      mkdir $out
      ${lib.concatStrings (map (wp: "cp ${wp} $out\n") wallpapers)}
    '';
  };

  defaultConfig = {
    path = wallpaperDir;
    duration = "3m";
  };

  mapDisplay = display: {
    name = display.name;
    value = defaultConfig;
  };
  settings = builtins.listToAttrs (map mapDisplay displays);
in {
  home-manager.users.${username} = {
    home.packages = with pkgs; [swww];

    programs.wpaperd = {
      enable = true;
      inherit settings;
    };
  };
}
