{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    
    packages = with pkgs; [
      noto-fonts
      noto-fonts-extra
      noto-fonts-cjk
      noto-fonts-emoji
      font-awesome
      open-sans
      nerdfonts
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        monospace = [
          "FiraCode Nerd Font"
        ];

        emoji = [ 
          "Noto Color Emoji"
          "Font Awesome 6 Free" 
          "Font Awesome 6 Brands" 
        ];

        sansSerif = [
          "Noto Sans"
        ];

        serif = [
          "Noto Serif"
        ];  
      };
    };
  };
}
