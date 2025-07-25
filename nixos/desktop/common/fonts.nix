{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (pkgs.stdenv.isLinux && config.services'.desktop.enable) {
    fonts.enableDefaultPackages = true;
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      fira
      monaspace
      noto-fonts
      noto-fonts-monochrome-emoji
    ];
  };
}
