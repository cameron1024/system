let
  fetchDrive = {
    id,
    hash,
  }: pkgs:
    pkgs.fetchurl {
      inherit hash;
      url = "https://drive.usercontent.google.com/download?id=${id}";
    };
in {
  everforest = fetchDrive {
    id = "1ZW7zL_YzqI6qqaaxdE6jBWFmobw-QhoT";
    hash = "sha256-qmGcKVLd5ntWVfQWzwMXC3PPYjC+pUYe4Qp1PDxHNfE=";
  };

  leaves = fetchDrive {
    id = "1DV-I9Ex5B8ZXYxGnm5ZAc_2NDQejdvtB";
    hash = "sha256-oo2ZOfo3a5lSATOamg4yS/pdMoEQUySy5M6PbF0VV7M=";
  };

  mistForest = fetchDrive {
    id = "1Y3nS0s33nbCSsKhAdMWfgwa4oOA3bMPY";
    hash = "sha256-tGudS0BU83wbBEDCBrXWk7arkce8Bf0u+fUE3cTBYZ0=";
  };

  forestBridge = fetchDrive {
    id = "1bl8PtQwYkg6HxlIr0Oxd-iz-FkwgFPmH";
    hash = "sha256-GfvwQYDOqnDgztgf0p80CS3Sc93xphdyuXajrG8gnB0=";
  };

  forestFromSky = fetchDrive {
    id = "1w1c20wUZv9b5O7yqGvAtIdFOxgIBQxTV";
    hash = "sha256-v4Jr7cTzqpa63pnbOzG9yx5iWGUJEMooJ2B6upBcaRA=";
  };
}
