{ pkgs, username, lib, ... }:

let
  # recentNushell = pkgs.nushell.overrideAttrs (old: rec {
  #   version = "0.88.1";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "nushell";
  #     repo = "nushell";
  #     rev = version;
  #     hash = "sha256-UuKXonAEMX57pZwP37N1FuUtkRE+3xB6Oj30yxSpJk4=";
  #   };
  #
  #   cargoDeps = old.cargoDeps.overrideAttrs (lib.const {
  #     inherit src;
  #     outputHash = "sha256-7XF3SVrJN6eGXD1uYGhlOZngFtn2ir+GYR1bsK5Qc/E=";
  #   });
  # });
  #
  # recentZoxide = pkgs.zoxide.overrideAttrs (old: rec {
  #   version = "0.9.2";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "ajeetdzouza";
  #     repo = "zoxide";
  #     rev = "3022cf3686b85288e6fbecb2bd23ad113fd83f3b";
  #     hash = "sha256-UuKXonAEMX57pZwP37N1FuUtkRE+3xB6Oj30yxSpJk4=";
  #   };
  #
  #   postPatch = null;
  #   nativeBuildInputs = old.nativeBuildInputs ++ (with pkgs; [ pkg-config openssl ]);
  #
  #   cargoDeps = old.cargoDeps.overrideAttrs (lib.const {
  #     inherit src;
  #     outputHash = "sha256-ad7JDxLFodW7KvHKoK51gdcEvORZOs+2XGC0LNcCu0I=";
  #   });
  # });
in

{
  imports = [ 
    ./bat
    ./fish
    ./tools
  ];

  config.home-manager.users.${username} = {
    programs.nushell = {
      enable = true;
      shellAliases = {
        e = "nvim";
        ed = "neovide --multigrid";
        p = "cd ~/projects/playground";
        dev = "nix develop --command fish";
        dr = "direnv reload";
        rs = "rust-script";
        t = "cd /tmp";
        g = "z";
        q = "exit";
        cat = "bat";
      };
      configFile.source = ./config.nu;
      envFile.source = ./env.nu;
    };

    programs.zoxide.enableNushellIntegration = true;
    programs.direnv.enableNushellIntegration = true;
    programs.carapace.enableNushellIntegration = true;
    programs.starship.enableNushellIntegration = true;
  };

}
