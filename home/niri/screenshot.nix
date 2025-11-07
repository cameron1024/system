{
  lib,
  nixosConfig,
  pkgs,
  ...
}: let
  ocrScreenshot = pkgs.writeShellScriptBin "ocr-screenshot.sh" ''
    rm /tmp/ocr-output.txt || true

    # write screenshot to /tmp/ocr-screenshot.png
    ${pkgs.hyprshot}/bin/hyprshot \
      --output /tmp \
      --filename ocr-screenshot.png \
      --mode region \
      --silent

    # write text to /tmp/ocr-output.txt
    ${pkgs.tesseract}/bin/tesseract /tmp/ocr-screenshot.png /tmp/ocr-output

    TEXT=$(cat /tmp/ocr-output.txt)
    
    if [ -z "$TEXT" ]; then
      echo "no text, exitting"
      exit 1
    fi

    echo $TEXT | wl-copy && notify-send "Copied text to clipboard: $TEXT"
  '';
in
  with lib; {
    config = mkIf (nixosConfig.programs'.niri.enable or false) {
      home.packages = [ocrScreenshot];
    };
  }
