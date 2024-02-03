{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;

    fontDir.enable = true;
    
    packages = with pkgs; [
 # icon fonts
      material-symbols
      # normal fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      roboto

      maple-mono
      maple-mono-NF
      maple-mono-SC-NF

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
