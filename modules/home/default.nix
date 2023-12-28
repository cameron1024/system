{ pkgs, lib, isDarwin, username, ... }:

{
  home-manager.users.${username} = {

    imports = [
      # ./vscode
      ./wezterm
      ./kitty
      ./erdtree.nix
      ./social
    ];

    gtk = {
      enable = true;
      theme = {
        package = pkgs.gnome.gnome-themes-extra;
        name = "Adwaita-dark";
      };
    };

    nixpkgs.config.allowUnfree = true;

    home.username = lib.mkIf (!isDarwin) username;
    home.homeDirectory = lib.mkIf (!isDarwin) "/home/${username}";
    home.stateVersion = "22.05";

    # override cursor theme
    home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";

    home.packages = with pkgs; [
      ripgrep
      eza
      fd
      curl
      xclip
      tokei
      jq
      bottom
      tree
      rust-script
      unzip
      navi
      zellij
      du-dust
      neovide

      lynx

      silicon

    ] ++ (if isDarwin then [] else [
      google-chrome
    ]);

  };

}


