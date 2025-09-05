{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "josefin-sans";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "googlefonts";
    repo = "josefinsans";
    rev = "132fdfd997a62411375d15e20ef81285923750c6"; 
    hash = "sha256-pngYz7la2WMxEeethah3NjI3i1BSnicMvadH+UhxtNk=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    mkdir -p $out/share/fonts/variable

    find . -name "*.ttf" -path "*/fonts/ttf/*" -exec cp {} $out/share/fonts/truetype/ \;
    find . -name "*.ttf" -path "*/fonts/variable/*" -exec cp {} $out/share/fonts/variable/ \;

    runHook postInstall
  '';
}
