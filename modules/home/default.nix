{ pkgs, config, ... }:
let
  tunables = import ./tunables.nix;
  colors = import ./color.nix { colorscheme = tunables.colorscheme; };
in

{
  home-manager.users.cameron = {

    imports = [
      ./rust.nix
      ./git.nix
    ];

    nixpkgs.config.allowUnfree = true;
    dconf.settings = import ./dconf.nix;

    home.username = "cameron";
    home.homeDirectory = "/home/cameron";
    home.stateVersion = "22.05";



    programs = {
      neovim = import ./nvim/init.nix { inherit pkgs; colors = colors; font = tunables.font; };
      tmux = import ./tmux/tmux.nix { inherit pkgs; inherit colors; };
      fish = import ./fish.nix;
      starship.enable = true;
      zoxide.enable = true;
      gh.enable = true;
      direnv.enable = true;
      direnv.nix-direnv.enable = true;
      kitty = import ./kitty.nix { font = tunables.font; inherit pkgs; };
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
      navi
      zellij
      vlc
      du-dust
      neovide

      lynx

      kodiPackages.netflix

      helix
      silicon
      flutter
      dart

      python

      # system monitoring
      acpi
      sysstat

      # comms
      google-chrome
      slack
      whatsapp-for-linux
      discord

      # LSPs
      haskell-language-server
      rnix-lsp

      plover.dev
      ttyper
    ];

  };

}


