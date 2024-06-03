{
  pkgs,
  lib,
  isDarwin,
  username,
  inputs,
  ...
}: let
  linuxPackages = with pkgs; [
    google-chrome
  ];

  darwinPackages = [];

  extraModules =
    if isDarwin
    then [inputs.mac-app-util.homeManagerModules.default]
    else [inputs.anyrun.homeManagerModules.default];
in {
  imports =
    extraModules
    ++ [
      ./shell
      ./git
      ./tmux
      ./wezterm
      ./kitty
      ./social
      ./tools
    ];

  nixpkgs.config.allowUnfree = true;

  home.username = lib.mkIf (!isDarwin) username;
  home.homeDirectory = lib.mkIf (!isDarwin) "/home/${username}";

  # override cursor theme
  home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";

  home.packages = with pkgs;
    [
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

      ollama
      vscode

    ]
    ++ (
      if isDarwin
      then darwinPackages
      else linuxPackages
    );
}
