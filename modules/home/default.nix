{ pkgs, lib, config, ... }:
let
  tunables = import ./tunables.nix;
  colors = import ./color.nix { colorscheme = tunables.colorscheme; };
in

{
  home-manager.users.cameron = {

    imports = [
      ./rust.nix
      ./git.nix
      ./vscode
      ./wezterm
      ../tools/neovim-again
      ./erdtree.nix
    ];

    gtk = {
      enable = true;
      theme = {
        package = pkgs.gnome.gnome-themes-extra;
        name = "Adwaita-dark";
      };
    };

    nixpkgs.config.allowUnfree = true;

    home.username = "cameron";
    home.homeDirectory = "/home/cameron";
    home.stateVersion = "22.05";

    # override cursor theme
    home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";


    programs = {
      /* neovim = import ./nvim/init.nix { inherit pkgs; colors = colors; font = tunables.font; }; */
      tmux = import ./tmux/tmux.nix { inherit pkgs; inherit colors; };
      myNvim.enable = true;
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

      comma

      lynx

      kodiPackages.netflix

      helix
      silicon

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

      dwarf-fortress
      asciiquarium
      cmatrix

      solaar
      pandoc

      mprocs
      blender

      kubo
      inlyne # cool markdown viewer
      wabt

      python3

      nixfmt

      discord

    ];

  };

}


