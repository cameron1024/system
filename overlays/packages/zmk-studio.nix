{
  fetchurl,
  appimage-run,
  writeShellScriptBin,
  ... 
}:
let 
  appimage = fetchurl {
    url = "https://github.com/zmkfirmware/zmk-studio/releases/download/v0.3.1/ZMK.Studio_0.3.1_amd64.AppImage";  
    hash = "sha256-kDt3AxPV1901WH3n6+mmylLwnvRrAuHSlFlRK9qEoOs=";

  };
in
writeShellScriptBin "zmk-studio" ''
  ${appimage-run}/bin/appimage-run ${appimage} 
''
