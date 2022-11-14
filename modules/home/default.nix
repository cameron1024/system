{ pkgs, config, ... }:
let
  tunables = import ./tunables.nix;
  colors = import ./color.nix { colorscheme = tunables.colorscheme; };
in

{


  home-manager.users.cameron = {

    imports = [
      ./rust
    ];
    nixpkgs.config.allowUnfree = true;
    dconf.settings = import ./dconf.nix;

    home.username = "cameron";
    home.homeDirectory = "/home/cameron";
    home.stateVersion = "22.05";


    programs = {
      neovim = import ./nvim/init.nix { inherit pkgs; colors = colors; font = tunables.font; };
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
      rofi = {
        enable = true;
      };
      kitty = import ./kitty.nix { font = tunables.font; inherit pkgs; };
    };

    home.packages = with pkgs; [
      ripgrep
      exa
      fd
      curl
      fzf
      xclip
      tokei
      jq
      bat
      tree
      unzip
      navi
      zellij
      vlc

      kodiPackages.netflix

      helix
      silicon

      powertop


      python
      ninja

      # system monitoring
      acpi
      sysstat
      bottom

      # other shit
      google-chrome
      slack
      whatsapp-for-linux

      # LSPs
      rnix-lsp

      plover.dev
    ];

  };

}


