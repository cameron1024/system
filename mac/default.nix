{pkgs, ...}: {
  imports = [
    ./fonts.nix
    ./yabai.nix
  ];

  config = {
    system.stateVersion = 5;

    nix = {
      # configureBuildUsers = true;
      package = pkgs.nixVersions.stable;

      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };

    nixpkgs = {
      system = "aarch64-darwin";
      config = {allowUnfree = true;};
      overlays = [(import ../overlays/utils.nix)];
    };

    environment.systemPackages = with pkgs; [
      karabiner-elements
      nodejs_20
    ];

    system.keyboard.enableKeyMapping = true;
    system.keyboard.remapCapsLockToControl = true;

    system.defaults.dock.expose-animation-duration = 10.0;

    # nixpkgs.hostPlatform = "aarch64-darwin";
    services.nix-daemon.enable = true;

    users.users.cameron = {
      description = "cameron";
      home = "/Users/cameron";
    };

    environment.variables = {
      ANDROID_HOME = "/Users/cameron/Library/Android/sdk";
    };

    home-manager.users.cameron = {
      programs.fish.interactiveShellInit =
        /*
        fish
        */
        ''

          set -gx PATH $PATH "$HOME/.puro/bin"
          set -gx PATH $PATH "$HOME/.puro/shared/pub_cache/bin"
          set -gx PATH $PATH "$HOME/.puro/envs/default/flutter/bin"

          set -gx PURO_ROOT "/Users/cameron/.puro"
          set -gx PUB_CACHE "/Users/cameron/.puro/shared/pub_cache"

          set -gx JAVA_HOME /opt/homebrew/Cellar/openjdk@17/17.0.14
        '';
      programs.nushell = {
        shellAliases = {
          brew = "/opt/homebrew/bin/brew";
        };
      };
    };
  };
}
