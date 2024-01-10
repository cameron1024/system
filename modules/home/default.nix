{ pkgs, lib, isDarwin, username, inputs, ... }:

let
  linuxPackages = with pkgs; [
    google-chrome
  ];

  darwinPackages = [];

  extraModules = if isDarwin then [inputs.mac-app-util.homeManagerModules.default] else [];
in

{
  home-manager.users.${username} = {

    imports = extraModules ++ [
      ./shell
      ./git
      ./tmux
      ./wezterm
      ./kitty
      ./social
    ] ;

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
      du-dust

      lynx

      silicon

    ] ++ (if isDarwin then darwinPackages else linuxPackages);

  };

}


