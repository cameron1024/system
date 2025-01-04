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
      config.allowUnfree = true;

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

    homebrew = {
      enable = true;
      brews = ["fvm"];
      taps = ["leoafarias/fvm"];
    };

    environment.variables = {
      ANDROID_HOME = "/Users/cameron/Library/Android/sdk";
    };

    home-manager.users.cameron = {
      programs.fish.interactiveShellInit = ''
        set PATH $PATH ~/fvm/default/bin
      '';
      programs.nushell = {
        shellAliases = {
          brew = "/opt/homebrew/bin/brew";
        };
      };
    };
  };
}
