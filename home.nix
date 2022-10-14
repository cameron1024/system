{ pkgs, config, ... }:
let
  device = import ./device.nix { inherit pkgs; };
  tunables = import ./tunables.nix;
  colors = import ./color.nix { colorscheme = tunables.colorscheme; };
in

{
  home-manager.users.cameron = {

    nixpkgs.config.allowUnfree = true;
    dconf.settings = import ./dconf.nix;

    home.username = "cameron";
    home.homeDirectory = "/home/cameron";
    home.stateVersion = "22.05";


    programs = {
      neovim = import ./nvim/init.nix { inherit pkgs; colors = colors; font = tunables.font; };
      alacritty = import ./alacritty.nix { colors = colors; device = device; font = tunables.font; };
      tmux = import ./tmux/tmux.nix { inherit pkgs; colors = colors; };
      fish = import ./fish.nix;
      starship = import ./starship.nix;
      git = import ./git.nix;
      zoxide.enable = true;
      gh.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      wezterm = {
        enable = true;
        extraConfig = builtins.readFile ./wezterm.lua;
      };
      rofi = {
        enable = true;
      };
    };

    home.packages = with pkgs; [
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
      tmate

      kodiPackages.netflix

      helix
      silicon

      rustup
      gcc
      llvmPackages.bintools-unwrapped
      cmake
      glibc
      cargo-cache
      cargo-nextest
      cargo-udeps

      python
      flutter
      dart
      ghc
      stack

      # system monitoring
      acpi
      sysstat

      # other shit
      google-chrome
      slack
      whatsapp-for-linux

      # LSPs
      rust-analyzer
      haskell-language-server
      rnix-lsp

      plover.dev
    ];

  };

}

