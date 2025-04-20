{
  pkgs,
  lib,
  machine,
  ...
}: let
  ocrScreenshot = pkgs.writeShellScriptBin "ocr-screenshot.sh" ''
    # write screenshot to /tmp/ocr-screenshot.png
    ${pkgs.hyprshot}/bin/hyprshot \
      --output /tmp \
      --filename ocr-screenshot.png \
      --mode region \
      --silent

    # write text to /tmp/ocr-output.txt
    ${pkgs.tesseract}/bin/tesseract /tmp/ocr-screenshot.png /tmp/ocr-output

    TEXT=$(cat /tmp/ocr-output.txt)

    echo $TEXT | wl-copy && notify-send "Copied text to clipboard: $TEXT"
  '';
in {
  home.packages = lib.mkIf machine.linux (with pkgs; [
    hyprshot
    jq
    grim
    slurp
    wl-clipboard
    libnotify
    tesseract
    ocrScreenshot
  ]);

  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER SHIFT, s, exec, hyprshot -m region"
      "SUPER, t, exec, ${ocrScreenshot}/bin/ocr-screenshot.sh"
    ];
  };
}
