{
  stdenvNoCC,
  fetchurl,
  ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "material-rounded";
  version = "0.0.1";

  src = fetchurl {
    url = "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf";
    hash = "sha256-1xnyL97ifjRLB+Rub6i1Cx/OPPywPUqE8D+vvwgS/CI=";
  };

  phases = ["installPhase"]; # no unpack phase needed

  installPhase = ''
    install -Dm644 ${src} -t $out/share/fonts/truetype
  '';
}
