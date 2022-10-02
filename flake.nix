{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      device = import ./device.nix { inherit pkgs; };
      tunables = import ./tunables.nix;
      colors = import ./color.nix { colorscheme = tunables.colorscheme; };
    in

    {
      nixpkgs.config.allowUnfree = true;
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (import ./configuration.nix ./hardware/thinkpad.nix)
          home-manager.nixosModules.home-manager
          (
            { ... }: {
              home-manager.users.cameron = {
                home.username = "cameron";
                home.homeDirectory = "/home/cameron";
                home.stateVersion = "22.05";

                nixpkgs.config.allowUnfree = true;
                programs = {
                  neovim = import ./nvim/init.nix { inherit pkgs; colors = colors; };
                  alacritty = import ./alacritty.nix { colors = colors; device = device; };
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

          )
        ];
      };

    };

}
