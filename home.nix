{ config, nixpkgs, ... }:

let
  tunables = import ./tunables.nix;
  device = import ./device.nix { inherit nixpkgs; };
  colors = import ./color.nix { colorscheme = tunables.colorscheme; };
in

{
  home.username = "cameron";
  home.homeDirectory = "/home/cameron";

  home.stateVersion = "22.05";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = with nixpkgs; [
    # general utilities
    ripgrep
    exa
    fd
    curl
    fzf
    powertop
    xclip
    tokei
    jq
    bottom
    bat
    tree
    rust-script
    unzip
    bacon
    navi
    zellij
    vlc
    unstable.wezterm
    tmate

    unstable.helix

    rustup
    gcc
    llvmPackages.bintools-unwrapped
    cmake
    glibc
    cargo-cache
    cargo-nextest
    unstable.cargo-udeps

    python
    unstable.flutter
    unstable.dart
    ghc
    stack


    # writing
    zola

    # system monitoring
    acpi
    sysstat

    # other shit
    unstable.google-chrome
    slack

    # LSPs
    unstable.rust-analyzer
    unstable.haskell-language-server
    unstable.rnix-lsp
  ];

  programs = {
    neovim = import ./nvim/init.nix { pkgs =  nixpkgs; inherit colors; };
    alacritty = import ./alacritty.nix { colors = colors; device = device; };
    tmux = import ./tmux/tmux.nix { pkgs = pkgs; colors = colors; };
    fish = import ./fish.nix;
    starship = import ./starship.nix;
    git = import ./git.nix;
    zoxide.enable = true;
    gh.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  home.file.".wezterm.lua".text = import ./wezterm/wezterm.nix { inherit colors; };
  home.file.".tmate.conf".text = ''
    source-file ~/.config/tmux/tmux.conf
  '';
}
