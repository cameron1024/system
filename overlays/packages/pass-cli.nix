{
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "proton-pass-cli";
  version = "1.3.2";
  src = fetchurl {
    url = "https://proton.me/download/pass-cli/${version}/pass-cli-linux-x86_64";
    hash = "sha256-X7FK1t0+SuBGgSsBuhYUCkcR8LtCQMjbplo5B1LSuh0=";
  };
  phases = ["installPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin
    chmod +x $out/bin/pass-cli
  '';
}
