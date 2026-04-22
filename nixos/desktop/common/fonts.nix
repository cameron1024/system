{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf config.services'.desktop.enable {
    fonts.enableDefaultPackages = true;
    fonts.packages = with pkgs; [
      fira-code
      inter
      josefin
      material-design-icons
      material-icons
      material-rounded
      monaspace
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      noto-fonts
      noto-fonts-monochrome-emoji
    ];
  };
}
