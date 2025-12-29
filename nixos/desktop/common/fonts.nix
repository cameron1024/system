{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (pkgs.stdenv.isLinux && config.services'.desktop.enable) {
    fonts.enableDefaultPackages = true;
    fonts.packages = with pkgs; [
      josefin
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      fira-code
      monaspace
      noto-fonts
      noto-fonts-monochrome-emoji
      inter
      fira-code
      material-rounded
      material-icons
      material-design-icons
    ];
  };
}
