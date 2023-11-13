{ pkgs, username, ... }:
let
  tunables = import ./tunables.nix;
in

{
  home-manager.users.${username} = {

    imports = [
      ./rust.nix
      ./git.nix
      ./vscode
      ./wezterm
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

    home.username = username;
    home.homeDirectory = "/home/${username}";
    home.stateVersion = "22.05";

    # override cursor theme
    home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";


    programs = {
      /* neovim = import ./nvim/init.nix { inherit pkgs; colors = colors; font = tunables.font; }; */
      # tmux = import ./tmux/tmux.nix { inherit pkgs; };
      # fish = import ./fish.nix;
      # zoxide.enable = true;
      gh.enable = true;
      direnv.enable = true;
      direnv.nix-direnv.enable = true;
      kitty = import ./kitty.nix { font = tunables.font; inherit pkgs; };
    };

    home.packages = with pkgs; [
      ripgrep
      eza
      fd
      curl
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

      pandoc

      mprocs
      blender

      kubo
      inlyne # cool markdown viewer
      wabt

      python3

      nixfmt

      discord
      libreoffice

    ];

  };

}


