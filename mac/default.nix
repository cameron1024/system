{pkgs, ...}: {
  imports = [
    ./fonts.nix
    ./yabai.nix
  ];

  config = {
    system.stateVersion = 5;

    nix = {
      enable = false;
      # configureBuildUsers = true;
      package = pkgs.nixVersions.stable;
      settings.trusted-users = [ "root" "cameron" "@admin" ];

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

    # system.defaults.dock.expose-animation-duration = 10.0;

    security.pam.services.sudo_local.touchIdAuth = true;
    security.pam.services.sudo_local.reattach = true;

    # nixpkgs.hostPlatform = "aarch64-darwin";

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
