{pkgs, ...}: {
  fonts = {
    fontDir.enable = true;

    fonts = with pkgs; [
      noto-fonts
      noto-fonts-extra
      noto-fonts-cjk
      noto-fonts-emoji
      font-awesome
      open-sans
      nerdfonts
    ];
  };
}
