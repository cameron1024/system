{
  description = "my dots";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, home-manager }: 

  let
    tunables = import ./tunables.nix;
    device = import ./device.nix { pkgs = nixpkgs; };
    colors = import ./color.nix { colorscheme = tunables.colorscheme; };
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (import ./configuration.nix ./hardware/thinkpad.nix)
	home-manager.nixosModules.home-manager
	({...}: {
          home-manager.users.cameron = {
	    
  programs = {
#    neovim = import ./nvim/init.nix { pkgs = nixpkgs; inherit colors; };
    alacritty = import ./alacritty.nix { colors = colors; device = device; };
    tmux = import ./tmux/tmux.nix { pkgs = nixpkgs; colors = colors; };
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


            home = {
	      username = "cameron";
	      homeDirectory = "/home/cameron";
	      stateVersion = "22.05";
	      sessionVariables = { EDITOR = "nvim"; };
	      packages = with nixpkgs; [
	        
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
    wezterm
    tmate

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

    # LSPs
    rust-analyzer
    haskell-language-server
    rnix-lsp
	      ];
	    };
	  };
	})
      ];
    };

  };

}
