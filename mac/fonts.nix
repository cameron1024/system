{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      fira
      fira-code
      noto-fonts
      noto-fonts-extra
      noto-fonts-cjk-sans
      noto-fonts-emoji
      font-awesome
      open-sans
      monaspace
    ];
  };
}
