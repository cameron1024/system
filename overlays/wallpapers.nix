final: prev: let
  fetchDrive = {
    id,
    hash,
  }:
    final.fetchurl {
      inherit hash;
      url = "https://drive.usercontent.google.com/download?id=${id}";
    };

  makeWallpaperDir = {wallpapers ? []}:
    final.stdenvNoCC.mkDerivation {
      name = "all-wallpapers";
      version = "0.0.0";
      phases = ["installPhase"];
      installPhase = let
        mapToCp = name: wallpaper: "cp ${toString wallpaper} $out/${name}.png";
        script = builtins.concatStringsSep "\n" (final.lib.mapAttrsToList mapToCp wallpapers);
      in ''
        mkdir -p $out
        ${script}
      '';
    };

  wallpapers = {
    forestStairs = final.fetchDrive {
      id = "1ZW7zL_YzqI6qqaaxdE6jBWFmobw-QhoT";
      hash = "sha256-qmGcKVLd5ntWVfQWzwMXC3PPYjC+pUYe4Qp1PDxHNfE=";
    };

    leaves = final.fetchDrive {
      id = "1DV-I9Ex5B8ZXYxGnm5ZAc_2NDQejdvtB";
      hash = "sha256-oo2ZOfo3a5lSATOamg4yS/pdMoEQUySy5M6PbF0VV7M=";
    };

    mistForest = final.fetchDrive {
      id = "1Y3nS0s33nbCSsKhAdMWfgwa4oOA3bMPY";
      hash = "sha256-tGudS0BU83wbBEDCBrXWk7arkce8Bf0u+fUE3cTBYZ0=";
    };

    forestBridge = final.fetchDrive {
      id = "1bl8PtQwYkg6HxlIr0Oxd-iz-FkwgFPmH";
      hash = "sha256-GfvwQYDOqnDgztgf0p80CS3Sc93xphdyuXajrG8gnB0=";
    };

    forestFromSky = final.fetchDrive {
      id = "1w1c20wUZv9b5O7yqGvAtIdFOxgIBQxTV";
      hash = "sha256-v4Jr7cTzqpa63pnbOzG9yx5iWGUJEMooJ2B6upBcaRA=";
    };

    darkForest = final.fetchDrive {
      id = "11KYtodciqeveLwql0FOtcsJquh6RWjf5";
      hash = "sha256-6ZLsZjDNrlg8asdXh9jxyYfkltPu+EOKuFXEOM2To/Q=";
    };
  };

  all = makeWallpaperDir {inherit wallpapers;};
in {
  inherit fetchDrive;
  wallpapers = wallpapers // {inherit all;};
}
