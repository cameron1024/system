{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      fira
      noto-fonts
      noto-fonts-extra
      noto-fonts-cjk
      noto-fonts-emoji
      font-awesome
      open-sans
      nerdfonts
      monaspace
    ];
  };
}
